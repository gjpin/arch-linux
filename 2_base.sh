#!/bin/bash

# Set environment variables according to GPU vendor (Intel, AMDGPU) 
cpu_vendor=$(cat /proc/cpuinfo | grep vendor | uniq)
gpu_drivers=""
libva_environment_variable=""
vdpau_environment_variable=""
if [[ $cpu_vendor =~ "AuthenticAMD" ]]
then
 gpu_drivers="vulkan-radeon libva-mesa-driver mesa-vdpau"
 libva_environment_variable="export LIBVA_DRIVER_NAME=radeonsi"
 vdpau_environment_variable="export VDPAU_DRIVER=radeonsi"
elif [[ $cpu_vendor =~ "GenuineIntel" ]]
then
 gpu_drivers="vulkan-intel intel-media-driver libvdpau-va-gl"
 libva_environment_variable="export LIBVA_DRIVER_NAME=iHD"
 vdpau_environment_variable="export VDPAU_DRIVER=va_gl"
fi

# Sync repos and update packages
sudo pacman -Syu --noconfirm

# Create user directories
sudo pacman -S --noconfirm xdg-user-dirs
mkdir -p ${HOME}/.local/share/themes ${HOME}/.local/share/icons ${HOME}/.local/share/fonts
mkdir -p ${HOME}/.ssh && chmod 700 ${HOME}/.ssh/
touch ${HOME}/.ssh/config && chmod 600 ${HOME}/.ssh/config
mkdir -p ${HOME}/.config/systemd/user
mkdir -p ${HOME}/.bashrc.d
mkdir -p ${HOME}/src

# bashrc configurations
tee -a ${HOME}/.bashrc << EOF

# User specific environment
if ! [[ "\$PATH" =~ "\$HOME/.local/bin:\$HOME/bin:" ]]
then
    PATH="\$HOME/.local/bin:\$HOME/bin:\$PATH"
fi
export PATH

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
        for rc in ~/.bashrc.d/*; do
                if [ -f "\$rc" ]; then
                        . "\$rc"
                fi
        done
fi

unset rc
EOF

# Install fonts
sudo pacman -S --noconfirm ttf-roboto ttf-roboto-mono ttf-droid ttf-opensans ttf-dejavu \
ttf-liberation ttf-hack noto-fonts ttf-fira-code ttf-fira-mono ttf-font-awesome \
noto-fonts-emoji ttf-hanazono adobe-source-code-pro-fonts ttf-cascadia-code inter-font

# Install and enable firewalld
sudo pacman -S --noconfirm firewalld
sudo systemctl enable --now firewalld.service

# Installing GPU drivers
sudo pacman -S --noconfirm mesa $gpu_drivers vulkan-icd-loader

# Improve hardware video accelaration
sudo pacman -S --noconfirm ffmpeg libva-utils libva-vdpau-driver vdpauinfo gst-libav

# Install common applications
sudo pacman -S --noconfirm vim git openssh upower htop powertop p7zip ripgrep unzip fwupd unrar bash-completion

# Add Flathub repositories
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak remote-add --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
flatpak update --appstream

# Install Firefox Flatpak
sudo flatpak install -y flathub org.mozilla.firefox
sudo flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full/x86_64/21.08
sudo flatpak override --socket=wayland --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.firefox

# Open Firefox in headless mode and then close it to create profile folder
timeout 5 flatpak run org.mozilla.firefox --headless

# Import Firefox user settings
cd ${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox/*-release
tee -a user.js << EOF
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("media.rdd-ffmpeg.enabled", true);
EOF
cd

# Install Flatpak applications
sudo flatpak install -y flathub com.spotify.Client
sudo flatpak install -y flathub org.gimp.GIMP
sudo flatpak install -y flathub org.blender.Blender
sudo flatpak install -y flathub org.videolan.VLC
sudo flatpak install -y flathub org.chromium.Chromium
sudo flatpak install -y flathub com.github.tchx84.Flatseal
sudo flatpak install -y flathub-beta com.google.Chrome
sudo flatpak install -y flathub com.usebottles.bottles
sudo flatpak install -y flathub org.libreoffice.LibreOffice
# sudo flatpak install -y flathub com.valvesoftware.Steam
# sudo flatpak override --filesystem=/mnt/data/games/steam com.valvesoftware.Steam
# sudo flatpak install flathub-beta net.lutris.Lutris//beta
# sudo flatpak install -y flathub org.gnome.Platform.Compat.i386 org.freedesktop.Platform.GL32.default org.freedesktop.Platform.GL.default
# sudo flatpak override --filesystem=/mnt/data/games/lutris net.lutris.Lutris

# Chrome - Enable GPU acceleration
mkdir -p ${HOME}/.var/app/com.google.Chrome/config
tee -a ${HOME}/.var/app/com.google.Chrome/config/chrome-flags.conf << EOF
--ignore-gpu-blacklist
--enable-gpu-rasterization
--enable-zero-copy
--enable-features=VaapiVideoDecoder
--use-vulkan
EOF

# Chromium - Enable GPU acceleration
mkdir -p ${HOME}/.var/app/org.chromium.Chromium/config
tee -a ${HOME}/.var/app/org.chromium.Chromium/config/chromium-flags.conf << EOF
--ignore-gpu-blacklist
--enable-gpu-rasterization
--enable-zero-copy
--enable-features=VaapiVideoDecoder
--use-vulkan
EOF

# Install paru
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
makepkg -si --noconfirm
cd ..
rm -rf paru-bin

# Install and configure Plymouth
paru -S --noconfirm plymouth
sudo sed -i 's/base systemd autodetect/base systemd sd-plymouth autodetect/g' /etc/mkinitcpio.conf
sudo sed -i 's/quiet rw/quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0 rw/g' /boot/loader/entries/arch.conf
sudo sed -i 's/quiet rw/quiet splash loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0 rw/g' /boot/loader/entries/arch-lts.conf
sudo mkinitcpio -p linux
sudo mkinitcpio -p linux-lts
sudo plymouth-set-default-theme -R bgrt

# Install and start thermald
if [[ $cpu_vendor =~ "GenuineIntel" ]]
then
sudo pacman -S --noconfirm thermald
sudo systemctl enable --now thermald.service
fi

# Laptop battery life improvements
## Enable audio power saving features
if [[ $(cat /sys/class/dmi/id/chassis_type) -eq 10 ]]
then
sudo touch /etc/modprobe.d/audio_powersave.conf
sudo tee -a /etc/modprobe.d/audio_powersave.conf << EOF
options snd_hda_intel power_save=1
EOF

## Enable wifi (iwlwifi) power saving features
sudo touch /etc/modprobe.d/iwlwifi.conf
sudo tee -a /etc/modprobe.d/iwlwifi.conf << EOF
options iwlwifi power_save=1
EOF

## Reduce VM writeback time
sudo touch /etc/sysctl.d/dirty.conf
sudo tee -a /etc/sysctl.d/dirty.conf << EOF
vm.dirty_writeback_centisecs = 1500
EOF
fi

# Set environment variables
sudo tee -a /etc/environment << EOF
$libva_environment_variable
$vdpau_environment_variable
EOF

# Enable bluetooth
sudo systemctl enable --now bluetooth.service

# Disable root
passwd --lock root

# Install syncthing and enable service
sudo pacman -S --noconfirm syncthing
sudo systemctl enable --now syncthing@${USER}.service

# Install wireplumber and pipewire
sudo pacman -S --noconfirm pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber
systemctl enable --now --user pipewire.service

# Install VSCode
paru -S --noconfirm visual-studio-code-bin

# VSCode - Import user settings
mkdir -p ${HOME}/.config/Code/User
tee -a ${HOME}/.config/Code/User/settings.json << EOF
{
    "telemetry.telemetryLevel": "off",
    "window.menuBarVisibility": "toggle",
    "workbench.startupEditor": "none",
    "editor.fontFamily": "'Noto Sans Mono', 'Droid Sans Mono', 'monospace', monospace, 'Droid Sans Fallback'",
    "workbench.enableExperiments": false,
    "workbench.settings.enableNaturalLanguageSearch": false,
    "workbench.iconTheme": "material-icon-theme"
}
EOF

# VSCode - install extensions
code --install-extension PKief.material-icon-theme
code --install-extension golang.Go

# Force electron apps to run under wayland
mkdir -p ${HOME}/.config/
tee -a ${HOME}/.config/electron-flags.conf << EOF
--enable-features=UseOzonePlatform
--ozone-platform=wayland
EOF
