#!/usr/bin/bash

################################################
##### Time
################################################

# References:
# https://wiki.archlinux.org/title/System_time#Time_zone
# https://wiki.archlinux.org/title/Systemd-timesyncd

# Enable systemd-timesyncd
systemctl enable systemd-timesyncd.service

# Set timezone
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc --utc

################################################
##### Locale and keymap
################################################

# Set locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "LANG=\"en_US.UTF-8\"" > /etc/locale.conf
locale-gen

# Set keymap
echo "KEYMAP=us" > /etc/vconsole.conf

################################################
##### Hostname
################################################

# Set hostname
echo ${NEW_HOSTNAME} > /etc/hostname

# Set /etc/hosts
tee /etc/hosts << EOF
127.0.0.1 localhost
::1 localhost
127.0.1.1 ${NEW_HOSTNAME}.localdomain ${NEW_HOSTNAME}
EOF

################################################
##### Pacman
################################################

# References:
# https://wiki.archlinux.org/title/Pacman/Package_signing#Initializing_the_keyring
# https://wiki.archlinux.org/title/Makepkg

# Force pacman to refresh the package lists
pacman -Syyu --noconfirm

# Initialize Pacman's keyring
pacman-key --init
pacman-key --populate

# Configure Pacman
sed -i "s|^#Color|Color|g" /etc/pacman.conf
sed -i "s|^#VerbosePkgLists|VerbosePkgLists|g" /etc/pacman.conf
sed -i "s|^#ParallelDownloads.*|ParallelDownloads = 5|g" /etc/pacman.conf
sed -i "/ParallelDownloads = 5/a ILoveCandy" /etc/pacman.conf

# Upgrade system
pacman -Syy

# Disable debug packages (makepkg)
mkdir -p /etc/makepkg.conf.d
tee /etc/makepkg.conf.d/debugpackages.conf << EOF
OPTIONS=(!debug)
EOF

################################################
##### initramfs configuration
################################################

# References:
# https://wiki.archlinux.org/title/RAID#Configure_mkinitcpio
# https://github.com/archlinux/mkinitcpio/blob/master/mkinitcpio.conf

# Configure mkinitcpio
tee /etc/mkinitcpio.conf << EOF
MODULES=(ext4 vfat $(if [ ${RAID0} = "yes" ]; then echo "raid0 md_mod"; fi) dm_mod dm_crypt ${GPU_MKINITCPIO_MODULES})
BINARIES=()
FILES=()
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block $(if [ ${RAID0} = "yes" ]; then echo "mdadm_udev"; fi) sd-encrypt filesystems fsck)
COMPRESSION="zstd"
COMPRESSION_OPTIONS=(-2)
EOF

# Remove extra spaces from MODULES and HOOKS lines
sed -i '/^MODULES=\|^HOOKS=/ s/  */ /g' /etc/mkinitcpio.conf

################################################
##### Kernel parameters
################################################

# References:
# https://wiki.archlinux.org/title/Unified_kernel_image#Kernel_command_line
# https://wiki.archlinux.org/title/Trusted_Platform_Module#systemd-cryptenroll
# https://github.com/joelmathewthomas/archinstall-luks2-lvm2-secureboot-tpm2?tab=readme-ov-file#8-set-kernel-command-line
# https://wiki.archlinux.org/title/RAID#RAID0_layout
# https://wiki.archlinux.org/title/CPU_frequency_scaling#amd_pstate
# https://wiki.archlinux.org/title/Wake-on-LAN#Fix_by_Kernel_quirks

# Create cmdline.d directory for kernel parameters
mkdir /etc/cmdline.d

# LUKS options
tee /etc/cmdline.d/luks.conf << EOF
rd.luks.name=$(if [ ${RAID0} = "no" ]; then blkid -s UUID -o value /dev/nvme0n1p2; elif [ ${RAID0} = "yes" ]; then blkid -s UUID -o value /dev/md/ArchArray;fi)=system
EOF

# root options
tee /etc/cmdline.d/root.conf << EOF
root=/dev/mapper/system rootfstype=ext4 rw
EOF

# RAID options
if [ ${RAID0} = "yes" ]; then
tee /etc/cmdline.d/raid.conf << EOF
raid0.default_layout=2
EOF
fi

# TPM2 LUKS unlock options
tee /etc/cmdline.d/tpm.conf << EOF
rd.luks.options=$(if [ ${RAID0} = "no" ]; then blkid -s UUID -o value /dev/nvme0n1p2; elif [ ${RAID0} = "yes" ]; then blkid -s UUID -o value /dev/md/ArchArray;fi)=tpm2-device=auto
EOF

# AMD scaling driver options
if [ -n "$AMD_SCALING_DRIVER" ]; then
tee /etc/cmdline.d/amdscalingdriver.conf << EOF
${AMD_SCALING_DRIVER}
EOF
fi

# Disable emergency shell
tee /etc/cmdline.d/emergencyshell.conf << EOF
rd.shell=0 rd.emergency=reboot
EOF

# Permanently disable zswap
tee /etc/cmdline.d/zswap.conf << EOF
zswap.enabled=0
EOF

# Make boot quite and disable watchdog
tee /etc/cmdline.d/quiet.conf << EOF
nowatchdog quiet loglevel=3 systemd.show_status=auto rd.udev.log_level=3 vt.global_cursor_default=0 splash
EOF

# Security options
tee /etc/cmdline.d/security.conf << EOF
lsm=landlock,lockdown,yama,integrity,apparmor,bpf
EOF

# Full AMD GPU controls (desktop only)
if [[ $(cat /sys/class/dmi/id/chassis_type) -ne 10 ]] && lspci | grep "VGA" | grep "AMD" > /dev/null; then
tee /etc/cmdline.d/amdgpucontrol.conf << EOF
amdgpu.ppfeaturemask=0xffffffff
EOF
fi

# Intel GPU options
if lspci | grep "VGA" | grep "Intel" > /dev/null; then
tee /etc/cmdline.d/intelgpu.conf << EOF
enable_guc=2 enable_fbc=1
EOF
fi

# Enable quirks to prevent wake-up after shutdown with WoL enabled
tee /etc/cmdline.d/wol.conf << EOF
xhci_hcd.quirks=270336
EOF

################################################
##### Configure systemd-ukify with measured boot support
################################################

# References:
# /usr/lib/kernel/uki.conf
# https://www.freedesktop.org/software/systemd/man/latest/ukify.html
# https://man7.org/linux/man-pages/man8/kernel-install.8.html
# https://github.com/joelmathewthomas/archinstall-luks2-lvm2-secureboot-tpm2?tab=readme-ov-file#10-configure-systemd-ukify

# Install systemd-ukify and dependencies
pacman -S --noconfirm systemd-ukify sbsigntools efitools

# Create UKI configuration
tee /etc/kernel/uki.conf << EOF
[UKI]
OSRelease=@/etc/os-release
PCRBanks=sha256

[PCRSignature:initrd]
Phases=enter-initrd
PCRPrivateKey=/etc/kernel/pcr-initrd.key.pem
PCRPublicKey=/etc/kernel/pcr-initrd.pub.pem
EOF

# Generate the key for the PCR policy
ukify genkey --config=/etc/kernel/uki.conf

################################################
##### Use mkinitcpio to generate the UKI
################################################

# References:
# https://wiki.archlinux.org/title/Unified_kernel_image#.preset_file
# https://github.com/joelmathewthomas/archinstall-luks2-lvm2-secureboot-tpm2?tab=readme-ov-file#11-use-mkinitcpio-to-generate-the-uki

# Create directory for UKIs
mkdir -p /boot/EFI/Linux

# Create preset file for standard Kernel
tee /etc/mkinitcpio.d/linux.preset << EOF
ALL_kver="/boot/vmlinuz-linux"
PRESETS=('default')
default_uki="/boot/EFI/Linux/arch-linux.efi"
default_options="--splash /usr/share/systemd/bootctl/splash-arch.bmp"
EOF

# Create preset file for LTS Kernel
tee /etc/mkinitcpio.d/linux-lts.preset << EOF
ALL_kver="/boot/vmlinuz-linux-lts"
PRESETS=('default')
default_uki="/boot/EFI/Linux/arch-linux-lts.efi"
default_options="--splash /usr/share/systemd/bootctl/splash-arch.bmp"
EOF

# Regenerate initramfs
mkinitcpio -P

################################################
##### systemd-boot
################################################

# References:
# https://wiki.archlinux.org/title/systemd-boot
# https://wiki.archlinux.org/title/Systemd-boot#Unified_kernel_images

# Install systemd-boot to the ESP
bootctl install

# systemd-boot upgrade hook
mkdir -p /etc/pacman.d/hooks
tee /etc/pacman.d/hooks/95-systemd-boot.hook << 'EOF'
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Gracefully upgrading systemd-boot...
When = PostTransaction
Exec = /usr/bin/systemctl restart systemd-boot-update.service
EOF

# systemd-boot configuration
tee /boot/loader/loader.conf << 'EOF'
default  arch-linux.efi
timeout  0
console-mode max
editor   no
EOF

################################################
##### Secure boot
################################################

# References:
# https://github.com/Foxboron/sbctl
# https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot#Using_your_own_keys

# Install sbctl
pacman -S --noconfirm sbctl

# Create secure boot signing keys
sbctl create-keys

# Enroll keys to EFI
sbctl enroll-keys --tpm-eventlog

# Sign files with secure boot keys
sbctl sign --save /boot/EFI/BOOT/BOOTX64.EFI
sbctl sign --save /boot/EFI/Linux/arch-linux.efi
sbctl sign --save /boot/EFI/Linux/arch-linux-lts.efi
sbctl sign --save /boot/EFI/systemd/systemd-bootx64.efi
sbctl sign --save /boot/vmlinuz-linux
sbctl sign --save /boot/vmlinuz-linux-lts

################################################
##### Common applications
################################################

# Install common applications
pacman -S --noconfirm \
    coreutils \
    htop \
    git \
    7zip \
    unzip \
    unrar \
    lm_sensors \
    upower \
    nano \
    wget \
    openssh \
    fwupd \
    zstd \
    lzop \
    man-db \
    man-pages \
    e2fsprogs \
    util-linux \
    rsync \
    jq \
    yq \
    lazygit \
    ripgrep \
    fd \
    gptfdisk \
    bc \
    cpupower \
    procps-ng \
    gawk \
    fzf \
    findutils \
    net-tools \
    zenity

# Add AppImage support
pacman -S --noconfirm fuse3

# Updater helper
tee /usr/local/bin/update-all << EOF
#!/usr/bin/bash

################################################
##### System and firmware
################################################

# Update keyring
sudo pacman -Sy --noconfirm --needed archlinux-keyring

# Update all packages
paru -Syyu

# Update firmware
sudo fwupdmgr refresh
sudo fwupdmgr update

################################################
##### Flatpaks
################################################

# Update Flatpak apps
flatpak update -y
flatpak uninstall -y --unused
EOF

chmod +x /usr/local/bin/update-all

################################################
##### zram / swap
################################################

# References:
# https://wiki.archlinux.org/title/Zram#Using_zram-generator
# https://wiki.archlinux.org/title/swap#Swappiness
# https://wiki.archlinux.org/title/Improving_performance#zram_or_zswap
# https://wiki.gentoo.org/wiki/Zram
# https://www.reddit.com/r/Fedora/comments/mzun99/new_zram_tuning_benchmarks/
# https://github.com/systemd/zram-generator

# Install zram generator
pacman -S --noconfirm zram-generator

# Configure zram generator
tee /etc/systemd/zram-generator.conf << EOF
[zram0]
zram-size = ram / 4
compression-algorithm = zstd
EOF

# Daemon reload
systemctl daemon-reload

# Enable zram on boot
systemctl start /dev/zram0

# Set page cluster
echo 'vm.page-cluster=0' > /etc/sysctl.d/99-page-cluster.conf

# Set swappiness
echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf

# Set vfs cache pressure
echo 'vm.vfs_cache_pressure=50' > /etc/sysctl.d/99-vfs-cache-pressure.conf

################################################
##### Tweaks
################################################

# References:
# https://github.com/CryoByte33/steam-deck-utilities/blob/main/docs/tweak-explanation.md
# https://wiki.cachyos.org/configuration/general_system_tweaks/
# https://gitlab.com/cscs/maxperfwiz/-/blob/master/maxperfwiz?ref_type=heads

# Set reverse path filtering to strict mode
tee /etc/sysctl.d/99-reverse-path-filtering.conf << EOF
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.all.rp_filter=1
EOF

# Enable trim operations
systemctl enable fstrim.timer

# Sysctl tweaks
COMPUTER_MEMORY=$(echo $(vmstat -sS M | head -n1 | awk '{print $1;}'))
MEMORY_BY_CORE=$(echo $(( $(vmstat -s | head -n1 | awk '{print $1;}')/$(nproc) )))
BEST_KEEP_FREE=$(echo "scale=0; "$MEMORY_BY_CORE"*0.058" | bc | awk '{printf "%.0f\n", $1}')

tee /etc/sysctl.d/99-performance-tweaks.conf << EOF
kernel.nmi_watchdog=0
kernel.split_lock_mitigate=0
vm.compaction_proactiveness=0
vm.page_lock_unfairness=1
$(if [[ ${COMPUTER_MEMORY} > 13900 ]]; then echo "vm.dirty_bytes=419430400"; fi)
$(if [[ ${COMPUTER_MEMORY} > 13900 ]]; then echo "vm.dirty_background_bytes=209715200"; fi)
$(if [[ $(cat /sys/block/*/queue/rotational) == 0 ]]; then echo "vm.dirty_expire_centisecs=500"; else echo "vm.dirty_expire_centisecs=3000"; fi)
$(if [[ $(cat /sys/block/*/queue/rotational) == 0 ]]; then echo "vm.dirty_writeback_centisecs=250"; else echo "vm.dirty_writeback_centisecs=1500"; fi)
vm.min_free_kbytes=${BEST_KEEP_FREE}
EOF

# Udev tweaks
tee /etc/udev/rules.d/99-performance-tweaks.rules << 'EOF'
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
EOF

# Hugepage Defragmentation - default: 1
# Transparent Hugepages - default: always
# Shared Memory in Transparent Hugepages - default: never
tee /etc/systemd/system/kernel-tweaks.service << 'EOF'
[Unit]
Description=Set kernel tweaks
After=multi-user.target
StartLimitBurst=0

[Service]
Type=oneshot
Restart=on-failure
ExecStart=/usr/bin/bash -c 'echo always > /sys/kernel/mm/transparent_hugepage/enabled'
ExecStart=/usr/bin/bash -c 'echo advise > /sys/kernel/mm/transparent_hugepage/shmem_enabled'
ExecStart=/usr/bin/bash -c 'echo 0 > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag'

[Install]
WantedBy=multi-user.target
EOF

systemctl enable kernel-tweaks.service

# Disable watchdog timer drivers
# sudo dmesg | grep -e sp5100 -e iTCO -e wdt -e tco
tee /etc/modprobe.d/disable-watchdog-drivers.conf << 'EOF'
blacklist sp5100_tco
blacklist iTCO_wdt
blacklist iTCO_vendor_support
EOF

# Disable broadcast messages
tee /etc/systemd/system/disable-broadcast-messages.service << 'EOF'
[Unit]
Description=Disable broadcast messages
After=multi-user.target
StartLimitBurst=0

[Service]
Type=oneshot
Restart=on-failure
ExecStart=/usr/bin/busctl set-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager EnableWallMessages b false

[Install]
WantedBy=multi-user.target
EOF

systemctl enable disable-broadcast-messages.service

################################################
##### Users
################################################

# References:
# https://wiki.archlinux.org/title/XDG_Base_Directory

# Install ZSH and dependencies
pacman -S --noconfirm zsh

# Set root password and shell
echo "root:${NEW_USER_PASSWORD}" | chpasswd
chsh -s /usr/bin/zsh

# Setup user
useradd -m -G wheel -s /usr/bin/zsh ${NEW_USER}
echo "${NEW_USER}:${NEW_USER_PASSWORD}" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Create XDG user directories
pacman -S --noconfirm xdg-user-dirs
sudo -u ${NEW_USER} xdg-user-dirs-update

# Create common directories and configure them
mkdir -p \
  /home/${NEW_USER}/.local/share/applications \
  /home/${NEW_USER}/.local/share/themes \
  /home/${NEW_USER}/.local/share/fonts \
  /home/${NEW_USER}/.local/bin \
  /home/${NEW_USER}/.config/autostart \
  /home/${NEW_USER}/.config/environment.d \
  /home/${NEW_USER}/.config/autostart \
  /home/${NEW_USER}/.config/systemd/user \
  /home/${NEW_USER}/.icons \
  /home/${NEW_USER}/Projects \
  /home/${NEW_USER}/Applications

# Create SSH directory and config file
mkdir -p /home/${NEW_USER}/.ssh

chown 700 /home/${NEW_USER}/.ssh

tee /home/${NEW_USER}/.ssh/config << EOF
Host *
    ServerAliveInterval 60
EOF

# Create zsh configs directory
mkdir -p /home/${NEW_USER}/.zshrc.d

# Configure ZSH
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/zsh/.zshrc -o /home/${NEW_USER}/.zshrc

# Configure powerlevel10k zsh theme
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/zsh/.p10k.zsh -o /home/${NEW_USER}/.p10k.zsh

################################################
##### Networking
################################################

# References:
# https://wiki.archlinux.org/title/NetworkManager#Using_iwd_as_the_Wi-Fi_backend
# https://wiki.archlinux.org/title/Firewalld
# https://wiki.archlinux.org/title/nftables

# Install and configure firewalld
pacman -S --noconfirm firewalld
systemctl enable firewalld.service

# Set default zone to home
firewall-offline-cmd --set-default-zone=home

# Disable firewall-applet
sed -i '/^Exec/d' /etc/xdg/autostart/firewall-applet.desktop
chattr +i /etc/xdg/autostart/firewall-applet.desktop

# Install and enable NetworkManager
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager.service

# Install bind tools
pacman -S --noconfirm bind

# Install nftables
pacman -S --noconfirm iptables-nft --ask 4

################################################
##### Paru
################################################

# References:
# https://github.com/Morganamilo/paru

# (Temporary - reverted at cleanup) Allow $NEW_USER to run pacman without password
echo "${NEW_USER} ALL=NOPASSWD:/usr/bin/pacman" >> /etc/sudoers

# Install paru
sudo -u ${NEW_USER} git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin
sudo -u ${NEW_USER} makepkg -si --noconfirm --dir /tmp/paru-bin
rm -rf /tmp/paru-bin

################################################
##### AppArmor
################################################

# References:
# https://wiki.archlinux.org/title/AppArmor
# https://wiki.archlinux.org/title/Audit_framework
# https://github.com/roddhjav/apparmor.d
# https://apparmor.pujol.io/

# Install AppArmor
pacman -S --noconfirm apparmor

# Enable AppArmor service
systemctl enable apparmor.service

# Enable caching AppArmor profiles
sed -i "s|^#write-cache|write-cache|g" /etc/apparmor/parser.conf
sed -i "s|^#Optimize=compress-fast|Optimize=compress-fast|g" /etc/apparmor/parser.conf

# Install and enable Audit Framework
pacman -S --noconfirm audit
systemctl enable auditd.service

# Install AppArmor.d profiles
sudo -u ${NEW_USER} paru -S --noconfirm apparmor.d-git

# Configure AppArmor.d
mkdir -p /etc/apparmor.d/tunables/xdg-user-dirs.d/apparmor.d.d

tee /etc/apparmor.d/tunables/xdg-user-dirs.d/apparmor.d.d/local << 'EOF'
@{XDG_PROJECTS_DIR}+="Projects" ".devtools"
@{XDG_GAMES_DIR}+="Games"
EOF

################################################
##### ffmpeg
################################################

# References:
# https://wiki.archlinux.org/title/FFmpeg#Installation

# Install ffmpeg
pacman -S --noconfirm ffmpeg

################################################
##### GPU
################################################

# References:
# https://wiki.archlinux.org/title/intel_graphics
# https://wiki.archlinux.org/title/AMDGPU
# https://wiki.archlinux.org/title/Hardware_video_acceleration
# https://wiki.archlinux.org/title/Vulkan

# Install GPU drivers related packages
pacman -S --noconfirm mesa vulkan-icd-loader vulkan-mesa-layers ${GPU_PACKAGES}

# Override VA-API driver via environment variable
tee -a /etc/environment << EOF

# VA-API
${LIBVA_ENV_VAR}
EOF

# Set env vars for AMDGPU
if lspci | grep "VGA" | grep "AMD" > /dev/null; then
tee -a /etc/environment << EOF

# Vulkan
AMD_VULKAN_ICD=RADV

# VDPAU
VDPAU_DRIVER=radeonsi
EOF
elif lspci | grep "VGA" | grep "Intel" > /dev/null; then
tee -a /etc/environment << EOF

# VDPAU
VDPAU_DRIVER=va_gl
EOF
fi

# Install VA-API tools
pacman -S --noconfirm libva-utils

# Install VDPAU tools
pacman -S --noconfirm vdpauinfo

# Install Vulkan tools
pacman -S --noconfirm vulkan-tools

################################################
##### systemd
################################################

# References:
# https://www.freedesktop.org/software/systemd/man/systemd-system.conf.html

# Configure default timeout to stop system units
mkdir -p /etc/systemd/system.conf.d
tee /etc/systemd/system.conf.d/default-timeout.conf << EOF
[Manager]
DefaultTimeoutStopSec=5s
EOF

# Configure default timeout to stop user units
mkdir -p /etc/systemd/user.conf.d
tee /etc/systemd/user.conf.d/default-timeout.conf << EOF
[Manager]
DefaultTimeoutStopSec=5s
EOF

################################################
##### GStreamer
################################################

# References:
# https://wiki.archlinux.org/title/GStreamer

# Install GStreamer
pacman -S --noconfirm \
    gstreamer \
    gst-libav \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly \
    gst-plugin-pipewire \
    gstreamer-vaapi

################################################
##### PipeWire
################################################

# References:
# https://wiki.archlinux.org/title/PipeWire

# Install PipeWire and WirePlumber
pacman -S --noconfirm \
    pipewire \
    pipewire-alsa \
    pipewire-jack \
    pipewire-pulse \
    libpulse \
    wireplumber --ask 4

# Enable PipeWire's user service
chown -R ${NEW_USER}:${NEW_USER} /home/${NEW_USER}
sudo -u ${NEW_USER} systemctl --user enable pipewire-pulse.service

################################################
##### Syncthing
################################################

# References:
# https://wiki.archlinux.org/title/syncthing

# Install Syncthing
pacman -S --noconfirm syncthing

# Enable Syncthing's user service
chown -R ${NEW_USER}:${NEW_USER} /home/${NEW_USER}
sudo -u ${NEW_USER} systemctl --user enable syncthing.service

################################################
##### Podman
################################################

# References:
# https://wiki.archlinux.org/title/Podman
# https://wiki.archlinux.org/title/Buildah
# https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md

# Install Podman and dependencies
pacman -S --noconfirm podman passt netavark aardvark-dns

# Install Buildah
pacman -S --noconfirm buildah

# Enable unprivileged ping
echo 'net.ipv4.ping_group_range=0 165535' > /etc/sysctl.d/99-unprivileged-ping.conf

# Create docker/podman alias
tee /home/${NEW_USER}/.zshrc.d/podman << EOF
alias docker=podman
EOF

# Re-enable unqualified search registries
tee -a /etc/containers/registries.conf.d/10-unqualified-search-registries.conf << EOF
unqualified-search-registries = ['docker.io', 'quay.io']
EOF

tee -a /etc/containers/registries.conf.d/01-registries.conf << EOF
[[registry]]
location = "docker.io"

[[registry]]
location = "quay.io"
EOF

# Enable Podman socket
systemctl --user enable podman.socket

################################################
##### Virtualization
################################################

# References:
# https://wiki.archlinux.org/title/Libvirt
# https://wiki.archlinux.org/title/QEMU
# https://wiki.archlinux.org/title/Virt-Manager

# Install QEMU and dependencies
pacman -S --noconfirm libvirt qemu-desktop dnsmasq virt-manager

# Add user to libvirt group
usermod -a -G libvirt ${NEW_USER}

# Enable libvirtd service
systemctl enable libvirtd.service

# Use as a normal user
# sed -i "s|^#unix_sock_group = \"libvirt\"|unix_sock_group = \"libvirt\"|g" /etc/libvirt/libvirtd.conf
# sed -i "s|^#unix_sock_rw_perms = \"0770\"|unix_sock_rw_perms = \"0770\"|g" /etc/libvirt/libvirtd.conf

# sed -i "s|^#user = \"libvirt-qemu\"|user = \"${NEW_USER}\"|g" /etc/libvirt/qemu.conf
# sed -i "s|^#group = \"libvirt-qemu\"|group = \"${NEW_USER}\"|g" /etc/libvirt/qemu.conf

################################################
##### Kubernetes / Cloud
################################################

# References:
# https://minikube.sigs.k8s.io/docs/drivers/kvm2/
# https://wiki.archlinux.org/title/Minikube

# Install and configure minikube
pacman -S --noconfirm minikube
mkdir -p /home/${NEW_USER}/.minikube/config
tee /home/${NEW_USER}/.minikube/config/config.json << 'EOF'
{
    "container-runtime": "containerd",
    "driver": "kvm2"
}
EOF

# Install k8s applications
pacman -S --noconfirm kubectl krew helm k9s kubectx cilium-cli talosctl

# Kubernetes aliases and autocompletion
tee /home/${NEW_USER}/.zshrc.d/kubernetes << 'EOF'
# Aliases
alias k="kubectl"
alias kx="kubectx"
alias kn="kubens"

# Autocompletion
autoload -Uz compinit
compinit
source <(kubectl completion zsh)
EOF

# Install OpenTofu
pacman -S --noconfirm opentofu

################################################
##### Development (languages, LSP, neovim)
################################################

# Set git configurations
sudo -u ${NEW_USER} git config --global init.defaultBranch main

# Create dev tools directory
mkdir -p /home/${NEW_USER}/.devtools

# Install NodeJS and npm
pacman -S --noconfirm nodejs npm

# Change npm's default directory
# https://docs.npmjs.com/resolving-eacces-permissions-errors-when-installing-packages-globally
mkdir /home/${NEW_USER}/.devtools/npm-global
chown -R ${NEW_USER}:${NEW_USER} /home/${NEW_USER}/.devtools/npm-global
sudo -u ${NEW_USER} npm config set prefix "/home/${NEW_USER}/.devtools/npm-global"
tee /home/${NEW_USER}/.zshrc.d/npm << 'EOF'
export PATH=$HOME/.devtools/npm-global/bin:$PATH
EOF

# Install Python uv
pacman -S --noconfirm uv

tee /home/${NEW_USER}/.zshrc.d/python << 'EOF'
# uv shell autocompletion
eval "$(uv generate-shell-completion zsh)"
eval "$(uvx --generate-shell-completion zsh)"
EOF

# Install Go
pacman -S --noconfirm go go-tools gopls
mkdir -p /home/${NEW_USER}/.devtools/go
tee /home/${NEW_USER}/.zshrc.d/go << 'EOF'
export GOPATH="$HOME/.devtools/go"
export PATH="$GOPATH/bin:$PATH"
EOF

# Install language servers
pacman -S --noconfirm \
    bash-language-server \
    eslint-language-server \
    python-lsp-server \
    typescript-language-server \
    vue-language-server \
    vscode-css-languageserver \
    vscode-html-languageserver \
    vscode-json-languageserver \
    yaml-language-server

# Install C++ development related packages
pacman -S --noconfirm llvm clang lld mold scons

# Install rust
pacman -S --noconfirm rust

# Install JDK
pacman -S --noconfirm jdk-openjdk

# Install eBPF development related packages
pacman -S --noconfirm \
    linux-headers \
    linux-lts-headers \
    bpf \
    bcc-tools \
    python-bcc \
    bpftrace

################################################
##### Android
################################################

# Install Android tools
pacman -S --noconfirm android-tools

# Install Android udev rules
pacman -S --noconfirm android-udev

# Create adbusers group
groupadd adbusers

# Add user to the adbusers group
usermod -a -G adbusers ${NEW_USER}

################################################
##### Neovim
################################################

# Install Neovim 
pacman -S --noconfirm neovim

# Set as default editor
tee /home/${NEW_USER}/.zshrc.d/neovim << 'EOF'
# Set neovim alias
alias vi=nvim
alias vim=nvim

# Set preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
  export VISUAL='vim'
else
  export EDITOR='nvim'
  export VISUAL='nvim'
fi
EOF

################################################
##### Power management
################################################

# References:
# https://wiki.archlinux.org/title/Power_management
# https://wiki.archlinux.org/title/CPU_frequency_scaling#cpupower
# https://gitlab.com/corectrl/corectrl/-/wikis/Setup
# https://wiki.archlinux.org/title/AMDGPU#Performance_levels

# Apply power managament configurations according to device type
if [[ $(cat /sys/class/dmi/id/chassis_type) -eq 10 ]]; then
    # Enable audio power saving features
    echo 'options snd_hda_intel power_save=1' > /etc/modprobe.d/audio_powersave.conf

    # Enable wifi (iwlwifi) power saving features
    echo 'options iwlwifi power_save=1' > /etc/modprobe.d/iwlwifi.conf
else
    if lspci | grep "VGA" | grep "AMD" > /dev/null; then
        # Install corectrl
        pacman -S --noconfirm corectrl

        # Launch CoreCtrl on session startup
        cp /usr/share/applications/org.corectrl.CoreCtrl.desktop /home/${NEW_USER}/.config/autostart/org.corectrl.CoreCtrl.desktop

        # Don't ask for user password
        curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/corectrl/90-corectrl.rules -o /etc/polkit-1/rules.d/90-corectrl.rules
        sed -i "s/your-user-group/${NEW_USER}/" /etc/polkit-1/rules.d/90-corectrl.rules

        # Import corectrl configs and profiles
        mkdir -p /home/${NEW_USER}/.config/corectrl/profiles
        curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/corectrl/corectrl.ini -o /home/${NEW_USER}/.config/corectrl/corectrl.ini
        curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/corectrl/profiles/_global_.ccpro -o /home/${NEW_USER}/.config/corectrl/profiles/_global_.ccpro
        curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/corectrl/profiles/alvr_dashboard.ccpro -o /home/${NEW_USER}/.config/corectrl/profiles/alvr_dashboard.ccpro
        curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/corectrl/profiles/wivrn_dashboard.ccpro -o /home/${NEW_USER}/.config/corectrl/profiles/wivrn_dashboard.ccpro
    fi
fi

# Install and enable thermald if CPU is Intel
if [[ $(cat /proc/cpuinfo | grep vendor | uniq) =~ "GenuineIntel" ]]; then
    pacman -S --noconfirm thermald
    systemctl enable thermald.service
fi

# Install and enable power profiles daemon
pacman -S --noconfirm power-profiles-daemon
systemctl enable power-profiles-daemon.service

################################################
##### VSCode
################################################

# Install VSCode
sudo -u ${NEW_USER} paru -S --noconfirm visual-studio-code-bin

# (Temporary - reverted at cleanup) Install Virtual framebuffer X server. Required to install VSCode extensions without a display server
pacman -S --noconfirm xorg-server-xvfb

# Install VSCode extensions
sudo -u ${NEW_USER} xvfb-run code --install-extension golang.Go
sudo -u ${NEW_USER} xvfb-run code --install-extension ms-python.python
sudo -u ${NEW_USER} xvfb-run code --install-extension redhat.vscode-yaml
sudo -u ${NEW_USER} xvfb-run code --install-extension hashicorp.terraform
sudo -u ${NEW_USER} xvfb-run code --install-extension rooveterinaryinc.roo-cline

# Import VSCode settings
mkdir -p /home/${NEW_USER}/.config/Code/User
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/vscode/settings.json -o /home/${NEW_USER}/.config/Code/User/settings.json

################################################
##### Fonts
################################################

# Install fonts
pacman -S --noconfirm \
    adwaita-fonts \
    noto-fonts \
    noto-fonts-emoji \
    noto-fonts-cjk \
    noto-fonts-extra \
    ttf-liberation \
    otf-cascadia-code \
    ttf-noto-nerd \
    ttf-hack \
    inter-font \
    cantarell-fonts \
    otf-font-awesome

################################################
##### Electron
################################################

# References:
# https://wiki.archlinux.org/title/Wayland#Electron

# Enable Wayland for electron apps and improve font rendering
tee /home/${NEW_USER}/.config/electron-flags.conf << EOF
--disable-font-subpixel-positioning
--enable-features=WaylandWindowDecorations
--ozone-platform-hint=auto
EOF

################################################
##### WireGuard
################################################

# Install wireguard-tools
pacman -S --noconfirm wireguard-tools

# Create WireGuard folder
mkdir -p /etc/wireguard
chmod 700 /etc/wireguard

################################################
##### Desktop Environment
################################################

# Enable bluetooth
systemctl enable bluetooth.service

# Install and configure desktop environment
if [ ${DESKTOP_ENVIRONMENT} = "plasma" ]; then
    /install-arch/plasma.sh
elif [ ${DESKTOP_ENVIRONMENT} = "gnome" ]; then
    /install-arch/gnome.sh
fi

# Hide applications from menus
APPLICATIONS=('assistant' 'avahi-discover' 'designer' 'electron' 'electron21' 'htop' 'linguist' 'lstopo' 'nvim' 'org.kde.kuserfeedback-console' 'qdbusviewer' 'qt5ct' 'qv4l2' 'qvidcap' 'bssh' 'bvnc' 'mpv')
for APPLICATION in "${APPLICATIONS[@]}"
do
    # Create a local copy of the desktop files and append properties
    cp /usr/share/applications/${APPLICATION}.desktop /home/${NEW_USER}/.local/share/applications/${APPLICATION}.desktop 2>/dev/null || : 

    if test -f "/home/${NEW_USER}/.local/share/applications/${APPLICATION}.desktop"; then
        echo "NoDisplay=true" >> /home/${NEW_USER}/.local/share/applications/${APPLICATION}.desktop
        echo "Hidden=true" >> /home/${NEW_USER}/.local/share/applications/${APPLICATION}.desktop
        echo "NotShowIn=KDE;GNOME;" >> /home/${NEW_USER}/.local/share/applications/${APPLICATION}.desktop
    fi
done

################################################
##### Gaming / XR related applications
################################################

# Install Steam
if [ ${STEAM_NATIVE} = "yes" ]; then
    /install-arch/steam.sh
fi

# Install Sunshine
if [ ${SUNSHINE_NATIVE} = "yes" ]; then
    /install-arch/sunshine.sh
fi

# Install VR related apps
if [ ${VR_NATIVE} = "yes" ]; then
    /install-arch/vr.sh
fi

################################################
##### Cleanup
################################################

# Make sure that all /home/$NEW_USER actually belongs to $NEW_USER 
chown -R ${NEW_USER}:${NEW_USER} /home/${NEW_USER}

# Revert sudoers change
sed -i "/${NEW_USER} ALL=NOPASSWD:\/usr\/bin\/pacman/d" /etc/sudoers

# Remove Virtual framebuffer X server
pacman -Rs --noconfirm xorg-server-xvfb
