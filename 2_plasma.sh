#!/bin/bash

echo "Downloading and running base script"
wget https://raw.githubusercontent.com/exah-io/arch-linux/master/2_base.sh
chmod +x 2_base.sh
sh ./2_base.sh

echo "Installing Xorg"
sudo pacman -S --noconfirm xorg

echo "Installing Plasma and common applications"
sudo pacman -S --noconfirm plasma ark dolphin dolphin-plugins gwenview kate kgpg konsole kwalletmanager okular spectacle kscreen plasma-browser-integration kcalc filelight partitionmanager krunner kfind

echo "Installing Thunderbird flatpak"
flatpak install --user --assumeyes flathub org.mozilla.Thunderbird

echo "Adding Thunderbolt frontend"
sudo pacman -S --noconfirm plasma-thunderbolt

echo "Improve Discover support"
sudo pacman -S --noconfirm packagekit-qt5

echo "Installing Plasma wayland session"
sudo pacman -S --noconfirm plasma-wayland-session

echo "Installing SDDM and SDDM-KCM"
sudo pacman -S --noconfirm sddm sddm-kcm
sudo systemctl enable sddm

echo "Improving multimedia support"
sudo pacman -S --noconfirm phonon-qt5-vlc

echo "Disabling baloo (file indexer)"
balooctl suspend
balooctl disable

echo "Improving KDE/GTK integration"
sudo pacman -S --noconfirm xdg-desktop-portal xdg-desktop-portal-kde breeze-gtk kde-gtk-config

echo "Installing KDE Connect and opening required firewall ports"
sudo pacman -S --noconfirm kdeconnect sshfs
sudo ufw allow from 192.168.1.0/24 to any port 1714:1764 proto tcp comment "kde connect"
sudo ufw allow from 192.168.1.0/24 to any port 1714:1764 proto udp comment "kde connect"

echo "Setting up autologin"
sudo mkdir -p /etc/sddm.conf.d/
sudo touch /etc/sddm.conf.d/autologin.conf
sudo tee -a /etc/sddm.conf.d/autologin.conf << EOF
[Autologin]
User=$USER
Session=plasmawayland.desktop
EOF

echo "Setting Breeze theme in Firefox Flatpak"
mkdir -p ~/.var/app/org.mozilla.firefox/.mozilla/firefox/config/gtk-3.0
touch ~/.var/app/org.mozilla.firefox/.mozilla/firefox/config/gtk-3.0/settings.ini
tee -a ~/.var/app/org.mozilla.firefox/.mozilla/firefox/config/gtk-3.0/settings.ini << EOF
[Settings]
gtk-application-prefer-dark-theme=false
gtk-button-images=true
gtk-cursor-theme-name=breeze_cursors
gtk-cursor-theme-size=24
gtk-decoration-layout=icon:minimize,maximize,close
gtk-enable-animations=true
gtk-font-name=Noto Sans,  10
gtk-icon-theme-name=breeze
gtk-menu-images=true
gtk-modules=colorreload-gtk-module:window-decorations-gtk-module
gtk-primary-button-warps-slider=false
gtk-theme-name=Breeze
gtk-toolbar-style=3
EOF

echo "Your setup is ready. You can reboot now!"
