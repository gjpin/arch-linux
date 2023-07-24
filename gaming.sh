#!/usr/bin/bash

################################################
##### Gaming
################################################

# References:
# https://wiki.archlinux.org/title/MangoHud

# Install MangoHud
pacman -S --noconfirm mangohud lib32-mangohud

# Configure MangoHud
mkdir -p /home/${NEW_USER}/.config/MangoHud

tee /home/${NEW_USER}/.config/MangoHud/MangoHud.conf << EOF
control=mangohud
legacy_layout=0
horizontal
gpu_stats
cpu_stats
ram
fps
frametime=0
hud_no_margin
table_columns=14
frame_timing=1
EOF

# Install Steam
pacman -S --noconfirm steam
pacman -Rs --noconfirm lib32-amdvlk

# Steam controllers udev rules
curl -sSL https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-input.rules -o /etc/udev/rules.d/60-steam-input.rules
udevadm control --reload-rules

# Install Gamescope
pacman -S --noconfirm gamescope

# Install Heroic Games Launcher
sudo -u ${NEW_USER} paru -S --noconfirm heroic-games-launcher-bin

# ProtonUp-Qt
flatpak install -y flathub net.davidotek.pupgui2