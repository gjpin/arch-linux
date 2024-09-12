#!/usr/bin/bash

################################################
##### Utilities
################################################

if [ ${STEAM_VERSION} = "native" ]; then
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
fi

# Create directory for Steam games
mkdir -p /home/${NEW_USER}/Games/Steam

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
firewall-offline-cmd --zone=home --add-port=48010/tcp --permanent
firewall-offline-cmd --zone=home --add-port=48010/udp --permanent
firewall-offline-cmd --zone=home --add-port=47998/udp --permanent
firewall-offline-cmd --zone=home --add-port=48000/udp --permanent

################################################
##### VR
################################################

# References:
# https://github.com/alvr-org/ALVR/blob/master/alvr/xtask/flatpak/com.valvesoftware.Steam.Utility.alvr.desktop
# https://github.com/alvr-org/ALVR/wiki/Installation-guide#portable-targz
# https://github.com/alvr-org/ALVR/tree/master/alvr/xtask/firewall
# https://github.com/alvr-org/ALVR/wiki/Flatpak
# https://github.com/alvr-org/ALVR/wiki/Installation-guide

# Install OpenXR
pacman -S --noconfirm openxr

if [ ${STEAM_VERSION} = "native" ]; then
    # Install ALVR
    sudo -u ${NEW_USER} paru -S --noconfirm alvr-bin
fi

# Allow ALVR in firewall
firewall-offline-cmd --zone=home --add-port=9943/tcp --permanent
firewall-offline-cmd --zone=home --add-port=9943/udp --permanent
firewall-offline-cmd --zone=home --add-port=9944/tcp --permanent
firewall-offline-cmd --zone=home --add-port=9944/udp --permanent