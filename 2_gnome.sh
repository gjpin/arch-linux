#!/bin/bash

# Download and run base script
wget https://raw.githubusercontent.com/gjpin/arch-linux/master/2_base.sh
chmod +x 2_base.sh
sh ./2_base.sh

# Install Gnome group
# --noconfirm is omitted in order to prevent some packages from being installed
sudo pacman -S gnome --ignore=vino,yelp,orca,simple-scan,gnome-user-docs,gnome-software,gnome-font-viewer,gnome-contacts,gnome-characters,gnome-books

# Install extra applications
sudo pacman -S --noconfirm gnome-tweaks gnome-shell-extensions gitg geary dconf-editor gnome-themes-extra

# Install Secrets (Password Safe)
flatpak install -y flathub org.gnome.PasswordSafe

# Install Authenticator
flatpak install -y flathub com.belmoussaoui.Authenticator
sudo flatpak override --nodevice=all com.belmoussaoui.Authenticator
sudo flatpak override --unshare=network com.belmoussaoui.Authenticator

# Enable GDM service
sudo systemctl enable gdm.service

echo "Enabling automatic login"
sudo tee -a /etc/gdm/custom.conf << EOF
# Enable automatic login for user
[daemon]
AutomaticLogin=${USER}
AutomaticLoginEnable=True
EOF

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

# Install Firefox and GTK Fluent theme
flatpak run org.mozilla.firefox --headless --new-tab "javascript:top.window.close()"
git clone https://github.com/vinceliuice/Fluent-gtk-theme.git
cd Fluent-gtk-theme
./install.sh -t grey -s standard -i arch -d ${HOME}/.local/share/themes --tweaks noborder solid
cp -r src/firefox/chrome/ ${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox/*-release
cp src/firefox/configuration/user.js ${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox/*-release
cd ..
rm -rf Fluent-gtk-theme

# Install Tela icons
git clone https://github.com/vinceliuice/Tela-icon-theme.git
cd Tela-icon-theme
./install.sh -d ${HOME}/.local/share/icons standard
cd ..
rm -rf Tela-icon-theme

# Set GTK and icon themes
gsettings set org.gnome.desktop.interface gtk-theme 'Fluent-grey-light'
gsettings set org.gnome.desktop.interface icon-theme 'Tela'

# Set Gnome Shell theme
dconf write /org/gnome/shell/extensions/user-theme/name "'Fluent-grey'"

# Add bash aliases
tee -a ${HOME}/.bashrc.d/aliases << EOF
alias dark="gsettings set org.gnome.desktop.interface gtk-theme 'Fluent-grey-dark' && dconf write /org/gnome/shell/extensions/user-theme/name \"'Fluent-grey-dark'\""
alias light="gsettings set org.gnome.desktop.interface gtk-theme 'Fluent-grey-light' && dconf write /org/gnome/shell/extensions/user-theme/name \"'Fluent-grey'\""
EOF

echo "Your setup is ready. You can reboot now!"
