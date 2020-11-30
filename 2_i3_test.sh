#!/bin/bash

echo "Downloading and running base script"
wget https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/2_base.sh
chmod +x 2_base.sh
sh ./2_base.sh

echo "Installing i3, dependencies and additional packages"
sudo pacman -S --noconfirm xorg xorg-xinit i3-gaps i3lock xorg-xbacklight feh maim picom rofi pulseaudio network-manager-applet xss-lock

echo "Configuring i3"
mkdir -p ~/.config/i3/
wget -P ~/.config/i3/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/i3/config

echo "Configuring picom"
mkdir -p ~/.config/picom
wget -P ~/.config/picom/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/picom/picom.conf

echo "Ricing rofi"
mkdir -p ~/.config/rofi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/rofi/config.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/rofi/base16-one-light.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/rofi/base16-onedark.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/rofi/gruvbox-common.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/rofi/gruvbox-dark-hard.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/rofi/gruvbox-dark-soft.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/rofi/gruvbox-dark.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/rofi/gruvbox-light-hard.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/rofi/gruvbox-light-soft.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/rofi/gruvbox-light.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/rofi/ayu-light.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/rofi/ayu-dark.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/rofi/ayu-mirage.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/rofi/ayu-light-blue.rasi

echo "Enabling i3 autostart"
sudo tee -a /etc/profile << EOF
if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
 exec startx /usr/bin/i3
fi
EOF

echo "Installing and ricing Alacritty terminal"
sudo pacman -S --noconfirm alacritty
mkdir -p ~/.config/alacritty/
wget -P ~/.config/alacritty/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/alacritty/alacritty.yml

echo "Installing Gnome apps (file manager, pdf viewer, image viewer)"
sudo pacman -S --noconfirm nautilus filemanager-actions file-roller evince eog

echo "Changing GTK and icons themes"
sudo pacman -S --noconfirm lxappearance

mkdir -p ~/.themes
wget -P ~/.themes https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/themes-icons/Orchis-light.tar.xz
tar -xzf ~/.themes/Orchis-light.tar.xz -C ~/.themes
rm -f ~/.themes/Orchis-light.tar.xz

mkdir -p ~/.local/share/icons/
wget -P ~/.local/share/icons/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/themes-icons/01-Tela.tar.xz
tar -xzf ~/.local/share/icons/01-Tela.tar.xz -C ~/.local/share/icons/
rm -f ~/.local/share/icons/01-Tela.tar.xz

wget -P ~/.config/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/gtk/.gtkrc-2.0

mkdir -p ~/.config/gtk-3.0/
wget -P ~/.config/gtk-3.0/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/gtk/gtk-3.0/settings.ini

mkdir -p ~/.icons/default/
wget -P ~/.icons/default/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/gtk/index.theme

echo "Configuring xinit"
wget -P ~/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/.xinitrc


# TODO: set firefox orchis theme
# flatpak location: ~/.var/app/org.mozilla.firefox/.mozilla/firefox/XXXXX-release


echo "Enabling autologin"
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
sudo touch /etc/systemd/system/getty@tty1.service.d/override.conf
sudo tee -a /etc/systemd/system/getty@tty1.service.d/override.conf << END
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --skip-login --nonewline --noissue --autologin $USER --noclear %I $TERM
END

echo "Removing last login message"
touch ~/.hushlogin

echo "Setting some default applications"
xdg-mime default eog.desktop image/jpeg
xdg-mime default eog.desktop image/jpg
xdg-mime default eog.desktop image/png
xdg-settings set default-web-browser firefox.desktop
xdg-mime default nautilus.desktop inode/directory

echo "Creating screenshots folder"
mkdir -p ~/Pictures/screenshots
