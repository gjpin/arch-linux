#!/bin/bash

# Download and run base script
wget https://raw.githubusercontent.com/gjpin/arch-linux/master/2_base.sh
sh ./2_base.sh

# Install Plasma and common applications
sudo pacman -S --noconfirm plasma plasma-wayland-session ark dolphin dolphin-plugins gwenview \
kate kgpg konsole kwalletmanager okular spectacle kscreen kcalc filelight partitionmanager \
krunner kfind plasma-firewall plasma-thunderbolt phonon-qt5-gstreamer

# Install SDDM and SDDM-KCM
sudo pacman -S --noconfirm sddm sddm-kcm
sudo systemctl enable --now sddm

# Disable baloo (file indexer)
balooctl suspend
balooctl disable

# Improve KDE/GTK integration
sudo pacman -S --noconfirm xdg-desktop-portal xdg-desktop-portal-kde breeze-gtk kde-gtk-config

# Installing KDE Connect
sudo pacman -S --noconfirm kdeconnect sshfs

# Setup autologin
sudo mkdir -p /etc/sddm.conf.d/
sudo tee -a /etc/sddm.conf.d/autologin.conf << EOF
[Autologin]
User=$USER
Session=plasmawayland
EOF

# echo "Setting Firefox Breeze theme"
# flatpak override --user --env=GTK_THEME=Breeze org.mozilla.firefox

echo "Your setup is ready. You can reboot now!"