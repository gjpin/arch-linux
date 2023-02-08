#!/bin/bash

# References:
# https://gitlab.com/freedesktop-sdk/freedesktop-sdk/-/wikis/Mesa-git
# https://github.com/flathub/com.valvesoftware.Steam.Utility.MangoHud

################################################
##### Mesa-git
################################################

# Set default Flatpak GL drivers to mesa-git
flatpak override --env=FLATPAK_GL_DRIVERS=mesa-git

tee -a /etc/environment << EOF

# Flatpak
FLATPAK_GL_DRIVERS=mesa-git
EOF

################################################
##### MangoHud
################################################

# Configure MangoHud
mkdir -p /home/${NEW_USER}/.config/MangoHud

tee /home/${NEW_USER}/.config/MangoHud/MangoHud.conf << EOF
engine_version
vulkan_driver
EOF

# Allow Flatpaks to access MangoHud configs
flatpak override --filesystem=xdg-config/MangoHud:ro

################################################
##### Steam
################################################

# Install Steam
flatpak install -y flathub com.valvesoftware.Steam
flatpak install -y flathub com.valvesoftware.Steam.Utility.gamescope
flatpak install -y flathub com.valvesoftware.Steam.CompatibilityTool.Proton-GE

# Steam controllers udev rules
curl -sSL https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-input.rules -o /etc/udev/rules.d/60-steam-input.rules
udevadm control --reload
udevadm trigger
tee /etc/modules-load.d/uinput.conf << EOF
uinput
EOF

################################################
##### Heroic Games Launcher
################################################

# Install Heroic Games Launcher
flatpak install -y flathub com.heroicgameslauncher.hgl