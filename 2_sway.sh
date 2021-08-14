#!/bin/bash

echo "Downloading and running base script"
wget https://raw.githubusercontent.com/gjpin/arch-linux/master/2_base.sh
chmod +x 2_base.sh
sh ./2_base.sh

echo "Downloading wallpaper"
mkdir -p ~/Pictures/wallpapers
wget -P ~/Pictures/wallpapers/ https://raw.githubusercontent.com/gjpin/arch-linux/master/images/wallpapers/Viktor_Forgacs.jpg

echo "Installing sway and additional packages"
sudo pacman -S --noconfirm sway swaylock swayidle waybar rofi light pulseaudio pavucontrol slurp grim ristretto tumbler mousepad

echo "Ricing sway"
mkdir -p ~/.config/sway
wget -P ~/.config/sway/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/sway/config

echo "Ricing waybar"
mkdir -p ~/.config/waybar
wget -P ~/.config/waybar/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/waybar/config
wget -P ~/.config/waybar/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/waybar/style.css

echo "Ricing rofi"
mkdir -p ~/.config/rofi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/config.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/base16-one-light.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/base16-onedark.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/gruvbox-common.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/gruvbox-dark-hard.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/gruvbox-dark-soft.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/gruvbox-dark.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/gruvbox-light-hard.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/gruvbox-light-soft.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/gruvbox-light.rasi

echo "Enabling sway autostart"
touch ~/.bash_profile
tee -a ~/.bash_profile << EOF
# If running from tty1 start sway
if [ "$(tty)" = "/dev/tty1" ]; then
    _JAVA_AWT_WM_NONREPARENTING=1 sway
fi
EOF

echo "Ricing vim"
mkdir -p ~/.vim
wget -P ~/.vim https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/vim/vimrc
mkdir -p ~/.vim/colors
wget -P ~/.vim/colors https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/vim/base16-one-light.vim
wget -P ~/.vim/colors https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/vim/base16-onedark.vim
wget -P ~/.vim/colors https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/vim/gruvbox.vim

echo "Installing and ricing Alacritty terminal"
sudo pacman -S --noconfirm alacritty
mkdir -p ~/.config/alacritty/
wget -P ~/.config/alacritty/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/alacritty/alacritty.yml

echo "Installing thunar with auto-mount and archives creation/deflation support"
sudo pacman -S --noconfirm thunar gvfs thunar-volman thunar-archive-plugin ark file-roller xarchiver

echo "Installing PDF viewer"
sudo pacman -S --noconfirm xreader

echo "Changing GTK and icons themes"
sudo pacman -S --noconfirm lxappearance

mkdir -p ~/.themes
wget -P ~/.themes https://raw.githubusercontent.com/gjpin/arch-linux/master/themes-icons/Orchis-light.tar.xz
tar -xf ~/.themes/Orchis-light.tar.xz -C ~/.themes
rm -f ~/.themes/Orchis-light.tar.xz

mkdir -p ~/.local/share/icons/
wget -P ~/.local/share/icons/ https://raw.githubusercontent.com/gjpin/arch-linux/master/themes-icons/01-Tela.tar.xz
tar -xf ~/.themes/01-Tela.tar.xz -C ~/.local/share/icons/
rm -f ~/.local/share/icons/01-Tela.tar.xz

wget -P ~/.config/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/gtk/.gtkrc-2.0

mkdir -p ~/.config/gtk-3.0/
wget -P ~/.config/gtk-3.0/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/gtk/gtk-3.0/settings.ini

mkdir -p ~/.icons/default/
wget -P ~/.icons/default/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/gtk/index.theme

echo "Enabling suspend and hibernate hotkeys"
sudo sed -i 's/#HandlePowerKey=poweroff/HandlePowerKey=hibernate/g' /etc/systemd/logind.conf
sudo sed -i 's/#HandleLidSwitch=suspend/HandleLidSwitch=suspend/g' /etc/systemd/logind.conf

echo "Blacklisting bluetooth modules"
sudo touch /etc/modprobe.d/nobt.conf
sudo tee -a /etc/modprobe.d/nobt.conf << END
blacklist btusb
blacklist bluetooth
END

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

echo "Installing xwayland"
sudo pacman -S --noconfirm xorg-server-xwayland

echo "Installing Thunderbird Flatpak with Wayland support"
flatpak --assumeyes install flathub org.mozilla.Thunderbird
flatpak override --user --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.Thunderbird

# echo "Setting automatic updates for Flatpak apps"
# mkdir -p ~/.config/systemd/user/
# touch ~/.config/systemd/user/flatpak-update.timer
# tee -a ~/.config/systemd/user/flatpak-update.timer << EOF
# [Unit]
# Description=Flatpak update

# [Timer]
# OnCalendar=7:00
# Persistent=true

# [Install]
# WantedBy=timers.target
# EOF

# touch ~/.config/systemd/user/flatpak-update.service
# tee -a ~/.config/systemd/user/flatpak-update.service << EOF
# [Unit]
# Description=Flatpak update

# [Service]
# Type=oneshot
# ExecStart=/usr/bin/flatpak update -y
# EOF

# systemctl --user enable flatpak-update.timer
# systemctl --user start flatpak-update.timer

echo "Installing wdisplays"
paru -S --noconfirm wdisplays-git

echo "Setting some default applications"
xdg-mime default ristretto.desktop image/jpeg
xdg-mime default ristretto.desktop image/jpg
xdg-mime default ristretto.desktop image/png
xdg-settings set default-web-browser firefox.desktop

echo "Creating screenshots folder"
mkdir -p ~/Pictures/screenshots
