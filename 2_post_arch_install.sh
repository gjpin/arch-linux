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

echo "Installing common directories"
pacman -S xdg-user-dirs

echo "Installing fonts"
pacman -S ttf-droid ttf-opensans ttf-dejavu ttf-liberation

echo "Adding your user to wheel group"
echo '%wheel ALL=(ALL) ALL' | EDITOR='tee -a' visudo

echo "Installing intel microcode"
pacman -S intel-ucode
grub-mkconfig -o /boot/grub/grub.cfg

echo "Installing common applications"
pacman -S firefox wget keepassxc git openssh

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