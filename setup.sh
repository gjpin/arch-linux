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

if [ ${STEAM_VERSION} = "native" ]; then
    # Enable multilib repository
    sed -i '/#\[multilib\]/{N;s/#\[multilib\]\n#Include = \/etc\/pacman.d\/mirrorlist/\[multilib\]\nInclude = \/etc\/pacman.d\/mirrorlist/}' /etc/pacman.conf
fi

# Always ignore amdvlk packages
# sed -i '/^#IgnorePkg/s/^#//' /etc/pacman.conf
# sed -i '/^IgnorePkg/s/$/ amdvlk lib32-amdvlk/' /etc/pacman.conf

# Force pacman to refresh the package lists
pacman -Syyu

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

################################################
##### Common applications
################################################

# Install common applications
pacman -S --noconfirm \
    coreutils \
    htop \
    git \
    p7zip \
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
    wireguard-tools \
    rsync \
    jq \
    yq \
    lazygit \
    ripgrep \
    fd \
    gptfdisk \
    bc

# Add AppImage support
pacman -S --noconfirm fuse3

################################################
##### zram (swap)
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
ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler} "mq-deadline"
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler} "bfq"
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
pacman -S --noconfirm zsh fzf

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
  /home/${NEW_USER}/.config/autostart \
  /home/${NEW_USER}/.config/environment.d \
  /home/${NEW_USER}/.config/autostart \
  /home/${NEW_USER}/.config/systemd/user \
  /home/${NEW_USER}/.icons \
  /home/${NEW_USER}/src

# Create SSH directory and config file
mkdir -p /home/${NEW_USER}/.ssh

chown 700 /home/${NEW_USER}/.ssh

tee /home/${NEW_USER}/.ssh/config << EOF
Host *
    ServerAliveInterval 60
EOF

# Create zsh configs directory
mkdir -p /home/${NEW_USER}/.zshrc.d

# Updater helper
tee /home/${NEW_USER}/.zshrc.d/update-all << EOF
update-all() {
    # Update keyring
    sudo pacman -Sy --noconfirm archlinux-keyring

    # Update all packages
    paru -Syyu

    # Update firmware
    sudo fwupdmgr refresh
    sudo fwupdmgr update
    
    # Update Flatpak apps
    flatpak update -y
}
EOF

# Configure ZSH
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/zsh/.zshrc -o /home/${NEW_USER}/.zshrc

# Configure powerlevel10k zsh theme
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/zsh/.p10k.zsh -o /home/${NEW_USER}/.p10k.zsh

# Add ~/.local/bin to the path
mkdir -p /home/${NEW_USER}/.local/bin

tee /home/${NEW_USER}/.zshrc.d/local-bin << 'EOF'
# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH
EOF

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

# Set default zone to block
firewall-offline-cmd --set-default-zone=block

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
##### initramfs
################################################

# References:
# https://wiki.archlinux.org/title/RAID#Configure_mkinitcpio

# Configure mkinitcpio
sed -i "s|MODULES=()|MODULES=(ext4${MKINITCPIO_MODULES})|" /etc/mkinitcpio.conf
sed -i "s|^HOOKS.*|HOOKS=(systemd autodetect keyboard sd-vconsole modconf block $(if [ ${RAID0} = "yes" ]; then echo "mdadm_udev"; fi) sd-encrypt filesystems fsck)|" /etc/mkinitcpio.conf
sed -i "s|#COMPRESSION=\"zstd\"|COMPRESSION=\"zstd\"|" /etc/mkinitcpio.conf
sed -i "s|#COMPRESSION_OPTIONS=()|COMPRESSION_OPTIONS=(-2)|" /etc/mkinitcpio.conf

# Re-create initramfs image
mkinitcpio -P

################################################
##### systemd-boot
################################################

# References:
# https://wiki.archlinux.org/title/systemd-boot
# https://wiki.archlinux.org/title/RAID#RAID0_layout
# https://wiki.archlinux.org/title/CPU_frequency_scaling#amd_pstate

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
default  arch.conf
timeout  0
console-mode max
editor   no
EOF

tee /boot/loader/entries/arch.conf << EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /${CPU_MICROCODE}.img
initrd  /initramfs-linux.img
options $(if [ ${RAID0} = "yes" ]; then echo "raid0.default_layout=2"; fi) rd.luks.name=$(if [ ${RAID0} = "no" ]; then blkid -s UUID -o value /dev/nvme0n1p2; elif [ ${RAID0} = "yes" ]; then blkid -s UUID -o value /dev/md/ArchArray;fi)=system root=/dev/mapper/system ${AMD_SCALING_DRIVER} zswap.enabled=0 nowatchdog quiet loglevel=3 systemd.show_status=auto rd.udev.log_level=3 vt.global_cursor_default=0 splash rw
EOF

tee /boot/loader/entries/arch-lts.conf << EOF
title   Arch Linux LTS
linux   /vmlinuz-linux-lts
initrd  /${CPU_MICROCODE}.img
initrd  /initramfs-linux-lts.img
options $(if [ ${RAID0} = "yes" ]; then echo "raid0.default_layout=2"; fi) rd.luks.name=$(if [ ${RAID0} = "no" ]; then blkid -s UUID -o value /dev/nvme0n1p2; elif [ ${RAID0} = "yes" ]; then blkid -s UUID -o value /dev/md/ArchArray;fi)=system root=/dev/mapper/system ${AMD_SCALING_DRIVER} zswap.enabled=0 nowatchdog quiet loglevel=3 systemd.show_status=auto rd.udev.log_level=3 vt.global_cursor_default=0 splash rw
EOF

################################################
##### Unlock LUKS with TPM2
################################################

# References:
# https://wiki.archlinux.org/title/Trusted_Platform_Module#systemd-cryptenroll

# Install TPM2-tools
pacman -S --noconfirm tpm2-tools tpm2-tss

# Configure initramfs to unlock the encrypted volume
sed -i "s|=system|& rd.luks.options=$(if [ ${RAID0} = "no" ]; then blkid -s UUID -o value /dev/nvme0n1p2; elif [ ${RAID0} = "yes" ]; then blkid -s UUID -o value /dev/md/ArchArray;fi)=tpm2-device=auto|" /boot/loader/entries/arch.conf
sed -i "s|=system|& rd.luks.options=$(if [ ${RAID0} = "no" ]; then blkid -s UUID -o value /dev/nvme0n1p2; elif [ ${RAID0} = "yes" ]; then blkid -s UUID -o value /dev/md/ArchArray;fi)=tpm2-device=auto|" /boot/loader/entries/arch-lts.conf

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
sbctl enroll-keys --microsoft --firmware-builtin

# Sign files with secure boot keys
sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
sbctl sign -s /boot/EFI/systemd/systemd-bootx64.efi
sbctl sign -s /boot/vmlinuz-linux
sbctl sign -s /boot/vmlinuz-linux-lts

################################################
##### Paru
################################################

# References:
# https://github.com/Morganamilo/paru

# (Temporary - reverted at cleanup) Allow $NEW_USER to run pacman without password
echo "${NEW_USER} ALL=NOPASSWD:/usr/bin/pacman" >> /etc/sudoers

# Install paru
git clone https://aur.archlinux.org/paru-bin.git
chown -R ${NEW_USER}:${NEW_USER} paru-bin
cd paru-bin
sudo -u ${NEW_USER} makepkg -si --noconfirm
cd ..
rm -rf paru-bin

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

# Install 32-bit packages
if [ ${STEAM_VERSION} = "native" ]; then
    pacman -S --noconfirm lib32-mesa lib32-vulkan-icd-loader lib32-vulkan-mesa-layers

    if lspci | grep "VGA" | grep "Intel" > /dev/null; then
        pacman -S --noconfirm lib32-vulkan-intel
    elif lspci | grep "VGA" | grep "AMD" > /dev/null; then
        pacman -S --noconfirm lib32-vulkan-radeon lib32-libva-mesa-driver
    fi
fi

# Override VA-API driver via environment variable
tee -a /etc/environment << EOF

# VA-API
${LIBVA_ENV_VAR}
EOF

# If GPU is AMD, use RADV's Vulkan driver
if lspci | grep "VGA" | grep "AMD" > /dev/null; then
tee -a /etc/environment << EOF

# Vulkan
AMD_VULKAN_ICD=RADV
EOF
fi

# Install VA-API tools
pacman -S --noconfirm libva-utils

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
##### Flatpak
################################################

# References
# https://wiki.archlinux.org/title/Flatpak
# https://github.com/containers/bubblewrap/issues/324

# Install Flatpak and applications
pacman -S --noconfirm flatpak xdg-desktop-portal-gtk
chown -R ${NEW_USER}:${NEW_USER} /home/${NEW_USER}
sudo -u ${NEW_USER} systemctl --user enable xdg-desktop-portal.service

# Bubblewrap workaround (Temporary - reverted at cleanup)
# chmod u+s /usr/bin/bwrap

# Add Flathub repositories
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak update

# Import global Flatpak overrides
mkdir -p /home/${NEW_USER}/.local/share/flatpak/overrides
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/global -o /home/${NEW_USER}/.local/share/flatpak/overrides/global

# Install Flatpak runtimes
flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full/x86_64/23.08
flatpak install -y flathub org.freedesktop.Platform.GStreamer.gstreamer-vaapi/x86_64/23.08
flatpak install -y flathub org.freedesktop.Sdk.Extension.llvm16//23.08
flatpak install -y flathub org.freedesktop.Sdk.Extension.rust-stable//23.08
flatpak install -y flathub org.freedesktop.Platform.GL.default//23.08-extra
flatpak install -y flathub org.freedesktop.Platform.GL32.default//23.08-extra

if lspci | grep VGA | grep "Intel" > /dev/null; then
  flatpak install -y flathub org.freedesktop.Platform.VAAPI.Intel/x86_64/23.08
fi

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
##### Docker
################################################

# References:
# https://wiki.archlinux.org/title/docker

# Install Docker and plugins
pacman -S --noconfirm docker docker-compose docker-buildx

# Enable Docker service
systemctl enable docker.socket

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
gpasswd -a ${NEW_USER} libvirt

# Enable libvirtd service
systemctl enable libvirtd.service

# Use as a normal user
# sed -i "s|^#unix_sock_group = \"libvirt\"|unix_sock_group = \"libvirt\"|g" /etc/libvirt/libvirtd.conf
# sed -i "s|^#unix_sock_rw_perms = \"0770\"|unix_sock_rw_perms = \"0770\"|g" /etc/libvirt/libvirtd.conf

# sed -i "s|^#user = \"libvirt-qemu\"|user = \"${NEW_USER}\"|g" /etc/libvirt/qemu.conf
# sed -i "s|^#group = \"libvirt-qemu\"|group = \"${NEW_USER}\"|g" /etc/libvirt/qemu.conf

################################################
##### Kubernetes
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
pacman -S --noconfirm kubectl helm k9s kubectx

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

################################################
##### User applications
################################################

# Install user applications
flatpak install -y flathub org.keepassxc.KeePassXC
flatpak install -y flathub com.bitwarden.desktop
flatpak install -y flathub org.libreoffice.LibreOffice
flatpak install -y flathub com.brave.Browser
flatpak install -y flathub com.belmoussaoui.Authenticator

# Install Joplin
flatpak install -y flathub net.cozic.joplin_desktop
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/net.cozic.joplin_desktop -o /home/${NEW_USER}/.local/share/flatpak/overrides/net.cozic.joplin_desktop

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

# Install Python and create alias for python venv
pacman -S --noconfirm python
mkdir -p /home/${NEW_USER}/.devtools/python
chown -R ${NEW_USER}:${NEW_USER} /home/${NEW_USER}/.devtools/python
sudo -u ${NEW_USER} python -m venv /home/${NEW_USER}/.devtools/python/dev
tee /home/${NEW_USER}/.zshrc.d/python << 'EOF'
alias pydev="source ${HOME}/.devtools/python/dev/bin/activate"
EOF

# Install Go
pacman -S --noconfirm go go-tools gopls
mkdir -p /home/${NEW_USER}/.devtools/go
tee /home/${NEW_USER}/.zshrc.d/go << 'EOF'
export GOPATH="$HOME/.devtools/go"
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

# Install Terraform
pacman -S --noconfirm terraform vault

# Install C++ development related packages
pacman -S --noconfirm llvm clang lld mold scons

# Install rust
pacman -S --noconfirm rust

################################################
##### Neovim
################################################

# Install Neovim and set as default editor
pacman -S --noconfirm neovim
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

# Install LazyVim
# https://www.lazyvim.org/installation
git clone https://github.com/LazyVim/starter /home/${NEW_USER}/.config/nvim
rm -rf /home/${NEW_USER}/.config/nvim/.git

# Install arctic.nvim (Dark Modern) color scheme in neovim
# https://github.com/rockyzhang24/arctic.nvim/tree/v2
# https://www.lazyvim.org/plugins/colorscheme
tee /home/${NEW_USER}/.config/nvim/lua/plugins/colorscheme.lua << 'EOF'
return {
    {
        "gjpin/arctic.nvim",
        branch = "v2",
        dependencies = { "rktjmp/lush.nvim" }
    },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "arctic",
        }
    }
}
EOF

################################################
##### thermald
################################################

# Install and enable thermald if CPU is Intel
if [[ $(cat /proc/cpuinfo | grep vendor | uniq) =~ "GenuineIntel" ]]; then
    pacman -S --noconfirm thermald
    systemctl enable thermald.service
fi

################################################
##### Power saving
################################################

# References:
# https://wiki.archlinux.org/title/Power_management

# If device is a laptop, apply more power saving configurations
if [[ $(cat /sys/class/dmi/id/chassis_type) -eq 10 ]]; then
    # Enable audio power saving features
    echo 'options snd_hda_intel power_save=1' > /etc/modprobe.d/audio_powersave.conf

    # Enable wifi (iwlwifi) power saving features
    echo 'options iwlwifi power_save=1' > /etc/modprobe.d/iwlwifi.conf

    # Rebuild initramfs
    mkinitcpio -P
fi

################################################
##### Firefox (Flatpak)
################################################

# Install Firefox
flatpak install -y flathub org.mozilla.firefox

# Set Firefox as default browser and handler for http/s
sudo -u ${NEW_USER} xdg-settings set default-web-browser org.mozilla.firefox.desktop
sudo -u ${NEW_USER} xdg-mime default org.mozilla.firefox.desktop x-scheme-handler/http
sudo -u ${NEW_USER} xdg-mime default org.mozilla.firefox.desktop x-scheme-handler/https

# Temporarily open firefox to create profile 
sudo -u ${NEW_USER} timeout 5 flatpak run org.mozilla.firefox --headless

# Set Firefox profile path
export FIREFOX_PROFILE_PATH=$(find /home/${NEW_USER}/.var/app/org.mozilla.firefox/.mozilla/firefox -type d -name "*.default-release")

# Import extensions
mkdir -p ${FIREFOX_PROFILE_PATH}/extensions
curl https://addons.mozilla.org/firefox/downloads/file/4003969/ublock_origin-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/uBlock0@raymondhill.net.xpi
curl https://addons.mozilla.org/firefox/downloads/file/4018008/bitwarden_password_manager-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/{446900e4-71c2-419f-a6a7-df9c091e268b}.xpi
curl https://addons.mozilla.org/firefox/downloads/file/3998783/floccus-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/floccus@handmadeideas.org.xpi
curl https://addons.mozilla.org/firefox/downloads/file/3932862/multi_account_containers-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/@testpilot-containers.xpi
curl https://addons.mozilla.org/firefox/downloads/file/4307919/steam_database.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/firefox-extension@steamdb.info.xpi

# Import Firefox configs
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/firefox/user.js -o ${FIREFOX_PROFILE_PATH}/user.js

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
sudo -u ${NEW_USER} xvfb-run code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
sudo -u ${NEW_USER} xvfb-run code --install-extension esbenp.prettier-vscode
sudo -u ${NEW_USER} xvfb-run code --install-extension dbaeumer.vscode-eslint
sudo -u ${NEW_USER} xvfb-run code --install-extension hashicorp.terraform

# Import VSCode settings
mkdir -p /home/${NEW_USER}/.config/Code/User
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/vscode/settings.json -o /home/${NEW_USER}/.config/Code/User/settings.json

################################################
##### Desktop Environment
################################################

# Install fonts
pacman -S --noconfirm \
    noto-fonts \
    noto-fonts-emoji \
    noto-fonts-cjk \
    noto-fonts-extra \
    ttf-liberation \
    otf-cascadia-code \
    ttf-firacode-nerd \
    ttf-hack-nerd \
 	ttf-noto-nerd \
    ttf-sourcecodepro-nerd \
    ttf-ubuntu-nerd \
    ttf-ubuntu-mono-nerd \
    ttf-hack \
    inter-font \
    cantarell-fonts \
    otf-font-awesome

# Install and enable power profiles daemon
pacman -S --noconfirm power-profiles-daemon
systemctl enable power-profiles-daemon.service

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
##### Gaming
################################################

# Install and configure gaming with Flatpak
if [ ${GAMING} = "yes" ]; then
    /install-arch/gaming.sh
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

# Revert temporary bubblewrap workaround
# chmod u-s /usr/bin/bwrap