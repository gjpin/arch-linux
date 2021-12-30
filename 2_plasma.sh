#!/bin/bash

# Download and run base script
wget https://raw.githubusercontent.com/gjpin/arch-linux/master/2_base.sh
sh ./2_base.sh

# Install Plasma group
sudo pacman -S --noconfirm plasma --ignore discover

# Enable SDDM
sudo systemctl enable sddm

# Install other Plasma applications
sudo pacman -S --noconfirm plasma-wayland-session xdg-desktop-portal ark dolphin dolphin-plugins gwenview \
kate kgpg konsole kwalletmanager okular spectacle kscreen kcalc filelight partitionmanager \
krunner kfind plasma-systemmonitor phonon-qt5-gstreamer gst-libav

flatpak install -y flathub org.kde.keysmith

# Install KDE Connect
sudo pacman -S --noconfirm kdeconnect sshfs

# Disable baloo (file indexer)
balooctl suspend
balooctl disable

# Setup autologin
sudo mkdir -p /etc/sddm.conf.d/
sudo tee -a /etc/sddm.conf.d/autologin.conf << EOF
[Autologin]
User=$USER
Session=plasmawayland
EOF

# Set Firefox Breeze theme
# flatpak override --env=GTK_THEME=Breeze org.mozilla.firefox

echo "Your setup is ready. You can reboot now!"