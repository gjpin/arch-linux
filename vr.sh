#!/usr/bin/bash

################################################
##### Custom repo
################################################

# References:
# https://github.com/gjpin/arch-linux-repo

# Add custom repo with VR packages
tee -a /etc/pacman.conf << EOF

[gjpin]
SigLevel = Optional TrustAll
Server = https://gjpin.github.io/arch-linux-repo/repo/
EOF

# Refresh package databases
pacman -Sy

################################################
##### Utilities
################################################

# References:
# https://monado.freedesktop.org/valve-index-setup.html#5-setting-up-opencomposite
# https://aur.archlinux.org/packages/opencomposite-git

# Install OpenXR and OpenVR
pacman -S --noconfirm openxr openvr

# Install Monado, OpenComposite and xrizer
sudo -u ${NEW_USER} paru -S --noconfirm \
    gjpin/xr-hardware-git \
    gjpin/monado-git \
    gjpin/opencomposite-git \
    gjpin/xrizer-git

# Install WlxOverlay-S
sudo -u ${NEW_USER} paru -S --noconfirm gjpin/wlx-overlay-s-git

# Setup OpenVR to use OpenComposite
mkdir -p /home/${NEW_USER}/.config/openvr

curl -sSL https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/openvr/openvrpaths.vrpath.opencomposite | envsubst > /home/${NEW_USER}/.config/openvr/openvrpaths.vrpath.opencomposite
curl -sSL https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/openvr/openvrpaths.vrpath.steam | envsubst > /home/${NEW_USER}/.config/openvr/openvrpaths.vrpath.steam
curl -sSL https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/openvr/openvrpaths.vrpath.xrizer | envsubst > /home/${NEW_USER}/.config/openvr/openvrpaths.vrpath.xrizer

chmod 444 /home/${NEW_USER}/.config/openvr/openvrpaths.vrpath.opencomposite
chmod 444 /home/${NEW_USER}/.config/openvr/openvrpaths.vrpath.steam
chmod 444 /home/${NEW_USER}/.config/openvr/openvrpaths.vrpath.xrizer

ln -sf /home/${NEW_USER}/.config/openvr/openvrpaths.vrpath.opencomposite /home/${NEW_USER}/.config/openvr/openvrpaths.vrpath

################################################
##### WiVRn
################################################

# References:
# https://github.com/WiVRn/WiVRn
# https://github.com/WiVRn/WiVRn/blob/master/docs/steamvr.md
# https://github.com/WiVRn/WiVRn/blob/master/docs/configuration.md
# /usr/share/openxr/1/openxr_wivrn.json

# Install WiVRn
sudo -u ${NEW_USER} paru -S --noconfirm \
    gjpin/wivrn-server \
    gjpin/wivrn-dashboard

# Configure WiVRn
mkdir -p /home/${NEW_USER}/.config/wivrn
curl -sSL https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/wivrn/config.json -o /home/${NEW_USER}/.config/wivrn/config.json

# Enable Avahi service
systemctl enable avahi-daemon.service

# Allow mDNS through firewall
firewall-offline-cmd --zone=home --add-port=5353/udp

# Allow Avahi through firewall
firewall-offline-cmd --zone=home --add-port=9757/tcp
firewall-offline-cmd --zone=home --add-port=9757/udp

################################################
##### ALVR
################################################

# References:
# https://github.com/alvr-org/ALVR/blob/master/alvr/xtask/flatpak/com.valvesoftware.Steam.Utility.alvr.desktop
# https://github.com/alvr-org/ALVR/wiki/Installation-guide#portable-targz
# https://github.com/alvr-org/ALVR/tree/master/alvr/xtask/firewall
# https://github.com/alvr-org/ALVR/wiki/Flatpak
# https://github.com/alvr-org/ALVR/wiki/Installation-guide

# Ensure alvr firewalld service does not exist due to conflict
rm -f /usr/lib/firewalld/services/alvr.xml

# Install ALVR
sudo -u ${NEW_USER} paru -S --noconfirm gjpin/alvr-git

# Configure ALVR
mkdir -p /home/${NEW_USER}/.config/alvr
curl -sSL https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/alvr/session.json -o /home/${NEW_USER}/.config/alvr/session.json

# Allow ALVR through firewall
firewall-offline-cmd --zone=home --add-port=9943/tcp
firewall-offline-cmd --zone=home --add-port=9943/udp
firewall-offline-cmd --zone=home --add-port=9944/tcp
firewall-offline-cmd --zone=home --add-port=9944/udp