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

# Force pacman to refresh the package lists
pacman -Syy

# Initialize Pacman's keyring
pacman-key --init
pacman-key --populate

# Configure Pacman
sed -i "s|^#Color|Color|g" /etc/pacman.conf
sed -i "s|^#VerbosePkgLists|VerbosePkgLists|g" /etc/pacman.conf
sed -i "s|^#ParallelDownloads.*|ParallelDownloads = 5|g" /etc/pacman.conf
sed -i "/ParallelDownloads = 5/a ILoveCandy" /etc/pacman.conf

# Enable multilib repository
tee -a /etc/pacman.conf << EOF
[multilib]
Include = /etc/pacman.d/mirrorlist
EOF

# Upgrade system
pacman -Syu

################################################
##### ZSH and common applications
################################################

# Install ZSH and plugins
pacman -S --noconfirm zsh zsh-completions grml-zsh-config zsh-autosuggestions zsh-syntax-highlighting

# Install common applications
pacman -S --noconfirm \
    coreutils \
    htop \
    git \
    p7zip \
    ripgrep \
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
    jq

# Add AppImage support
pacman -S --noconfirm \
    fuse-common \
    fuse2 \
    fuse3 \
    fuse2fs

################################################
##### Swap
################################################

# References:
# https://wiki.archlinux.org/title/swap#Swap_file
# https://wiki.archlinux.org/title/swap#Swappiness
# https://wiki.archlinux.org/title/Improving_performance#zram_or_zswap
# https://wiki.gentoo.org/wiki/Zram
# https://www.dwarmstrong.org/zram-swap/
# https://www.reddit.com/r/Fedora/comments/mzun99/new_zram_tuning_benchmarks/

# Create swap file
dd if=/dev/zero of=/swapfile bs=1M count=8k status=progress

# Set swapfile permissions
chmod 0600 /swapfile

# Format swapfile to swap
mkswap -U clear /swapfile

# Activate swap file
swapon /swapfile

# Add swapfile to fstab configuration
tee -a /etc/fstab << EOF
# swapfile
/swapfile none swap defaults 0 0
EOF

# Set swappiness
echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf

# Set vfs cache pressure
echo 'vm.vfs_cache_pressure=50' > /etc/sysctl.d/99-vfs-cache-pressure.conf

################################################
##### Tweaks
################################################

# References:
# https://github.com/CryoByte33/steam-deck-utilities/blob/main/docs/tweak-explanation.md
# https://wiki.cachyos.org/en/home/General_System_Tweaks

# Split Lock Mitigate - default: 1
echo 'kernel.split_lock_mitigate=0' > /etc/sysctl.d/99-splitlock.conf

# Compaction Proactiveness - default: 20
echo 'vm.compaction_proactiveness=0' > /etc/sysctl.d/99-compaction_proactiveness.conf

# Page Lock Unfairness - default: 5
echo 'vm.page_lock_unfairness=1' > /etc/sysctl.d/99-page_lock_unfairness.conf

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

# Increase vm.max_map_count
# Same as Fedora and SteamOS: https://fedoraproject.org/wiki/Changes/IncreaseVmMaxMapCount
echo 'vm.max_map_count=1048576' > /etc/sysctl.d/99-max-map-count.conf

################################################
##### Users
################################################

# References:
# https://wiki.archlinux.org/title/XDG_Base_Directory

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

# Configure ZSH
tee /home/${NEW_USER}/.zshrc.local << EOF
# ZSH configs
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
EOF

# Create common directories and configure them
mkdir -p \
  /home/${NEW_USER}/.local/share/applications \
  /home/${NEW_USER}/.local/share/themes \
  /home/${NEW_USER}/.local/share/fonts \
  /home/${NEW_USER}/.local/bin \
  /home/${NEW_USER}/.config/autostart \
  /home/${NEW_USER}/.config/environment.d \
  /home/${NEW_USER}/.config/autostart \
  /home/${NEW_USER}/.ssh \
  /home/${NEW_USER}/.icons \
  /home/${NEW_USER}/src

chown 700 /home/${NEW_USER}/.ssh

tee -a /home/${NEW_USER}/.zshenv << 'EOF'

# Add $HOME/.local/bin/ to the PATH
export PATH="${HOME}/.local/bin/:${PATH}"
EOF

# Updater helper
tee -a /home/${NEW_USER}/.zshrc.local << EOF

# Update helper
update-all() {
    # Update keyring
    sudo pacman -Sy --noconfirm archlinux-keyring

    # Update system
    sudo pacman -Syu

    # Update AUR packages
    paru -Syu

    # Update firmware
    sudo fwupdmgr refresh
    sudo fwupdmgr update
    
    # Update Flatpak apps
    flatpak update -y
}
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

# Configure mkinitcpio
sed -i "s|MODULES=()|MODULES=(ext4${MKINITCPIO_MODULES})|" /etc/mkinitcpio.conf
sed -i "s|^HOOKS.*|HOOKS=(systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems fsck)|" /etc/mkinitcpio.conf
sed -i "s|#COMPRESSION=\"zstd\"|COMPRESSION=\"zstd\"|" /etc/mkinitcpio.conf
sed -i "s|#COMPRESSION_OPTIONS=()|COMPRESSION_OPTIONS=(-2)|" /etc/mkinitcpio.conf

# Re-create initramfs image
mkinitcpio -P

################################################
##### systemd-boot
################################################

# References:
# https://wiki.archlinux.org/title/systemd-boot

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
options rd.luks.name=$(blkid -s UUID -o value /dev/nvme0n1p2)=system root=/dev/mapper/system zswap.compressor=zstd zswap.max_pool_percent=10 nowatchdog quiet loglevel=3 systemd.show_status=auto rd.udev.log_level=3 vt.global_cursor_default=0 splash rw
EOF

tee /boot/loader/entries/arch-lts.conf << EOF
title   Arch Linux LTS
linux   /vmlinuz-linux-lts
initrd  /${CPU_MICROCODE}.img
initrd  /initramfs-linux-lts.img
options rd.luks.name=$(blkid -s UUID -o value /dev/nvme0n1p2)=system root=/dev/mapper/system zswap.compressor=zstd zswap.max_pool_percent=10 nowatchdog quiet loglevel=3 systemd.show_status=auto rd.udev.log_level=3 vt.global_cursor_default=0 splash rw
EOF

################################################
##### Unlock LUKS with TPM2
################################################

# References:
# https://wiki.archlinux.org/title/Trusted_Platform_Module#systemd-cryptenroll

# Install TPM2-tools
pacman -S --noconfirm tpm2-tools tpm2-tss

# Configure initramfs to unlock the encrypted volume
sed -i "s|=system|& rd.luks.options=$(blkid -s UUID -o value /dev/nvme0n1p2)=tpm2-device=auto|" /boot/loader/entries/arch.conf
sed -i "s|=system|& rd.luks.options=$(blkid -s UUID -o value /dev/nvme0n1p2)=tpm2-device=auto|" /boot/loader/entries/arch-lts.conf

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
sbctl enroll-keys --microsoft

# Sign files with secure boot keys
sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
sbctl sign -s /boot/EFI/systemd/systemd-bootx64.efi
sbctl sign -s /boot/vmlinuz-linux
sbctl sign -s /boot/vmlinuz-linux-lts

################################################
##### GPU
################################################

# References:
# https://wiki.archlinux.org/title/intel_graphics
# https://wiki.archlinux.org/title/AMDGPU
# https://wiki.archlinux.org/title/Hardware_video_acceleration
# https://wiki.archlinux.org/title/Vulkan

# Install GPU drivers related packages
pacman -S --noconfirm mesa lib32-mesa vulkan-icd-loader vulkan-mesa-layers ${GPU_PACKAGES}

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

# Install ffmpeg
pacman -S --noconfirm ffmpeg

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
sudo -u ${NEW_USER} systemctl --user enable pipewire-pulse.service

################################################
##### Flatpak
################################################

# References
# https://wiki.archlinux.org/title/Flatpak

# Install Flatpak and applications
pacman -S --noconfirm flatpak xdg-desktop-portal-gtk
sudo -u ${NEW_USER} systemctl --user enable xdg-desktop-portal.service

# Add Flathub repositories
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak update

# Global override to deny all applications the permission to access certain directories
flatpak override --nofilesystem='home' --nofilesystem='host' --nofilesystem='xdg-cache' --nofilesystem='xdg-config' --nofilesystem='xdg-data'

# Allow read-only access to GTK configs
flatpak override --filesystem=xdg-config/gtk-3.0:ro
flatpak override --filesystem=xdg-config/gtk-4.0:ro

# Allow access to Downloads directory
flatpak override --filesystem=xdg-download

# Install runtimes
flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full/x86_64/22.08
flatpak install -y flathub org.freedesktop.Platform.GStreamer.gstreamer-vaapi/x86_64/22.08
flatpak install -y flathub org.freedesktop.Platform.GL32.default/x86_64/22.08
flatpak install -y flathub org.freedesktop.Platform.GL.default/x86_64/22.08
flatpak install -y flathub org.freedesktop.Platform.VAAPI.Intel/x86_64/22.08
flatpak install -y flathub org.gnome.Platform.Compat.i386/x86_64/43

# Install GTK themes
flatpak install -y flathub org.gtk.Gtk3theme.Breeze
flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3
flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3-dark

################################################
##### Syncthing
################################################

# References:
# https://wiki.archlinux.org/title/syncthing

# Install Syncthing
pacman -S --noconfirm syncthing

# Enable Syncthing's user service
sudo -u ${NEW_USER} systemctl --user enable syncthing.service

################################################
##### Podman
################################################

# References:
# https://wiki.archlinux.org/title/Podman
# https://wiki.archlinux.org/title/Buildah
# https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md

# Install Podman and dependencies
pacman -S --noconfirm podman slirp4netns netavark aardvark-dns

# Install Podman Compose
pacman -S --noconfirm podman-compose podman-dnsname

# Instlal Buildah and dependencies
pacman -S --noconfirm buildah fuse-overlayfs

# Enable kernel.unprivileged_userns_clone
echo 'kernel.unprivileged_userns_clone=1' > /etc/sysctl.d/99-unprivileged-userns-clone.conf

# Set subuid and subgid
usermod --add-subuids 100000-165535 --add-subgids 100000-165535 ${NEW_USER}

# Enable unprivileged ping
echo 'net.ipv4.ping_group_range=0 165535' > /etc/sysctl.d/99-unprivileged-ping.conf

# Create docker/podman alias
tee -a /home/${NEW_USER}/.zshrc.local << EOF

# Podman
alias docker=podman
EOF

# Re-enable unqualified search registries
tee -a /etc/containers/registries.conf.d/00-unqualified-search-registries.conf << EOF
unqualified-search-registries = ["docker.io"]
EOF

tee -a /etc/containers/registries.conf.d/01-registries.conf << EOF
[[registry]]
location = "docker.io"
EOF

################################################
##### Virtualization
################################################

# References:
# https://wiki.archlinux.org/title/Libvirt
# https://wiki.archlinux.org/title/QEMU

# Install QEMU and dependencies
pacman -S --noconfirm libvirt qemu-desktop dnsmasq

# Add user to libvirt group
gpasswd -a ${NEW_USER} libvirt

# Enable libvirtd service
systemctl enable libvirtd.service

################################################
##### Kubernetes
################################################

# References:
# https://minikube.sigs.k8s.io/docs/drivers/kvm2/
# https://wiki.archlinux.org/title/Minikube

# Install and configure minikube
pacman -S --noconfirm minikube

sudo -u ${NEW_USER} minikube config set driver kvm2
sudo -u ${NEW_USER} minikube config set container-runtime containerd

tee -a /home/${NEW_USER}/.zshenv << 'EOF'

# minikube
export MINIKUBE_IN_STYLE=0
EOF

# Install k8s applications
pacman -S --noconfirm kubectl helm k9s

################################################
##### Cloud
################################################

# Install HashiCorp tools
pacman -S --noconfirm terraform packer

################################################
##### Paru
################################################

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
##### User applications
################################################

# Install user applications
pacman -S --noconfirm \
    chromium \
    libreoffice-fresh \
    blender \
    bitwarden \
    keepassxc \
    obsidian

sudo -u ${NEW_USER} paru -S --noconfirm \
    spotify \
    insomnia-bin \
    podman-desktop-bin

################################################
##### Development (languages, LSP, neovim)
################################################

# Go
pacman -S --noconfirm go go-tools gopls

tee -a /home/${NEW_USER}/.zshenv << 'EOF'

# Go
export GOPATH="${HOME}/.go"
export PATH="${GOPATH}/bin:${PATH}"
EOF

# Node.js
pacman -S --noconfirm nodejs npm

# Neovim
pacman -S --noconfirm neovim

tee -a /home/${NEW_USER}/.zshrc.local << EOF

# Neovim
alias vi=nvim
alias vim=nvim
EOF

tee -a /etc/environment << EOF

# Editor
EDITOR=nvim
VISUAL=nvim
EOF

# Language servers
pacman -S --noconfirm \
    typescript-language-server \
    bash-language-server \
    python-lsp-server \
    yaml-language-server

################################################
##### Wayland configurations
################################################

# References:
# https://wiki.archlinux.org/title/Wayland#Electron
# https://wiki.archlinux.org/title/wayland#XWayland

# Run Electron applications natively under Wayland
# tee /home/${NEW_USER}/.config/electron-flags.conf << EOF
# --enable-features=WaylandWindowDecorations
# --ozone-platform-hint=auto
# EOF

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

    # Reduce VM writeback time
    echo 'vm.dirty_writeback_centisecs=6000' > /etc/sysctl.d/99-vm-writeback-time.conf

    # Rebuild initramfs
    mkinitcpio -P
fi

################################################
##### Firefox
################################################

# References:
# https://wiki.archlinux.org/title/Firefox
# https://github.com/pyllyukko/user.js/blob/master/user.js

# Install Firefox
pacman -S --noconfirm firefox

# Set Firefox as default browser and handler for http/s
sudo -u ${NEW_USER} xdg-settings set default-web-browser firefox.desktop
sudo -u ${NEW_USER} xdg-mime default firefox.desktop x-scheme-handler/http
sudo -u ${NEW_USER} xdg-mime default firefox.desktop x-scheme-handler/https

# Run Firefox natively under Wayland
tee -a /home/${NEW_USER}/.zshenv << EOF

# Firefox
export MOZ_ENABLE_WAYLAND=1
EOF

################################################
##### VSCode
################################################

# Install VSCode
sudo -u ${NEW_USER} paru -S --noconfirm visual-studio-code-bin

# (Temporary - reverted at cleanup) Install Virtual framebuffer X server. Required to install VSCode extensions without a display server
pacman -S --noconfirm xorg-server-xvfb

# Install VSCode extensions
sudo -u ${NEW_USER} xvfb-run code --install-extension golang.Go
sudo -u ${NEW_USER} xvfb-run code --install-extension HashiCorp.terraform
sudo -u ${NEW_USER} xvfb-run code --install-extension HashiCorp.HCL
sudo -u ${NEW_USER} xvfb-run code --install-extension redhat.vscode-yaml
sudo -u ${NEW_USER} xvfb-run code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
sudo -u ${NEW_USER} xvfb-run code --install-extension esbenp.prettier-vscode
sudo -u ${NEW_USER} xvfb-run code --install-extension dbaeumer.vscode-eslint

# Import VSCode settings
mkdir -p "/home/${NEW_USER}/.config/Code/User"
tee "/home/${NEW_USER}/.config/Code/User/settings.json" << EOF
{
    "window.menuBarVisibility": "toggle",
    "workbench.startupEditor": "none",
    "editor.fontFamily": "'Hack','Noto Sans Mono'",
    "workbench.settings.enableNaturalLanguageSearch": false,
    "workbench.iconTheme": null,
    "workbench.tree.indent": 12,
    "window.titleBarStyle": "native",
    "files.associations": {
      "*.j2": "terraform",
      "*.hcl": "terraform",
      "*.bu": "yaml",
      "*.ign": "json",
      "*.service": "ini"
    },
    "git.enableSmartCommit": true,
    "git.confirmSync": false,
    "git.autofetch": true,
    "git.useIntegratedAskPass": false,
    "workbench.enableExperiments": false,
	"clangd.checkUpdates": false,
	"code-runner.enableAppInsights": false,
	"docker-explorer.enableTelemetry": false,
	"extensions.ignoreRecommendations": true,
	"gitlens.showWelcomeOnInstall": false,
	"gitlens.showWhatsNewAfterUpgrades": false,
	"java.help.firstView": "none",
	"java.help.showReleaseNotes": false,
	"julia.enableTelemetry": false,
	"kite.showWelcomeNotificationOnStartup": false,
	"liveServer.settings.donotShowInfoMsg": true,
	"Lua.telemetry.enable": false,
	"material-icon-theme.showWelcomeMessage": false,
	"pros.showWelcomeOnStartup": false,
	"pros.useGoogleAnalytics": false,
	"redhat.telemetry.enabled": false,
	"rpcServer.showStartupMessage": false,
	"shellcheck.disableVersionCheck": true,
	"sonarlint.disableTelemetry": true,
	"telemetry.telemetryLevel": "off",
	"terraform.telemetry.enabled": false,
	"update.showReleaseNotes": false,
	"vsicons.dontShowNewVersionMessage": true,
	"workbench.welcomePage.walkthroughs.openOnInstall": false,
	"[typescript]": {
		"editor.defaultFormatter": "esbenp.prettier-vscode"
	},
	"[javascript]": {
		"editor.defaultFormatter": "esbenp.prettier-vscode"
	},
	"editor.formatOnSave": true
}
EOF

# Run VSCode under Wayland
# ln -s /home/${NEW_USER}/.config/electron-flags.conf /home/${NEW_USER}/.config/code-flags.conf

################################################
##### OpenSnitch
################################################

# Install OpenSnitch
# pacman -S --noconfirm opensnitch

# Enable OpenSnitch
# systemctl enable opensnitchd.service

# Autostart OpenSnitch UI
# ln -s /usr/share/applications/opensnitch_ui.desktop /home/${NEW_USER}/.config/autostart/opensnitch_ui.desktop

# Import configs
# mkdir -p /etc/opensnitchd
# curl -O --output-dir /etc/opensnitchd https://raw.githubusercontent.com/gjpin/arch-linux/main/extra/opensnitch/default-config.json

# Import rules
# mkdir -p /etc/opensnitchd/rules

# RULES=('bitwarden' 'chromium' 'curl' 'discord' 'dockerd' 'firefox' 'flatpak' 'fwupdmgr' 'git-remote-http' 'insomnia' 'networkmanager' 'obsidian' 'pacman' 'paru' 'plasmashell' 'ssh' 'syncthing' 'systemd-timesyncd' 'visual-studio-code' 'wireguard')
# for RULE in "${RULES[@]}"
# do
#     curl -O --output-dir /etc/opensnitchd/rules https://raw.githubusercontent.com/gjpin/arch-linux/main/extra/opensnitch/rules/${RULE}.json
# done

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
    ttf-sourcecodepro-nerd \
    ttf-ubuntu-nerd \
    ttf-ubuntu-mono-nerd \
    inter-font

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