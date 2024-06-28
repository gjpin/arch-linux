#!/usr/bin/bash

################################################
##### Utilities
################################################

# References:
# https://wiki.archlinux.org/title/MangoHud

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
udevadm trigger
modprobe uinput

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
mkdir -p /home/${NEW_USER}/Games/Heroic/{Epic,GOG}

# Create directory for Heroic Prefixes
mkdir -p /home/${NEW_USER}/Games/Heroic/Prefixes/{Epic,GOG}

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
##### Sunshine (native)
################################################

# References:
# https://github.com/LizardByte/Sunshine
# https://docs.lizardbyte.dev/projects/sunshine/en/latest/
# https://docs.lizardbyte.dev/projects/sunshine/en/latest/about/advanced_usage.html#port

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

# Allow Sunshine in firewall (commented since connection to Sunshine is done via Wireguard, which is a trusted zone)
# firewall-cmd --permanent --zone=block --add-rich-rule='rule family="ipv4" port port="48010" protocol="tcp" accept log prefix="Sunshine - RTSP"'
# firewall-cmd --permanent --zone=block --add-rich-rule='rule family="ipv4" port port="47998" protocol="udp" accept log prefix="Sunshine - Video"'
# firewall-cmd --permanent --zone=block --add-rich-rule='rule family="ipv4" port port="47999" protocol="udp" accept log prefix="Sunshine - Control"'
# firewall-cmd --permanent --zone=block --add-rich-rule='rule family="ipv4" port port="48000" protocol="udp" accept log prefix="Sunshine - Audio"'

################################################
##### ALVR (flatpak)
################################################

# References:
# https://github.com/alvr-org/ALVR/blob/master/alvr/xtask/flatpak/com.valvesoftware.Steam.Utility.alvr.desktop
# https://github.com/alvr-org/ALVR/wiki/Installation-guide#portable-targz
# https://github.com/alvr-org/ALVR/tree/master/alvr/xtask/firewall

# Download ALVR
curl https://github.com/alvr-org/ALVR/releases/latest/download/com.valvesoftware.Steam.Utility.alvr.flatpak -L -O

# Install ALVR
flatpak install -y --bundle com.valvesoftware.Steam.Utility.alvr.flatpak

# Remove ALVR flatpak
rm -f com.valvesoftware.Steam.Utility.alvr.flatpak

# Create ALVR shortcut
tee /home/${NEW_USER}/.local/share/applications/alvr.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=ALVR
GenericName=Game
Comment=ALVR is an open source remote VR display which allows playing SteamVR games on a standalone headset such as Gear VR or Oculus Go/Quest.
Exec=/usr/bin/flatpak run --command=alvr_dashboard com.valvesoftware.Steam
Icon=alvr
Categories=Game;
StartupNotify=true
PrefersNonDefaultGPU=true
X-KDE-RunOnDiscreteGpu=true
StartupWMClass=ALVR
EOF

# Allow ALVR in firewall
firewall-cmd --permanent --zone=block --add-rich-rule='rule family="ipv4" port port="9943" protocol="udp" accept log prefix="ALVR - discovery"'
firewall-cmd --permanent --zone=block --add-rich-rule='rule family="ipv4" port port="9944" protocol="udp" accept log prefix="ALVR - SteamVR"'
firewall-cmd --permanent --zone=block --add-rich-rule='rule family="ipv4" port port="9943" protocol="tcp" accept log prefix="ALVR - discovery"'
firewall-cmd --permanent --zone=block --add-rich-rule='rule family="ipv4" port port="9944" protocol="tcp" accept log prefix="ALVR - SteamVR"'

# Create ALVR dashboard alias
tee /home/${NEW_USER}/.zshrc.d/alvr << 'EOF'
alias alvr="flatpak run --command=alvr_dashboard com.valvesoftware.Steam"
EOF