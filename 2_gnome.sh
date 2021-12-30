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

echo "Improving media compatibility"
sudo pacman -S --noconfirm gst-libav

echo "Installing virt-manager"
sudo pacman -S --noconfirm virt-manager dmidecode ebtables dnsmasq
sudo systemctl start libvirtd.service
sudo systemctl enable libvirtd.service

# Set fonts
gsettings set org.gnome.desktop.interface document-font-name 'Inter 9'
gsettings set org.gnome.desktop.interface font-name 'Inter 9'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Inter Bold 9'
gsettings set org.gnome.desktop.interface monospace-font-name 'Noto Sans Mono 10'

# Misc changes
gsettings set org.gnome.desktop.calendar show-weekdate true

## Nautilus
gsettings set org.gtk.Settings.FileChooser sort-directories-first true
gsettings set org.gnome.nautilus.preferences click-policy 'single'
gsettings set org.gnome.nautilus.icon-view default-zoom-level 'standard'

## Text editor
dconf write /org/gnome/gedit/preferences/ui/side-panel-visible true
dconf write /org/gnome/gedit/preferences/editor/wrap-mode "'none'"

## Laptop specific
if [[ $(cat /sys/class/dmi/id/chassis_type) -eq 10 ]]
then
    gsettings set org.gnome.desktop.interface show-battery-percentage true
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
    gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing false
fi

## Gnome Terminal padding
tee -a ${HOME}/.config/gtk-3.0/gtk.css << EOF
VteTerminal,
TerminalScreen,
vte-terminal {
    padding: 5px 5px 5px 5px;
    -VteTerminal-inner-border: 5px 5px 5px 5px;
}
EOF

# Shortcuts
## Terminal
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ next-tab '<Primary>Tab'
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ close-tab '<Primary><Shift>w'

## Window management
gsettings set org.gnome.desktop.wm.keybindings close "['<Shift><Super>q']"

## Applications
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>Return'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'gnome-terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'gnome-terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Super>e'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'nautilus'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'nautilus'

## Screenshots
gsettings set org.gnome.settings-daemon.plugins.media-keys area-screenshot-clip "['<Super><Shift>s']"

echo "Your setup is ready. You can reboot now!"
