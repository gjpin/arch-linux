#!/usr/bin/bash

################################################
##### 32-bit support
################################################

# Enable multilib repository
sed -i '/#\[multilib\]/{N;s/#\[multilib\]\n#Include = \/etc\/pacman.d\/mirrorlist/\[multilib\]\nInclude = \/etc\/pacman.d\/mirrorlist/}' /etc/pacman.conf

# Install 32-bit packages
pacman -S --noconfirm lib32-mesa lib32-vulkan-icd-loader lib32-vulkan-mesa-layers

if lspci | grep "VGA" | grep "Intel" > /dev/null; then
    pacman -S --noconfirm lib32-vulkan-intel
elif lspci | grep "VGA" | grep "AMD" > /dev/null; then
    pacman -S --noconfirm lib32-vulkan-radeon lib32-libva
fi

################################################
##### Utilities
################################################

# Install Gamescope
pacman -S --noconfirm gamescope

# Install MangoHud
pacman -S --noconfirm mangohud lib32-mangohud

# Configure MangoHud
mkdir -p /home/${NEW_USER}/.config/MangoHud
curl -sSL https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/mangohud/MangoHud.conf -o /home/${NEW_USER}/.config/MangoHud/MangoHud.conf

################################################
##### Steam
################################################

# Install Steam
pacman -S --noconfirm steam

# Make sure correct driver is installed
if pacman -Qs lib32-amdvlk > /dev/null; then
    pacman -S --noconfirm lib32-vulkan-radeon
    pacman -Rs --noconfirm lib32-amdvlk
fi