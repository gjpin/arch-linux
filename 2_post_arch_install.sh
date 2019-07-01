#!/bin/bash
###############################
# Run this script as root
###############################
echo "Installing"
yes | pacman -S linux-headers dkms

reboot

###############################
# Run this script as root
###############################
echo "Adding user as a sudoer"
echo '%wheel ALL=(ALL) ALL' | EDITOR='tee -a' visudo

echo "Enabling NetworkManager"
systemctl enable NetworkManager

echo "Installing common base"
yes | pacman -S xdg-user-dirs xorg-server-xwayland

echo "Installing fonts"
yes | pacman -S ttf-droid ttf-opensans ttf-dejavu ttf-liberation ttf-hack

echo "Installing common applications"
yes | pacman -S firefox wget keepassxc git openssh vim

ZSH CANNOT BE INSTALLED AS ROOT
ZSH CANNOT BE INSTALLED AS ROOT
ZSH CANNOT BE INSTALLED AS ROOT
ZSH CANNOT BE INSTALLED AS ROOT
echo "Installing and setting up terminal and zsh"
yes | pacman -S alacritty zsh zsh-theme-powerlevel9k
chsh -s /bin/zsh
touch ~/.zshrc
tee -a ~/.zshrc << END
source /usr/share/zsh-theme-powerlevel9k/powerlevel9k.zsh-theme
bindkey ";5C" forward-word
bindkey ";5D" backward-word
prompt_context() {}
HISTSIZE=5000               #How many lines of history to keep in memory
HISTFILE=~/.zsh_history     #Where to save history to disk
SAVEHIST=5000               #Number of history entries to save to disk
#HISTDUP=erase               #Erase duplicates in the history file
setopt    appendhistory     #Append history to the history file (no overwriting)
setopt    sharehistory      #Share history across terminals
setopt incappendhistory #Immediately append to the history file, not just when a term is killed
END

echo "Installing intel microcode"
yes | pacman -S intel-ucode
grub-mkconfig -o /boot/grub/grub.cfg

echo "Installing and configuring UFW"
yes | pacman -S ufw
systemctl start ufw
systemctl enable ufw
ufw enable
ufw default deny incoming
ufw default allow outgoing