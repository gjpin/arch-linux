#!/bin/bash
###############################
# Do NOT run as root
###############################

echo "Installing yay" 
wget https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz
tar -xvf yay.tar.gz
cd yay
yes yes yes | makepkg -si
cd ..

n yes | yay -S qogir-gtk-theme-git





# TODO: Add support to https://github.com/vinceliuice/Qogir-theme
pacman -S gtk-engine-murrine gtk-engines

# TODO: Add support to https://github.com/vinceliuice/Qogir-icon-theme

# TODO: see https://github.com/swaywm/sway/wiki/GTK-3-settings-on-Wayland
exec_always {
    gsettings set $gnome-schema gtk-theme 'Qogir-win-light'
    gsettings set $gnome-schema icon-theme 'Qogir'
    gsettings set $gnome-schema cursor-theme 'Your cursor Theme'
}

