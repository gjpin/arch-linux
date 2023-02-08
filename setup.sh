#!/bin/bash

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
    rsync

################################################
##### Swap
################################################

# References:
# https://wiki.archlinux.org/title/swap#Swappiness
# https://wiki.archlinux.org/title/Improving_performance#zram_or_zswap
# https://wiki.gentoo.org/wiki/Zram
# https://www.dwarmstrong.org/zram-swap/
# https://www.reddit.com/r/Fedora/comments/mzun99/new_zram_tuning_benchmarks/

# Set page cluster
echo 'vm.page-cluster=0' > /etc/sysctl.d/99-page-cluster.conf

# Set swappiness
echo 'vm.swappiness=100' > /etc/sysctl.d/99-swappiness.conf

# Set dirty background ratio
echo 'vm.dirty_background_ratio=1' > /etc/sysctl.d/99-dirty-background-ratio.conf

# Set dirty ratio
echo 'vm.dirty_ratio=50' > /etc/sysctl.d/99-dirty-ratio.conf

# Set VFS cache pressure
echo 'vm.vfs_cache_pressure=500' > /etc/sysctl.d/99-vfs-cache-pressure.conf

# Configure and enable zram
tee /etc/systemd/system/dev-zram0.service << EOF
[Unit]
Description=Start zram
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/usr/bin/modprobe zram
ExecStart=/usr/bin/sh -c "echo zstd > /sys/block/zram0/comp_algorithm"
ExecStart=/usr/bin/sh -c "echo 8G > /sys/block/zram0/disksize"
ExecStart=/usr/bin/mkswap --label zram0 /dev/zram0
ExecStart=/usr/bin/swapon --priority 100 /dev/zram0

[Install]
WantedBy=multi-user.target
EOF

systemctl enable dev-zram0.service

################################################
##### SSD
################################################

# References:
# https://wiki.archlinux.org/title/Solid_state_drive

# Enable periodic TRIM
systemctl enable fstrim.timer

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
mkdir -p /home/${NEW_USER}/{.ssh,src,.local/share/applications,.local/bin,.local/share/themes}

chown 700 /home/${NEW_USER}/.ssh

tee /home/${NEW_USER}/.zshenv << 'EOF'
# Add $HOME/.local/bin/ to the PATH
export PATH="$HOME/.local/bin/:$PATH"
EOF

# Updater helper
tee -a /home/${NEW_USER}/.zshrc.local << EOF
# Updater helper
update-all() {
    # Update system
    sudo pacman -Syu

    # Update AUR packages
    paru -Syu
    
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

# Install and configure iwd and NetworkManager
pacman -S --noconfirm iwd networkmanager

tee /etc/NetworkManager/conf.d/wifi_backend.conf << EOF
[device]
wifi.backend=iwd
EOF

systemctl enable NetworkManager.service

# Install bind tools
pacman -S --noconfirm bind

# Install nftables
pacman -S --noconfirm iptables-nft

################################################
##### initramfs
################################################

# Configure mkinitcpio
sed -i "s|MODULES=()|MODULES=(btrfs${MKINITCPIO_MODULES})|" /etc/mkinitcpio.conf
sed -i "s|^HOOKS.*|HOOKS=(systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems fsck)|" /etc/mkinitcpio.conf
sed -i "s|#COMPRESSION=\"zstd\"|COMPRESSION=\"zstd\"|" /etc/mkinitcpio.conf

# Re-create initramfs image
mkinitcpio -P

################################################
##### GRUB
################################################

# References:
# https://wiki.archlinux.org/title/GRUB
# https://wiki.archlinux.org/title/Kernel_parameters#GRUB
# https://wiki.archlinux.org/title/GRUB/Tips_and_tricks#Password_protection_of_GRUB_menu
# https://www.gnu.org/software/grub/manual/grub/grub.html
# https://archlinux.org/news/grub-bootloader-upgrade-and-configuration-incompatibilities/
# https://wiki.archlinux.org/title/silent_boot

# Install GRUB packages
pacman -S --noconfirm grub efibootmgr

# Configure GRUB
sed -i "s|^GRUB_DEFAULT=.*|GRUB_DEFAULT=\"2\"|g" /etc/default/grub
sed -i "s|^GRUB_TIMEOUT=.*|GRUB_TIMEOUT=1|g" /etc/default/grub
sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"\"|g" /etc/default/grub
sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"rd.luks.name=$(blkid -s UUID -o value /dev/nvme0n1p2)=cryptdev nmi_watchdog=0 rw quiet splash\"|g" /etc/default/grub
sed -i "s|^GRUB_PRELOAD_MODULES=.*|GRUB_PRELOAD_MODULES=\"part_gpt part_msdos luks2\"|g" /etc/default/grub
sed -i "s|^GRUB_TIMEOUT_STYLE=.*|GRUB_TIMEOUT_STYLE=hidden|g" /etc/default/grub
sed -i "s|^#GRUB_ENABLE_CRYPTODISK=.*|GRUB_ENABLE_CRYPTODISK=y|g" /etc/default/grub
sed -i "s|^#GRUB_DISABLE_SUBMENU=.*|GRUB_DISABLE_SUBMENU=y|g" /etc/default/grub

# Install GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --boot-directory=/boot --bootloader-id=GRUB

# Password protect GRUB editing, but make menu unrestricted
GRUB_PASSWORD_HASH=$(echo -e "${LUKS_PASSWORD}\n${LUKS_PASSWORD}" | LC_ALL=C /usr/bin/grub-mkpasswd-pbkdf2 | awk '/hash of / {print $NF}')

chmod o-r /etc/grub.d/40_custom

tee -a /etc/grub.d/40_custom << EOF

# Password protect GRUB menu
set superusers="${NEW_USER}"
password_pbkdf2 ${NEW_USER} ${GRUB_PASSWORD_HASH}
EOF

sed -i "s|CLASS=\"--class gnu-linux --class gnu --class os.*\"|CLASS=\"--class gnu-linux --class gnu --class os --unrestricted\"|g" /etc/grub.d/10_linux

# Do not display 'Loading ...' messages
sed -i '/Loading initial ramdisk/d' /etc/grub.d/10_linux
sed -i '/Loading Linux/d' /etc/grub.d/10_linux

# Reduce boot verbosity (silent boot)
sed -i "s|quiet|& loglevel=3 systemd.show_status=auto rd.udev.log_level=3 vt.global_cursor_default=0|" /etc/default/grub

# Generate GRUB's configuration file
grub-mkconfig -o /boot/grub/grub.cfg

# GRUB upgrade hooks
mkdir -p /etc/pacman.d/hooks

tee /etc/pacman.d/hooks/90-grub-unrestricted.hook << EOF
[Trigger]
Type = Package
Operation = Upgrade
Target = grub

[Action]
Description = Adding --unrestricted to GRUB...
When = PostTransaction
Exec = /usr/bin/sed -i "s|CLASS=\"--class gnu-linux --class gnu --class os.*\"|CLASS=\"--class gnu-linux --class gnu --class os --unrestricted\"|g" /etc/grub.d/10_linux
EOF

tee /etc/pacman.d/hooks/91-grub-hide-messages.hook << EOF
[Trigger]
Type = Package
Operation = Upgrade
Target = grub

[Action]
Description = Hiding GRUB boot messages...
When = PostTransaction
Exec = /usr/bin/sh -c "sed -i '/Loading initial ramdisk/d' /etc/grub.d/10_linux; sed -i '/Loading Linux/d' /etc/grub.d/10_linux"
EOF

tee /etc/pacman.d/hooks/92-grub-upgrade.hook << EOF
[Trigger]
Type = Package
Operation = Upgrade
Target = grub

[Action]
Description = Upgrading GRUB...
When = PostTransaction
Exec = /usr/bin/sh -c "grub-install --target=x86_64-efi --efi-directory=/boot --boot-directory=/boot --bootloader-id=GRUB; grub-mkconfig -o /boot/grub/grub.cfg"
EOF

################################################
##### Unlock LUKS with TPM2
################################################

# References:
# https://wiki.archlinux.org/title/Trusted_Platform_Module#systemd-cryptenroll

# Install TPM2-tools
pacman -S --noconfirm tpm2-tools tpm2-tss

# Configure initramfs to unlock the encrypted volume
sed -i "s|=cryptdev|& rd.luks.options=$(blkid -s UUID -o value /dev/nvme0n1p2)=tpm2-device=auto|" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

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
sbctl enroll-keys --yes-this-might-brick-my-machine

# Sign files with secure boot keys
sbctl sign -s /boot/EFI/GRUB/grubx64.efi
sbctl sign -s /boot/grub/x86_64-efi/core.efi
sbctl sign -s /boot/grub/x86_64-efi/grub.efi
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
pacman -S --noconfirm mesa vulkan-icd-loader vulkan-mesa-layers ${GPU_PACKAGES}

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
    wireplumber

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
flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
flatpak update

# Allow read-only access to GTK configs
flatpak override --filesystem=xdg-config/gtk-3.0:ro
flatpak override --filesystem=xdg-config/gtk-4.0:ro

# Global override to deny all applications the permission to access certain directories
flatpak override --nofilesystem='home' --nofilesystem='host' --nofilesystem='xdg-cache' --nofilesystem='xdg-config' --nofilesystem='xdg-data'

################################################
##### Flatpak runtimes
################################################

# Install runtimes
flatpak install -y flathub org.freedesktop.Platform.VAAPI.Intel/x86_64/22.08
flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full/x86_64/22.08
flatpak install -y flathub org.freedesktop.Platform.GStreamer.gstreamer-vaapi/x86_64/22.08
flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/22.08
flatpak install -y flathub-beta org.freedesktop.Platform.GL.mesa-git/x86_64/22.08
flatpak install -y flathub-beta org.freedesktop.Platform.GL32.mesa-git/x86_64/22.08

################################################
##### Flatpak applications
################################################

# Install Spotify
flatpak install -y flathub com.spotify.Client

# Install Bottles
flatpak install -y flathub com.usebottles.bottles
flatpak override --filesystem=xdg-data/applications com.usebottles.bottles

# Install Discord
flatpak install -y flathub com.discordapp.Discord
flatpak override --socket=wayland com.discordapp.Discord
cp /var/lib/flatpak/app/com.discordapp.Discord/current/active/files/share/applications/com.discordapp.Discord.desktop /home/${NEW_USER}/.local/share/applications
sed -i "s|Exec=discord|Exec=flatpak run com.discordapp.Discord --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland|g" /home/${NEW_USER}/.local/share/applications/com.discordapp.Discord.desktop

# Insomnia
flatpak install -y flathub rest.insomnia.Insomnia
flatpak override --socket=wayland rest.insomnia.Insomnia
cp /var/lib/flatpak/app/rest.insomnia.Insomnia/current/active/files/share/applications/rest.insomnia.Insomnia.desktop /home/${NEW_USER}/.local/share/applications
sed -i "s|Exec=/app/bin/insomnia|Exec=flatpak run rest.insomnia.Insomnia --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland|g" /home/${NEW_USER}/.local/share/applications/rest.insomnia.Insomnia.desktop

# LibreOffice
flatpak install -y flathub org.libreoffice.LibreOffice

# Godot
flatpak install -y flathub org.godotengine.Godot

# Blender
flatpak install -y flathub org.blender.Blender
flatpak override --socket=wayland org.blender.Blender

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

# Install Podman, Buildah and dependencies
pacman -S --noconfirm podman fuse-overlayfs slirp4netns netavark buildah

# Enable kernel.unprivileged_userns_clone
echo 'kernel.unprivileged_userns_clone=1' > /etc/sysctl.d/99-rootless-podman.conf

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
tee -a /etc/containers/registries.conf << EOF
# Enable docker.io as unqualified search registry
unqualified-search-registries = ["docker.io"]
EOF

################################################
##### Development (languages, LSP, neovim)
################################################

# NodeJS
pacman -S --noconfirm nodejs npm

# Typescript and LSP
pacman -S --noconfirm typescript typescript-language-server

# Bash LSP
pacman -S --noconfirm bash-language-server

# Go and LSP
pacman -S --noconfirm go go-tools gopls

tee -a /home/${NEW_USER}/.zshenv << 'EOF'

# Go
export GOPATH="$HOME/.go"
export PATH="$GOPATH/bin:$PATH"
EOF

# Python and LSP
pacman -S --noconfirm python python-lsp-server

# .NET
pacman -S --noconfirm \
    dotnet-runtime \
    dotnet-sdk \
    mono-msbuild \
    mono-msbuild-sdkresolver \
    mono \
    aspnet-runtime

tee -a /home/${NEW_USER}/.zshenv << 'EOF'

# .NET
export PATH="$HOME/.dotnet/tools:$PATH"
EOF

# C++
pacman -S --noconfirm \
    clang \
    lld \
    lldb \
    llvm \
    cmake \
    scons \
    gcc

# Neovim
pacman -S --noconfirm neovim

tee -a /home/${NEW_USER}/.zshrc.local << EOF

# Neovim
alias vi=nvim
alias vim=nvim
EOF

tee -a /etc/environment << EOF

# Neovim
EDITOR=nvim
VISUAL=nvim
EOF

################################################
##### Wayland configurations
################################################

# References:
# https://wiki.archlinux.org/title/wayland#Qt
# https://wiki.archlinux.org/title/Wayland#Electron
# https://wiki.archlinux.org/title/wayland#XWayland

# Install XWayland
pacman -S --noconfirm xorg-xwayland

# Run QT applications natively under Wayland
pacman -S --noconfirm qt5-wayland qt6-wayland

tee -a /etc/environment << EOF

# Qt
QT_QPA_PLATFORM="wayland;xcb"
EOF

# Run Electron applications natively under Wayland
tee /home/${NEW_USER}/.config/electron-flags.conf << EOF
--enable-features=WaylandWindowDecorations
--ozone-platform-hint=auto
EOF

ln -s /home/${NEW_USER}/.config/electron-flags.conf /home/${NEW_USER}/.config/electron17-flags.conf
ln -s /home/${NEW_USER}/.config/electron-flags.conf /home/${NEW_USER}/.config/electron18-flags.conf
ln -s /home/${NEW_USER}/.config/electron-flags.conf /home/${NEW_USER}/.config/electron19-flags.conf
ln -s /home/${NEW_USER}/.config/electron-flags.conf /home/${NEW_USER}/.config/electron20-flags.conf
ln -s /home/${NEW_USER}/.config/electron-flags.conf /home/${NEW_USER}/.config/electron21-flags.conf
ln -s /home/${NEW_USER}/.config/electron-flags.conf /home/${NEW_USER}/.config/electron22-flags.conf

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

# Disable watchdog
echo 'kernel.nmi_watchdog=0' > /etc/sysctl.d/99-disable-watchdog.conf

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
tee -a /etc/environment << EOF

# Firefox
MOZ_ENABLE_WAYLAND=1
EOF

# Open Firefox in headless mode and then close it to create profile folder
sudo -u ${NEW_USER} timeout 5 firefox --headless

# Set Firefox profile path
FIREFOX_PROFILE_PATH=$(realpath /home/${NEW_USER}/.mozilla/firefox/*.default-release)

# Import Firefox configs
curl -Ssl https://raw.githubusercontent.com/gjpin/arch-linux/main/firefox.js \
  -o ${FIREFOX_PROFILE_PATH}/user.js

# Create extensisons folder
mkdir -p ${FIREFOX_PROFILE_PATH}/extensions

# Import extensions
curl https://addons.mozilla.org/firefox/downloads/file/4003969/ublock_origin-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/uBlock0@raymondhill.net.xpi
curl https://addons.mozilla.org/firefox/downloads/file/4018008/bitwarden_password_manager-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/{446900e4-71c2-419f-a6a7-df9c091e268b}.xpi
curl https://addons.mozilla.org/firefox/downloads/file/3998783/floccus-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/floccus@handmadeideas.org.xpi
curl https://addons.mozilla.org/firefox/downloads/file/3932862/multi_account_containers-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/@testpilot-containers.xpi

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
##### Applications
################################################

# Install applications
pacman -S --noconfirm \
    bitwarden \
    keepassxc \
    obsidian

# Install Chromium with native Wayland support
pacman -S --noconfirm chromium
tee /home/${NEW_USER}/.config/chromium-flags.conf << EOF
--ozone-platform-hint=auto
EOF

################################################
##### VSCode
################################################

# Install VS Code and dependencies
sudo -u ${NEW_USER} paru -S --noconfirm visual-studio-code-bin

# (Temporary - reverted at cleanup) Install Virtual framebuffer X server. Required to install VSCode extensions without a display server
pacman -S --noconfirm xorg-server-xvfb

# Install VSCode extensions
sudo -u ${NEW_USER} xvfb-run code --install-extension golang.Go
sudo -u ${NEW_USER} xvfb-run code --install-extension ms-python.python
sudo -u ${NEW_USER} xvfb-run code --install-extension ms-dotnettools.csharp
sudo -u ${NEW_USER} xvfb-run code --install-extension llvm-vs-code-extensions.vscode-clangd
sudo -u ${NEW_USER} xvfb-run code --install-extension vadimcn.vscode-lldb

# Import VSCode settings
mkdir -p "/home/${NEW_USER}/.config/Code/User"
tee "/home/${NEW_USER}/.config/Code/User/settings.json" << EOF
{
    "telemetry.telemetryLevel": "off",
    "window.menuBarVisibility": "toggle",
    "workbench.startupEditor": "none",
    "editor.fontFamily": "'Noto Sans Mono', 'Droid Sans Mono', 'monospace', 'Droid Sans Fallback'",
    "editor.fontLigatures": true,
    "workbench.enableExperiments": false,
    "workbench.settings.enableNaturalLanguageSearch": false,
    "workbench.iconTheme": null,
    "workbench.tree.indent": 12,
    "window.titleBarStyle": "native",
    "editor.fontWeight": "500",
    "files.associations": {
      "*.j2": "terraform",
      "*.hcl": "terraform",
      "*.bu": "yaml",
      "*.ign": "json",
      "*.service": "ini"
    },
    "extensions.ignoreRecommendations": true,
    "editor.formatOnSave": true,
    "editor.formatOnPaste": true,
    "git.enableSmartCommit": true,
    "git.confirmSync": false,
    "git.autofetch": true,
}
EOF

# Run VSCode under Wayland
ln -s /home/${NEW_USER}/.config/electron-flags.conf /home/${NEW_USER}/.config/code-flags.conf

################################################
##### Desktop Environment
################################################

# References:
# https://wiki.archlinux.org/title/Metric-compatible_fonts

# Install fonts
pacman -S --noconfirm noto-fonts noto-fonts-emoji noto-fonts-cjk noto-fonts-extra \
    ttf-liberation otf-cascadia-code ttf-sourcecodepro-nerd

# Install and enable power profiles daemon
pacman -S --noconfirm power-profiles-daemon
systemctl enable power-profiles-daemon.service

# Enable bluetooth
systemctl enable bluetooth.service

# Install and configure desktop environment
if [ ${DESKTOP_ENVIRONMENT} = "plasma" ]; then
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/setup_plasma.sh -O
    chmod +x setup_plasma.sh
    ./setup_plasma.sh
    rm setup_plasma.sh
elif [ ${DESKTOP_ENVIRONMENT} = "gnome" ]; then
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/setup_gnome.sh -O
    chmod +x setup_gnome.sh
    ./setup_gnome.sh
    rm setup_gnome.sh
elif [ ${DESKTOP_ENVIRONMENT} = "sway" ]; then
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/setup_sway.sh -O
    chmod +x setup_sway.sh
    ./setup_sway.sh
    rm setup_sway.sh
fi

# Hide applications from menus
APPLICATIONS=('assistant' 'avahi-discover' 'designer' 'electron19' 'htop' 'linguist' 'lstopo' 'nvim' 'org.kde.kuserfeedback-console' 'qdbusviewer' 'qt5ct' 'qv4l2' 'qvidcap' 'bssh' 'bvnc' 'libreoffice-xsltfilter' 'libreoffice-startcenter' 'mpv')
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
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/setup_gaming.sh -O
    chmod +x setup_gaming.sh
    ./setup_gaming.sh
    rm setup_gaming.sh
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

################################################
##### BTRFS snapshots
################################################

# References:
# https://wiki.archlinux.org/title/snapper
# https://www.dwarmstrong.org/btrfs-snapshots-rollbacks/
# https://wiki.archlinux.org/title/System_backup#Snapshots_and_/boot_partition
# https://stackoverflow.com/questions/20300971/rsync-copy-directory-contents-but-not-directory-itself

# Install Snapper, Pacman hooks for snapshots and GRUB snapshots boot options 
pacman -S --noconfirm snapper snap-pac grub-btrfs

# Unmount .snapshots
umount /.snapshots
rm -rf /.snapshots

# Create Snapper config
snapper --no-dbus -c root create-config /

# Delete Snapper's .snapshots subvolume
btrfs subvolume delete /.snapshots

# Re-create and re-mount /.snapshots mount
mkdir /.snapshots
mount -a

# Set permissions for .snapshots
chmod 700 /.snapshots

# Configure Snapper
sed -i "s|^ALLOW_USERS=.*|ALLOW_USERS=\"${NEW_USER}\"|g" /etc/snapper/configs/root
sed -i "s|^TIMELINE_MIN_AGE=.*|TIMELINE_MIN_AGE=\"1800\"|g" /etc/snapper/configs/root
sed -i "s|^TIMELINE_LIMIT_HOURLY=.*|TIMELINE_LIMIT_HOURLY=\"5\"|g" /etc/snapper/configs/root
sed -i "s|^TIMELINE_LIMIT_DAILY=.*|TIMELINE_LIMIT_DAILY=\"7\"|g" /etc/snapper/configs/root
sed -i "s|^TIMELINE_LIMIT_WEEKLY=.*|TIMELINE_LIMIT_WEEKLY=\"0\"|g" /etc/snapper/configs/root
sed -i "s|^TIMELINE_LIMIT_MONTHLY=.*|TIMELINE_LIMIT_MONTHLY=\"0\"|g" /etc/snapper/configs/root
sed -i "s|^TIMELINE_LIMIT_YEARLY=.*|TIMELINE_LIMIT_YEARLY=\"0\"|g" /etc/snapper/configs/root

# Enable Snapper services
systemctl enable snapper-timeline.timer
systemctl enable snapper-cleanup.timer

# Configure GRUB-BTRFS
sed -i "s|^#GRUB_BTRFS_GRUB_DIRNAME=.*|GRUB_BTRFS_GRUB_DIRNAME=\"/boot/grub\"|g" /etc/default/grub-btrfs/config

# Enable GRUB-BTRFS service
systemctl enable grub-btrfs.path

# Configure initramfs to boot into snapshots using overlayfs (read-only mode)
sed -i "s|fsck)|fsck grub-btrfs-overlayfs)|g" /etc/mkinitcpio.conf
mkinitcpio -P

# Create rollback helper
ZSHRC_LOCAL_PATHS=("/home/${NEW_USER}" "/root")
for ZSHRC_LOCAL_PATH in "${ZSHRC_LOCAL_PATHS[@]}"
do
tee -a ${ZSHRC_LOCAL_PATH}/.zshrc.local << 'EOF'

# Rollback helper
function rollback-helper {
    echo "How to rollback to another snapshot:
    
    1. Boot to a working snapshot
    2. (sudo su)
    3. mount /dev/mapper/cryptdev /mnt
    4. mount --mkdir /dev/nvme0n1p1 /mnt/boot
    5. mv /mnt/@ /mnt/@.broken
       or
       btrfs subvolume delete /mnt/@
    6. grep -r '<date>' /mnt/@snapshots/*/info.xml
    7. btrfs subvolume snapshot /mnt/@snapshots/${NUMBER}/snapshot /mnt/@
    8. cp -R /mnt/@snapshots/${NUMBER}/snapshot/.bootbackup/* /mnt/boot
    9. umount /mnt
    10. reboot -f"
}
EOF
done

# Automatically backup /boot partition to BTRFS partition on kernel updates
mkdir -p /.bootbackup

tee /etc/pacman.d/hooks/99-boot-backup.hook << EOF
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Path
Target = usr/lib/modules/*/vmlinuz

[Action]
Depends = rsync
Description = Backing up /boot...
When = PostTransaction
Exec = /usr/bin/rsync -a --delete /boot/ /.bootbackup
EOF