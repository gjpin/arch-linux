###############################
# Run this script as root
###############################
echo "Installing"
pacman -S linux-headers dkms

reboot

###############################
# Run this script as root
###############################
echo "Enabling NetworkManager"
systemctl enable NetworkManager

echo "Installing common base"
pacman -S xdg-user-dirs xorg-server-xwayland

echo "Installing fonts"
pacman -S ttf-droid ttf-opensans ttf-dejavu ttf-liberation ttf-hack

echo "Installing common applications"
pacman -S firefox wget keepassxc git openssh vim

echo "Installing and setting up terminal and zsh"
pacman -S alacritty zsh zsh-theme-powerlevel9k
chsh -s /bin/zsh
tee -a ~/.zshrc << END
source /usr/share/zsh-theme-powerlevel9k/powerlevel9k.zsh-theme
bindkey ";5C" forward-word
bindkey ";5D" backward-word
prompt_context() {}
END

echo "Adding your user to wheel group"
echo '%wheel ALL=(ALL) ALL' | EDITOR='tee -a' visudo

echo "Installing intel microcode"
pacman -S intel-ucode
grub-mkconfig -o /boot/grub/grub.cfg

echo "Installing yay" 
wget https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz
tar -xvf yay.tar.gz
cd yay
makepkg -si
cd ..

echo "Installing and configuring UFW"
pacman -S ufw
systemctl start ufw
systemctl enable ufw
ufw enable
ufw default deny incoming
ufw default allow outgoing