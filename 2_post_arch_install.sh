#!/bin/bash
###############################
# Do NOT run as root
###############################

echo "Installing yay" 
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si
cd ..
rm -rf yay-bin

echo "Installing an setting up theme"
sudo pacman -S gtk-engine-murrine gtk-engines
yay -S qogir-gtk-theme-git

git clone https://github.com/vinceliuice/Qogir-icon-theme.git
cd Qogir-icon-theme
sudo mkdir -p "/usr/share/icons"
sudo ./install.sh -d "/usr/share/icons"
cd ..
rm -rf Qogir-icon-theme

echo "Installing Material Design icons"
yay -S ttf-material-design-icons-git

echo "Installing sway"
sudo pacman -S sway
wget https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/.config/sway/config
mkdir -p ~/.config/sway
mv config ~/.config/sway/

echo "Installing stuff to make sway complete"
sudo pacman -S pulseaudio pavucontrol thunar rofi slurp grim swaylock swayidle waybar
wget https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/wallpaper/6303-mauritania.jpg
mv 6303-mauritania.jpg ~/Pictures/

echo "Installing office stuff"
sudo pacman -S ristretto gimp inkscape thunderbird

echo "Installing dev stuff"
sudo pacman -S code
yay -S nvm
source /usr/share/nvm/init-nvm.sh
nvm install --lts=dubnium

echo "Installing and setting up terminal and zsh"
yes | sudo pacman -S zsh zsh-theme-powerlevel9k
chsh -s /bin/zsh
touch ~/.zshrc
tee -a ~/.zshrc << END
# Load theme
source /usr/share/zsh-theme-powerlevel9k/powerlevel9k.zsh-theme

# Bind keys for navigation
bindkey ";5C" forward-word
bindkey ";5D" backward-word

# Customize prompt
prompt_context() {}

# History support
HISTSIZE=5000               #How many lines of history to keep in memory
HISTFILE=~/.zsh_history     #Where to save history to disk
SAVEHIST=5000               #Number of history entries to save to disk
#HISTDUP=erase               #Erase duplicates in the history file
setopt    appendhistory     #Append history to the history file (no overwriting)
setopt    sharehistory      #Share history across terminals
setopt incappendhistory #Immediately append to the history file, not just when a term is killed
END