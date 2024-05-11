#!/usr/bin/bash

################################################
##### Utilities
################################################

# Install MangoHud
flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud//23.08

# Install Gamescope
flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.gamescope//23.08

# Install Gamemode
pacman -S --noconfirm gamemode

################################################
##### Steam (Flatpak)
################################################

# Install Steam
flatpak install -y flathub com.valvesoftware.Steam

# Create directory for Steam games
mkdir -p /home/${NEW_USER}/games/steam

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

################################################
##### ALVR
################################################

# References:
# https://github.com/alvr-org/ALVR/wiki/Flatpak

# Install dependencies
flatpak install -y flathub org.freedesktop.Sdk//23.08 \
    org.freedesktop.Sdk.Extension.llvm16//23.08 \
    org.freedesktop.Sdk.Extension.rust-stable//23.08 \
    org.freedesktop.Platform.GL.default//23.08-extra \
    org.freedesktop.Platform.GL32.default//23.08-extra

# Download ALVR
curl https://github.com/alvr-org/ALVR/releases/latest/download/com.valvesoftware.Steam.Utility.alvr.flatpak -L -O

# Install ALVR
sudo -u ${NEW_USER} flatpak --user install -y --bundle com.valvesoftware.Steam.Utility.alvr.flatpak

# Remove ALVR flatpak
rm -f com.valvesoftware.Steam.Utility.alvr.flatpak

# Allow ALVR in firewall
firewall-cmd --zone=block --add-service=alvr
firewall-cmd --zone=trusted --add-service=alvr

firewall-cmd --permanent --zone=block --add-service=alvr
firewall-cmd --permanent --zone=trusted --add-service=alvr

# Create ALVR dashboard alias
tee /home/${NEW_USER}/.zshrc.d/alvr << 'EOF'
alias alvr="flatpak run --command=alvr_dashboard com.valvesoftware.Steam"
EOF