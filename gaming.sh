#!/usr/bin/bash

################################################
##### Utilities
################################################

# Install MangoHud
flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud//23.08

# Install Gamescope
flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.gamescope//23.08

# Install Gamemode
pacman -S --noconfirm gamemode lib32-gamemode

# Install Gamescope
pacman -S --noconfirm gamescope

# Install MangoHud
pacman -S --noconfirm mangohud lib32-mangohud

# Configure MangoHud
# https://wiki.archlinux.org/title/MangoHud
mkdir -p /home/${NEW_USER}/.config/MangoHud

tee /home/${NEW_USER}/.config/MangoHud/MangoHud.conf << EOF
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
engine_version
vulkan_driver
EOF

################################################
##### Steam (native)
################################################

# Install Steam
pacman -S --noconfirm steam
pacman -Rs --noconfirm lib32-amdvlk

# Steam controllers udev rules
curl -sSL https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-input.rules -o /etc/udev/rules.d/60-steam-input.rules
udevadm control --reload-rules

################################################
##### Heroic Games Launcher (Flatpak)
################################################

# Install Heroic Games Launcher
flatpak install -y flathub com.heroicgameslauncher.hgl

# Create directory for Heroic games
mkdir -p /home/${NEW_USER}/games/heroic/{epic,gog}

# Import Flatpak overrides
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.heroicgameslauncher.hgl -o /home/${NEW_USER}/.local/share/flatpak/overrides/com.heroicgameslauncher.hgl

# Configure MangoHud for Heroic
mkdir -p /home/${NEW_USER}/.var/app/com.heroicgameslauncher.hgl/config/MangoHud
tee /home/${NEW_USER}/.var/app/com.heroicgameslauncher.hgl/config/MangoHud/MangoHud.conf << EOF
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
engine_version
vulkan_driver
EOF

################################################
##### Sunshine
################################################

# References:
# https://github.com/LizardByte/Sunshine
# https://docs.lizardbyte.dev/projects/sunshine/en/latest/

# Install sunshine
sudo -u ${NEW_USER} paru -S --noconfirm sunshine-bin

# Enable sunshine service
chown -R ${NEW_USER}:${NEW_USER} /home/${NEW_USER}
sudo -u ${NEW_USER} systemctl --user enable sunshine

# Import sunshine configurations
mkdir -p /home/${NEW_USER}/.config/sunshine

curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sunshine/sunshine.conf -o /home/${NEW_USER}/.config/sunshine/sunshine.conf

if [ ${DESKTOP_ENVIRONMENT} = "gnome" ]; then
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sunshine/apps-gnome.json -o /home/${NEW_USER}/.config/sunshine/apps.json
elif [ ${DESKTOP_ENVIRONMENT} = "plasma" ]; then
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sunshine/apps-plasma.json -o /home/${NEW_USER}/.config/sunshine/apps.json
fi

# Enable KMS display capture
setcap cap_sys_admin+p $(readlink -f /usr/bin/sunshine)

################################################
##### ALVR (native)
################################################

# References:
# https://github.com/alvr-org/ALVR/blob/master/alvr/xtask/flatpak/com.valvesoftware.Steam.Utility.alvr.desktop
# https://github.com/alvr-org/ALVR/wiki/Installation-guide#portable-targz

# Download ALVR
curl https://github.com/alvr-org/ALVR/releases/latest/download/alvr_streamer_linux.tar.gz -L -O

# Extract ALVR
tar -xzf alvr_streamer_linux.tar.gz
mv alvr_streamer_linux /home/${NEW_USER}/.alvr

# Cleanup ALVR.tar.gz
rm -f alvr_streamer_linux.tar.gz

# Create ALVR shortcut
tee /home/${NEW_USER}/.local/share/applications/alvr.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=ALVR
GenericName=Game
Comment=ALVR is an open source remote VR display which allows playing SteamVR games on a standalone headset such as Gear VR or Oculus Go/Quest.
Exec=/home/${NEW_USER}/.alvr/bin/alvr_dashboard
Icon=alvr
Categories=Game;
StartupNotify=true
PrefersNonDefaultGPU=true
X-KDE-RunOnDiscreteGpu=true
StartupWMClass=ALVR
EOF

# Allow ALVR in firewall
firewall-cmd --zone=block --add-service=alvr
firewall-cmd --zone=trusted --add-service=alvr

firewall-cmd --permanent --zone=block --add-service=alvr
firewall-cmd --permanent --zone=trusted --add-service=alvr