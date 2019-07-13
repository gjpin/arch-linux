#!/bin/bash

echo "Installing common packages"
yes | sudo pacman -S linux-headers dkms xdg-user-dirs xorg-server-xwayland

echo "Installing and configuring UFW"
yes | sudo pacman -S ufw
sudo systemctl enable ufw
sudo systemctl start ufw
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing

echo "Installing common applications"
yes | sudo pacman -S firefox keepassxc git openssh vim links alacritty termite

echo "Installing office applications"
yes | sudo pacman -S ristretto gimp inkscape thunderbird

echo "Installing fonts"
yes | sudo pacman -S ttf-droid ttf-opensans ttf-dejavu ttf-liberation ttf-hack ttf-fira-code

echo "Installing VS Code, NVM and Node.js LTS"
yes | sudo pacman -S code
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
source /usr/share/nvm/init-nvm.sh
nvm install --lts=dubnium

echo "Installing and setting zsh"
yes | sudo pacman -S zsh zsh-theme-powerlevel9k
chsh -s /bin/zsh
wget -P ~/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/configs/zsh/.zshrc
wget -P ~/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/configs/zsh/.zprofile
mkdir -p ~/.zshrc.d
wget -P ~/.zshrc.d https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/configs/zsh/.zshrc.d/environ.zsh
wget -P ~/.zshrc.d https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/configs/zsh/.zshrc.d/wayland.zsh

echo "Setting up GTK theme and installing dependencies"
yes | sudo pacman -S gtk-engine-murrine gtk-engines
git clone https://github.com/vinceliuice/Qogir-theme.git
cd Qogir-theme
sudo mkdir -p /usr/share/themes
sudo ./install.sh -d /usr/share/themes
cd ..
rm -rf Qogir-theme

echo "Setting up icon theme"
git clone https://github.com/vinceliuice/Qogir-icon-theme.git
cd Qogir-icon-theme
sudo mkdir -p /usr/share/icons
sudo ./install.sh -d /usr/share/icons
cd ..
rm -rf Qogir-icon-theme

echo "Installing Material Design icons"
sudo mkdir -p /usr/share/fonts/TTF/
sudo wget -P /usr/share/fonts/TTF/ https://raw.githubusercontent.com/Templarian/MaterialDesign-Webfont/master/fonts/materialdesignicons-webfont.ttf

echo "Installing sway and additional packages"
yes | sudo pacman -S sway swaylock swayidle waybar pulseaudio pavucontrol fish network-manager-applet thunar rofi slurp grim
mkdir -p ~/.config/sway
wget -P ~/.config/sway/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/configs/sway/config

echo "Setting wallpaper"
wget -P ~/Pictures/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/wallpaper/6303-mauritania.jpg

echo "Ricing waybar"
mkdir -p ~/.config/waybar
wget -P ~/.config/waybar https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/configs/waybar/brightness.fish
wget -P ~/.config/waybar https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/configs/waybar/config
wget -P ~/.config/waybar https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/configs/waybar/style.css

echo "Ricing Alacritty"
mkdir -p ~/.config/alacritty
wget -P ~/.config/alacritty https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/configs/alacritty/alacritty.yml