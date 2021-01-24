#!/bin/bash

echo "Downloading and running base script"
wget https://raw.githubusercontent.com/exah-io/arch-linux/master/2_base.sh
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
echo "Changing UPower levels"
sudo sed -i 's/PercentageLow=10/PercentageLow=20/g' /etc/UPower/UPower.conf
sudo sed -i 's/PercentageCritical=3/PercentageCritical=10/g' /etc/UPower/UPower.conf
sudo sed -i 's/PercentageAction=2/PercentageAction=5/g' /etc/UPower/UPower.conf
fi

echo "Setting font sizes"
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Cantarell Bold 10'
gsettings set org.gnome.desktop.interface font-name 'Cantarell 10'
gsettings set org.gnome.desktop.interface document-font-name 'Cantarell 10'

echo "Setting custom shortcuts"
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>Return'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'gnome-terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Gnome Terminal'
gsettings set org.gnome.desktop.wm.keybindings close ['<Shift><Super>q']

echo "Improving Plymouth support"
sudo systemctl disable gdm.service
sudo systemctl enable gdm-plymouth.service

# echo "Enabling Arch repositories in Gnome Software"
# sudo pacman -S --noconfirm gnome-software-packagekit-plugin

# echo "Downloading GTK theme"
# git clone https://github.com/ZorinOS/zorin-desktop-themes
# mkdir ~/.themes
# mv ~/zorin-desktop-themes/ZorinGrey-Light/ ~/.themes
# mv ~/zorin-desktop-themes/ZorinGrey-Dark/ ~/.themes
# rm -rf ~/zorin-desktop-themes/

# echo "Changing panel/top bar transparency to 1.00"
# sed -i 's/background-color: rgba(0, 0, 0, 0.5);/background-color: rgba(0, 0, 0, 1.0);/g' ~/.themes/ZorinGrey-Dark/gnome-shell/gnome-shell.css

# echo "Downloading icons"
# git clone https://github.com/ZorinOS/zorin-icon-themes
# mkdir -p ~/.local/share/icons/
# mv ~/zorin-icon-themes/ZorinGrey-Dark/ ~/.local/share/icons/
# mv ~/zorin-icon-themes/ZorinGrey-Light/ ~/.local/share/icons/
# rm -rf ~/zorin-icon-themes/

# echo "Setting themes"
# gsettings set org.gnome.shell enabled-extensions ['user-theme@gnome-shell-extensions.gcampax.github.com']
# gsettings set org.gnome.desktop.interface gtk-theme 'ZorinGrey-Light'
# gsettings set org.gnome.desktop.interface icon-theme 'ZorinGrey-Light'
# gsettings set org.gnome.shell.extensions.user-theme name 'ZorinGrey-Dark'

echo "Your setup is ready. You can reboot now!"
