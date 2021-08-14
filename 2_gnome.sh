#!/bin/bash

echo "Downloading and running base script"
wget https://raw.githubusercontent.com/gjpin/arch-linux/master/2_base.sh
chmod +x 2_base.sh
sh ./2_base.sh

echo "Installing Gnome and a few extra apps"
sudo pacman -S --noconfirm gnome gnome-tweaks gnome-usage gitg geary gvfs-goa dconf-editor

echo "Enabling automatic login"
sudo tee -a /etc/gdm/custom.conf << EOF
# Enable automatic login for user
[daemon]
AutomaticLogin=$USER
AutomaticLoginEnable=True
EOF

if [[ $(cat /sys/class/dmi/id/chassis_type) -eq 10 ]]
then
echo "Setting misc laptop configurations"
gsettings set org.gnome.desktop.interface show-battery-percentage true
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing false
fi

echo "Setting font sizes"
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Cantarell Bold 10'
gsettings set org.gnome.desktop.interface font-name 'Cantarell 10'
gsettings set org.gnome.desktop.interface document-font-name 'Cantarell 10'
gsettings set org.gnome.desktop.interface monospace-font-name "Cascadia Mono Regular 11"

echo "Setting custom shortcuts"
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>Return'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'gnome-terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Gnome Terminal'
gsettings set org.gnome.desktop.wm.keybindings close ['<Shift><Super>q']
gsettings set org.gnome.settings-daemon.plugins.media-keys area-screenshot-clip ['<Shift><Super>s']

echo "Improving media compatibility"
sudo pacman -S --noconfirm gst-libav

echo "Installing virt-manager"
sudo pacman -S --noconfirm virt-manager dmidecode ebtables dnsmasq
sudo systemctl start libvirtd.service
sudo systemctl enable libvirtd.service

# echo "Enabling Arch repositories in Gnome Software"
# sudo pacman -S --noconfirm gnome-software-packagekit-plugin

echo "Your setup is ready. You can reboot now!"
