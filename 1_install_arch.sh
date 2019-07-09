#!/bin/bash

encryption_passphrase=""
root_password=""
user_password=""
hostname=""
user_name=""
continent_country=""
swap_size="8"

echo "Updating system clock"
timedatectl set-ntp true

###############################
# Setup partitions, LVM, encryption
###############################
echo "Partitioning disk"
echo "Creating partitions"
printf "n\n1\n4096\n+512M\nef00\nw\ny\n" | gdisk /dev/nvme0n1
printf "n\n2\n\n\n8e00\nw\ny\n" | gdisk /dev/nvme0n1

echo "Zeroing partitions"
cat /dev/zero > /dev/nvme0n1p1P
cat /dev/zero > /dev/nvme0n1p2

echo "Creating EFI filesystem"
yes | mkfs.fat -F32 /dev/nvme0n1p1

echo "Encrypting / partition"
printf "%s" "$encryption_passphrase" | cryptsetup -c aes-xts-plain64 -h sha512 -s 512 --use-random --type luks2 luksFormat /dev/nvme0n1p2
printf "%s" "$encryption_passphrase" | cryptsetup luksOpen /dev/nvme0n1p2 cryptoVols

echo "Setting up LVM"
pvcreate /dev/mapper/cryptoVols
vgcreate Arch /dev/mapper/cryptoVols
lvcreate -L +"$swap_size"GB Arch -n swap
lvcreate -l +100%FREE Arch -n root

echo "Creating filesystems on encrypted partition"
yes | mkswap /dev/mapper/Arch-swap
yes | mkfs.ext4 /dev/mapper/Arch-root

echo "Mounting new system"
mount /dev/mapper/Arch-root /mnt
mkdir /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
swapon /dev/mapper/Arch-swap

###############################
# Install ArchLinux
###############################
echo "Installing Arch"
yes '' | pacstrap /mnt base base-devel

echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

###############################
# Configure base system
###############################
echo "Configuring new system"
arch-chroot /mnt /bin/bash <<EOF
echo "Setting system clock"
ln -fs /usr/share/zoneinfo/$continent_country /etc/localtime
hwclock --systohc --localtime

echo "Setting locales"
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
locale-gen

echo "Setting hostname"
echo $hostname > /etc/hostname

echo "Setting root password"
echo -en "$root_password\n$root_password" | passwd

echo "Creating new user"
useradd -m -G wheel -s /bin/bash $user_name
echo -en "$user_password\n$user_password" | passwd $user_name

echo "Generating initramfs"
sed -i 's/^HOOKS.*/HOOKS=(base udev autodetect modconf block keymap encrypt lvm2 resume filesystems keyboard fsck)/' /etc/mkinitcpio.conf
sed -i 's/^MODULES.*/MODULES=(intel_agp i915)/' /etc/mkinitcpio.conf
mkinitcpio -p linux

echo "Installing intel microcode"
yes | pacman -S intel-ucode

echo "Setting up systemd-boot"
bootctl –path=/boot install

mkdir -p "/boot/loader/"
touch /boot/loader/loader.conf
tee -a /boot/loader/loader.conf << END
    default arch
    timeout 0
    editor 0
END

mkdir -p "/boot/loader/entries/"
touch /boot/loader/entries/arch.conf
tee -a /boot/loader/entries/arch.conf << END
    title ArchLinux
    linux /vmlinuz-linux
    initrd /initramfs-linux.img
    initrd /intel-ucode.img
    options cryptdevice=/dev/sda2:cryptoVols root=/dev/mapper/Arch-root resume=/dev/mapper/Arch-swap quiet rw
END

mkdir -p "/etc/pacman.d/hooks/"
touch /etc/pacman.d/hooks/systemd-boot.hook
tee -a /etc/pacman.d/hooks/systemd-boot.hook << END
    [Trigger]
    Type = Package
    Operation = Upgrade
    Target = systemd

    [Action]
    Description = Updating systemd-boot
    When = PostTransaction
    Exec = /usr/bin/bootctl update
END

echo "Enabling periodic TRIM"
systemctl enable fstrim.timer

echo "Installing common packages"
yes | pacman -S linux-headers dkms networkmanager wget

echo "Adding user as a sudoer"
echo '%wheel ALL=(ALL) ALL' | EDITOR='tee -a' visudo

echo "Installing and configuring UFW"
yes | sudo pacman -S ufw
sudo systemctl enable ufw
sudo systemctl start ufw
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing

echo "Enabling NetworkManager"
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

echo "Installing common base"
yes | sudo pacman -S xdg-user-dirs xorg-server-xwayland

echo "Installing fonts"
yes | sudo pacman -S ttf-droid ttf-opensans ttf-dejavu ttf-liberation ttf-hack

echo "Installing common applications"
yes | sudo pacman -S firefox keepassxc git openssh vim alacritty
EOF

umount -R /mnt
swapoff -a

echo "ArchLinux is ready. You can reboot now!"