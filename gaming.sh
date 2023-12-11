#!/usr/bin/bash

################################################
##### Utilities
################################################

# Install MangoHud
flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud//23.08

# Install Gamescope
flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.gamescope//23.08

################################################
##### Steam (Flatpak)
################################################

# Install Steam
flatpak install -y flathub com.valvesoftware.Steam

# Create directory for Steam games
mkdir -p /home/${NEW_USER}/Games/Steam

# Import Flatpak overrides
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.valvesoftware.Steam -o /home/${NEW_USER}/.local/share/flatpak/overrides/com.valvesoftware.Steam

# Steam controllers udev rules
curl -sSL https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-input.rules -o /etc/udev/rules.d/60-steam-input.rules
udevadm control --reload-rules

# Configure MangoHud for Steam
mkdir -p /home/${NEW_USER}/.var/app/com.valvesoftware.Steam/config/MangoHud
tee /home/${NEW_USER}/.var/app/com.valvesoftware.Steam/config/MangoHud/MangoHud.conf << EOF
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
##### Heroic Games Launcher (Flatpak)
################################################

# Install Heroic Games Launcher
flatpak install -y flathub com.heroicgameslauncher.hgl

# Create directory for Heroic games
mkdir -p /home/${NEW_USER}/Games/Heroic

# Create Documents folder
mkdir -p /home/${NEW_USER}/Games/Heroic/Prefixes/default/drive_c/users/${NEW_USER}/Documents

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