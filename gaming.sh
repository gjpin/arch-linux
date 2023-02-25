#!/bin/bash

################################################
##### MangoHud
################################################

# References:
# https://github.com/flathub/com.valvesoftware.Steam.Utility.MangoHud

# Install MangoHud
flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud/x86_64/22.08

# Configure MangoHud
mkdir -p /home/${NEW_USER}/.config/MangoHud

tee /home/${NEW_USER}/.config/MangoHud/MangoHud.conf << EOF
engine_version
vulkan_driver
EOF

# Allow Flatpaks to access MangoHud configs
flatpak override --filesystem=xdg-config/MangoHud:ro

################################################
##### Platforms
################################################

# Steam
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

# Heroic Games Launcher
flatpak install -y flathub com.heroicgameslauncher.hgl

# Lutris
flatpak install -y flathub net.lutris.Lutris

################################################
##### Emulators
################################################

flatpak install -y flathub org.duckstation.DuckStation # psx
flatpak install -y flathub net.pcsx2.PCSX2 # ps2
flatpak install -y flathub org.ppsspp.PPSSPP # psp
flatpak install -y flathub org.DolphinEmu.dolphin-emu # gamecube / wii
flatpak install -y flathub org.yuzu_emu.yuzu # switch
flatpak install -y flathub org.citra_emu.citra # 3ds
flatpak install -y flathub org.flycast.Flycast # dreamcast
flatpak install -y flathub app.xemu.xemu # xbox
flatpak install -y flathub com.snes9x.Snes9x # snes
flatpak install -y flathub net.kuribo64.melonDS # ds
flatpak install -y flathub net.rpcs3.RPCS3 # ps3