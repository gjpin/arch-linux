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
##### Sunshine (flatpak)
################################################

# References:
# https://github.com/LizardByte/Sunshine
# https://docs.lizardbyte.dev/projects/sunshine/en/latest/
# https://docs.lizardbyte.dev/projects/sunshine/en/latest/about/setup.html#install
# https://docs.lizardbyte.dev/projects/sunshine/en/latest/about/advanced_usage.html#port
# https://github.com/LizardByte/Sunshine/tree/master/packaging/linux/flatpak
# https://github.com/LizardByte/Sunshine/blob/master/packaging/linux/flatpak/scripts/additional-install.sh
# https://github.com/LizardByte/Sunshine/blob/master/packaging/linux/sunshine.service.in
# https://github.com/LizardByte/Sunshine/blob/master/packaging/linux/flatpak/sunshine_kms.desktop

# Download Sunshine flatpak
curl https://github.com/LizardByte/Sunshine/releases/latest/download/sunshine_x86_64.flatpak -L -O

# Install Sunshine
flatpak install -y sunshine_x86_64.flatpak

# Remove Sunshine flatpak
rm -f sunshine_x86_64.flatpak

# Sunshine udev rules
tee /etc/udev/rules.d/60-sunshine.rules << 'EOF'
KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"
EOF

# Configure systemd service
tee /home/${NEW_USER}/.config/systemd/user/sunshine.service << EOF
[Unit]
Description=Sunshine self-hosted game stream host for Moonlight
StartLimitIntervalSec=500
StartLimitBurst=5
PartOf=graphical-session.target
Wants=xdg-desktop-autostart.target
After=xdg-desktop-autostart.target

[Service]
Environment="PULSE_SERVER=unix:/run/user/$(id -u ${NEW_USER})/pulse/native"
ExecStart=/usr/bin/flatpak run dev.lizardbyte.sunshine
ExecStop=/usr/bin/flatpak kill dev.lizardbyte.sunshine
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=xdg-desktop-autostart.target
EOF

sudo -u ${NEW_USER} systemctl --user enable sunshine

# Create Sunshine shortcut
tee /home/${NEW_USER}/.local/share/applications/sunshine_kms.desktop << EOF
[Desktop Entry]
Name=Sunshine (KMS)
Exec=sudo -i PULSE_SERVER=unix:$(pactl info | awk '/Server String/{print$3}') flatpak run dev.lizardbyte.sunshine
Terminal=true
Type=Application
NoDisplay=true
EOF

# Configure Sunshine
mkdir -p /home/${NEW_USER}/.var/app/dev.lizardbyte.sunshine/config
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sunshine/sunshine.conf -o /home/${NEW_USER}/.var/app/dev.lizardbyte.sunshine/config/sunshine.conf

if [ ${DESKTOP_ENVIRONMENT} = "gnome" ]; then
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sunshine/apps-gnome.json -o /home/${NEW_USER}/.var/app/dev.lizardbyte.sunshine/config/apps.json
elif [ ${DESKTOP_ENVIRONMENT} = "plasma" ]; then
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sunshine/apps-plasma.json -o /home/${NEW_USER}/.var/app/dev.lizardbyte.sunshine/configapps.json
fi

# Allow Sunshine in firewall
firewall-cmd --permanent --zone=block --add-rich-rule='rule family="ipv4" port port="48010" protocol="tcp" accept log prefix="Sunshine - RTSP"'
firewall-cmd --permanent --zone=block --add-rich-rule='rule family="ipv4" port port="47998" protocol="udp" accept log prefix="Sunshine - Video"'
firewall-cmd --permanent --zone=block --add-rich-rule='rule family="ipv4" port port="47999" protocol="udp" accept log prefix="Sunshine - Control"'
firewall-cmd --permanent --zone=block --add-rich-rule='rule family="ipv4" port port="48000" protocol="udp" accept log prefix="Sunshine - Audio"'

################################################
##### ALVR (flatpak)
################################################

# References:
# https://github.com/alvr-org/ALVR/blob/master/alvr/xtask/flatpak/com.valvesoftware.Steam.Utility.alvr.desktop
# https://github.com/alvr-org/ALVR/wiki/Installation-guide#portable-targz
# https://github.com/alvr-org/ALVR/tree/master/alvr/xtask/firewall
# https://github.com/alvr-org/ALVR/wiki/Flatpak

# Download ALVR flatpak
curl https://github.com/alvr-org/ALVR/releases/latest/download/com.valvesoftware.Steam.Utility.alvr.flatpak -L -O

# Install ALVR
flatpak install -y --bundle com.valvesoftware.Steam.Utility.alvr.flatpak

# Remove ALVR flatpak
rm -f com.valvesoftware.Steam.Utility.alvr.flatpak

# Automatic Audio & Microphone setup
curl https://raw.githubusercontent.com/alvr-org/ALVR/master/alvr/xtask/flatpak/audio-flatpak-setup.sh -o /home/${NEW_USER}/.var/app/com.valvesoftware.Steam/audio-flatpak-setup.sh
chmod +x /home/${NEW_USER}/.var/app/com.valvesoftware.Steam/audio-flatpak-setup.sh

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