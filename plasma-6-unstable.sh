#!/usr/bin/bash

# Enable kde-unstable repository
sed '/^\[core\]/i \[kde-unstable\]\nInclude = \/etc\/pacman.d\/mirrorlist\n' teste
pacman -Syyu --noconfirm

# Plasma packages
pacman -S --noconfirm \
    bluedevil \
    breeze \
    breeze-gtk \
    drkonqi \
    flatpak-kcm \
    kactivitymanagerd \
    kde-cli-tools \
    kde-gtk-config \
    kdecoration \
    kdeplasma-addons \
    kgamma \
    kglobalacceld \
    kinfocenter \
    kmenuedit \
    kpipewire \
    kscreen \
    kscreenlocker \
    ksshaskpass \
    ksystemstats \
    kwallet-pam \
    kwayland \
    kwayland-integration \
    kwin \
    kwrited \
    layer-shell-qt \
    libkscreen \
    libksysguard \
    libplasma \
    milou \
    ocean-sound-theme \
    plasma-activities \
    plasma-activities-stats \
    plasma-browser-integration \
    plasma-desktop \
    plasma-disks \
    plasma-firewall \
    plasma-integration \
    plasma-nm \
    plasma-pa \
    plasma-systemmonitor \
    plasma-thunderbolt \
    plasma-vault \
    plasma-workspace \
    plasma-workspace-wallpapers \
    plasma5support \
    polkit-kde-agent \
    powerdevil \
    print-manager \
    qqc2-breeze-style \
    sddm-kcm \
    systemsettings \
    wacomtablet \
    xdg-desktop-portal-kde

# Non-Plasma packages (add-ons, extensions, ...)
pacman -S --noconfirm \
    baloo-widgets \
    dolphin-plugins \
    ffmpegthumbs \
    kde-inotify-survey \
    kdeconnect \
    kdegraphics-thumbnailers \
    kdenetwork-filesharing \
    kio-admin \
    kio-extras \
    kio-fuse \
    libappindicator-gtk3 \
    phonon-qt6-vlc

# 3rd-party packages
pacman -S --noconfirm \
    iio-sensor-proxy \
    xdg-desktop-portal-gtk \
    xsettingsd

# KDE applications
pacman -S --noconfirm \
    ark \
    dolphin \
    gwenview \
    kate \
    kcalc \
    kcolorchooser \
    konsole \
    kwalletmanager \
    okular \
    partitionmanager \
    plasma-systemmonitor \
    spectacle

# Extra Plasma packages
pacman -S --noconfirm \
    plasma-wayland-session \
    sshfs \
    kfind \
    quota-tools \
    filelight \
    kommit

# Install VLC
pacman -S --noconfirm vlc

# Use KDE file picker in GTK applications
tee -a /etc/environment << EOF

# KDE file picker
GTK_USE_PORTAL=1
EOF

# Disable baloo (file indexer)
sudo -u ${NEW_USER} balooctl suspend
sudo -u ${NEW_USER} balooctl disable
sudo -u ${NEW_USER} balooctl purge

################################################
##### SDDM
################################################

# Install SDDM
pacman -S --noconfirm sddm sddm-kcm

# Enable SDDM service
systemctl enable sddm.service

################################################
##### Konsole
################################################

# Create Konsole configs directory
mkdir -p /home/${NEW_USER}/.local/share/konsole

# Apply Konsole configurations
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/konsole/konsole_breeze_modern_dark.css -o /home/${NEW_USER}/.config/konsole_breeze_modern_dark.css

tee /home/${NEW_USER}/.config/konsolerc << EOF
MenuBar=Disabled

[Desktop Entry]
DefaultProfile=custom.profile

[KonsoleWindow]
RememberWindowSize=false

[TabBar]
TabBarUseUserStyleSheet=true
TabBarUserStyleSheetFile=file:///home/${NEW_USER}/.config/konsole_breeze_modern_dark.css
EOF

# Import Konsole custom profile
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/konsole/custom.profile -o /home/${NEW_USER}/.local/share/konsole/custom.profile

# Import Konsole custom color scheme
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/konsole/Breeze_Dark_Modern.profile -o /home/${NEW_USER}/.local/share/konsole/Breeze_Dark_Modern.profile

################################################
##### GTK theming
################################################

# Install GTK themes
flatpak install -y flathub org.gtk.Gtk3theme.Breeze org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark

# Install Gradience
flatpak install -y flathub com.github.GradienceTeam.Gradience

# Import Gradience Flatpak overrides
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.github.GradienceTeam.Gradience -o /home/${NEW_USER}/.local/share/flatpak/overrides/com.github.GradienceTeam.Gradience

# Apply Breeze Dark theme to GTK applications
mkdir -p /home/${NEW_USER}/.config/{gtk-3.0,gtk-4.0}
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/gtk/gtk.css -o /home/${NEW_USER}/.config/gtk-3.0/gtk.css
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/gtk/gtk.css -o /home/${NEW_USER}/.config/gtk-4.0/gtk.css

################################################
##### Firefox
################################################

# KDE specific configurations
tee -a ${FIREFOX_PROFILE_PATH}/user.js << 'EOF'

// KDE integration
// https://wiki.archlinux.org/title/firefox#KDE_integration
user_pref("widget.use-xdg-desktop-portal.mime-handler", 1);
user_pref("widget.use-xdg-desktop-portal.file-picker", 1);
EOF

################################################
##### SSH
################################################

# Use the KDE Wallet to store ssh key passphrases
# https://wiki.archlinux.org/title/KDE_Wallet#Using_the_KDE_Wallet_to_store_ssh_key_passphrases
tee /home/${NEW_USER}/.config/autostart/ssh-add.desktop << EOF
[Desktop Entry]
Exec=ssh-add -q
Name=ssh-add
Type=Application
EOF

tee /home/${NEW_USER}/.config/environment.d/ssh_askpass.conf << EOF
SSH_ASKPASS='/usr/bin/ksshaskpass'
GIT_ASKPASS=ksshaskpass
SSH_ASKPASS=ksshaskpass
SSH_ASKPASS_REQUIRE=prefer
EOF



# packages=$(curl -s https://download.kde.org/unstable/plasma/5.93.0/ | grep -o -P '(?<=<a href=")(.*)(?=-5.93.0.tar.xz.sig"><img)')
# echo "${packages}" | sed -e '/aura-browser\|plank-player\|plasma-bigscreen\|plasma-mobile\|plasma-nano\|plasma-remotecontrollers\|plasma-sdk\|plasma-tests/d'

# bluedevil
# breeze
# breeze-grub # skip
# breeze-gtk
# breeze-plymouth # skip
# discover # skip
# drkonqi
# flatpak-kcm
# kactivitymanagerd
# kde-cli-tools
# kde-gtk-config
# kdecoration
# kdeplasma-addons
# kgamma
# kglobalacceld
# kinfocenter
# kmenuedit
# kpipewire
# kscreen
# kscreenlocker
# ksshaskpass
# ksystemstats
# kwallet-pam
# kwayland
# kwayland-integration
# kwin
# kwrited
# layer-shell-qt
# libkscreen
# libksysguard
# libplasma
# milou
# ocean-sound-theme
# oxygen # skip
# oxygen-sounds # skip
# plasma-activities
# plasma-activities-stats
# plasma-browser-integration
# plasma-desktop
# plasma-disks
# plasma-firewall
# plasma-integration
# plasma-nm
# plasma-pa
# plasma-systemmonitor
# plasma-thunderbolt
# plasma-vault
# plasma-welcome # skip
# plasma-workspace
# plasma-workspace-wallpapers
# plasma5support
# plymouth-kcm # skip
# polkit-kde-agent-1 # polkit-kde-agent
# powerdevil
# print-manager
# qqc2-breeze-style
# sddm-kcm
# systemsettings
# wacomtablet
# xdg-desktop-portal-kde
