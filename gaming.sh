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

if [ ${STEAM_VERSION} = "native" ]; then
    # Install Gamemode
    pacman -S --noconfirm gamemode lib32-gamemode

    # Install Gamescope
    pacman -S --noconfirm gamescope

    # Install MangoHud
    pacman -S --noconfirm mangohud lib32-mangohud

    # Configure MangoHud
    mkdir -p /home/${NEW_USER}/.config/MangoHud
    curl -sSL https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/mangohud/MangoHud.conf -o /home/${NEW_USER}/.config/MangoHud/MangoHud.conf
fi

################################################
##### Steam
################################################

if [ ${STEAM_VERSION} = "native" ]; then
    # Install Steam
    pacman -S --noconfirm steam

    # Make sure correct driver is installed
    if pacman -Qs lib32-amdvlk > /dev/null; then
        pacman -S --noconfirm lib32-vulkan-radeon
        pacman -Rs --noconfirm lib32-amdvlk
    fi
elif [ ${STEAM_VERSION} = "flatpak" ]; then
    # Install Steam
    flatpak install -y flathub com.valvesoftware.Steam

    # Import Flatpak overrides
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.valvesoftware.Steam -o /home/${NEW_USER}/.local/share/flatpak/overrides/com.valvesoftware.Steam

    # Configure MangoHud for Steam
    mkdir -p /home/${NEW_USER}/.var/app/com.valvesoftware.Steam/config/MangoHud
    curl -sSL https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/mangohud/MangoHud.conf -o /home/${NEW_USER}/.var/app/com.valvesoftware.Steam/config/MangoHud/MangoHud.conf
fi

# Steam controllers udev rules
curl -sSL https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-input.rules -o /etc/udev/rules.d/60-steam-input.rules

# Create directory for Steam games
mkdir -p /home/${NEW_USER}/Games/Steam

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
curl -sSL https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/mangohud/MangoHud.conf -o /home/${NEW_USER}/.var/app/com.heroicgameslauncher.hgl/config/MangoHud/MangoHud.conf

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

# Allow Sunshine in firewall
firewall-offline-cmd --zone=trusted --add-port=48010/tcp --permanent
firewall-offline-cmd --zone=trusted --add-port=48010/udp --permanent
firewall-offline-cmd --zone=trusted --add-port=47998/udp --permanent
firewall-offline-cmd --zone=trusted --add-port=48000/udp --permanent

################################################
##### ALVR
################################################

# References:
# https://github.com/alvr-org/ALVR/blob/master/alvr/xtask/flatpak/com.valvesoftware.Steam.Utility.alvr.desktop
# https://github.com/alvr-org/ALVR/wiki/Installation-guide#portable-targz
# https://github.com/alvr-org/ALVR/tree/master/alvr/xtask/firewall
# https://github.com/alvr-org/ALVR/wiki/Flatpak
# https://github.com/alvr-org/ALVR/wiki/Installation-guide

if [ ${STEAM_VERSION} = "native" ]; then
    # Install ALVR
    sudo -u ${NEW_USER} paru -S --noconfirm alvr-bin
elif [ ${STEAM_VERSION} = "flatpak" ]; then
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
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/alvr/alvr-flatpak.desktop -o /home/${NEW_USER}/.local/share/applications/alvr.desktop

    # Create ALVR dashboard alias
    echo 'alias alvr="flatpak run --command=alvr_dashboard com.valvesoftware.Steam"' | tee /home/${NEW_USER}/.zshrc.d/alvr
fi

# Allow ALVR in firewall
firewall-offline-cmd --zone=trusted --add-port=9943/tcp --permanent
firewall-offline-cmd --zone=trusted --add-port=9943/udp --permanent
firewall-offline-cmd --zone=trusted --add-port=9944/tcp --permanent
firewall-offline-cmd --zone=trusted --add-port=9944/udp --permanent