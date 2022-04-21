#!/bin/bash

# Download and run base script
curl https://raw.githubusercontent.com/gjpin/arch-linux/master/base.sh -o base.sh
chmod +x 2_base.sh
sh ./2_base.sh

# Install Gnome group
# --noconfirm is omitted in order to prevent some packages from being installed
sudo pacman -S gnome --ignore=vino,yelp,orca,simple-scan,gnome-user-docs,gnome-software,gnome-font-viewer,gnome-contacts,gnome-characters,gnome-books,epiphany

# Install extra applications
sudo pacman -S --noconfirm gnome-tweaks gnome-shell-extensions gitg geary dconf-editor gnome-themes-extra

# Install Secrets (Password Safe)
sudo flatpak install -y flathub org.gnome.World.Secrets

# Install Authenticator
sudo flatpak install -y flathub com.belmoussaoui.Authenticator
sudo flatpak override --unshare=network com.belmoussaoui.Authenticator

# Allow Flatpaks to access themes and icons
sudo flatpak override --filesystem=xdg-data/themes:ro
sudo flatpak override --filesystem=xdg-data/icons:ro

# Enable GDM service
sudo systemctl enable gdm.service

# Enable automatic login
sudo tee -a /etc/gdm/custom.conf << EOF
# Enable automatic login for user
[daemon]
AutomaticLogin=${USER}
AutomaticLoginEnable=True
EOF

# Enable Gnome Shell extensions
gsettings set org.gnome.shell disabled-extensions []
gsettings set org.gnome.shell enabled-extensions "['user-theme@gnome-shell-extensions.gcampax.github.com']"

# Set fonts
gsettings set org.gnome.desktop.interface document-font-name 'Inter 9'
gsettings set org.gnome.desktop.interface font-name 'Inter 9'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Inter Bold 9'
gsettings set org.gnome.desktop.interface monospace-font-name 'Noto Sans Mono 10'

# Misc changes
gsettings set org.gnome.desktop.calendar show-weekdate true

## Terminal
dconf write /org/gnome/terminal/legacy/theme-variant "'dark'"
GNOME_TERMINAL_PROFILE=`gsettings get org.gnome.Terminal.ProfilesList default | awk -F \' '{print $2}'`
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ default-size-columns 110
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ palette "['rgb(7,54,66)', 'rgb(220,50,47)', 'rgb(133,153,0)', 'rgb(181,137,0)', 'rgb(38,139,210)', 'rgb(211,54,130)', 'rgb(42,161,152)', 'rgb(238,232,213)', 'rgb(0,43,54)', 'rgb(203,75,22)', 'rgb(88,110,117)', 'rgb(101,123,131)', 'rgb(131,148,150)', 'rgb(108,113,196)', 'rgb(147,161,161)', 'rgb(253,246,227)']"

## Nautilus
gsettings set org.gtk.Settings.FileChooser sort-directories-first true
gsettings set org.gnome.nautilus.preferences click-policy 'single'
gsettings set org.gnome.nautilus.icon-view default-zoom-level 'standard'

## Text editor
dconf write /org/gnome/gedit/preferences/editor/wrap-mode "'none'"
dconf write /org/gnome/gedit/preferences/editor/highlight-current-line false

## Laptop specific
if [[ $(cat /sys/class/dmi/id/chassis_type) -eq 10 ]]
then
    gsettings set org.gnome.desktop.interface show-battery-percentage true
    gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
    gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing false
fi

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

# Install GTK theme
paru -S adw-gtk3-git
gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3

# VSCode - Install GTK titlebar extension
code --install-extension fkrull.gtk-dark-titlebar

echo "Your setup is ready. You can reboot now!"
