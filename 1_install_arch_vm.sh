#!/bin/bash

encryption_passphrase="test"
root_password="test"
user_password="test"
hostname="archVM"
user_name="testuser"
continent_country="Europe/Berlin"
swap_size="1"

echo "Updating system clock"
timedatectl set-ntp true

###############################
# Setup partitions, LVM, encryption
###############################
echo "Partitioning disk"
echo "Creating partitions"
printf "n\n1\n4096\n+512M\nef00\nw\ny\n" | gdisk /dev/sda
printf "n\n2\n\n\n8e00\nw\ny\n" | gdisk /dev/sda

echo "Zeroing partitions"
cat /dev/zero > /dev/sda1
cat /dev/zero > /dev/sda2

echo "Creating EFI filesystem"
yes | mkfs.fat -F32 /dev/sda1

echo "Encrypting / partition"
printf "%s" "$encryption_passphrase" | cryptsetup -c aes-xts-plain64 -h sha512 -s 512 --use-random --type luks2 --label LVMPART luksFormat /dev/sda2
printf "%s" "$encryption_passphrase" | cryptsetup luksOpen /dev/sda2 cryptoVols

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
mount /dev/sda1 /mnt/boot
swapon /dev/mapper/Arch-swap

###############################
# Install ArchLinux
###############################
echo "Installing Arch"
yes '' | pacstrap /mnt base base-devel intel-ucode networkmanager

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
sed -i 's/^HOOKS.*/HOOKS=(base udev keyboard autodetect modconf block keymap encrypt lvm2 resume filesystems fsck)/' /etc/mkinitcpio.conf
sed -i 's/^MODULES.*/MODULES=(ext4 intel_agp i915)/' /etc/mkinitcpio.conf
mkinitcpio -p linux

echo "Setting up systemd-boot"
bootctl --path=/boot install

mkdir -p /boot/loader/
touch /boot/loader/loader.conf
tee -a /boot/loader/loader.conf << END
default arch
timeout 0
editor 0
END

mkdir -p /boot/loader/entries/
touch /boot/loader/entries/arch.conf
tee -a /boot/loader/entries/arch.conf << END
title ArchLinux
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options cryptdevice=LABEL=LVMPART:cryptoVols root=/dev/mapper/Arch-root resume=/dev/mapper/Arch-swap quiet rw
END

mkdir -p /etc/pacman.d/hooks/
touch /etc/pacman.d/hooks/100-systemd-boot.hook
tee -a /etc/pacman.d/hooks/100-systemd-boot.hook << END
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

echo "Enabling NetworkManager"
systemctl enable NetworkManager

echo "Adding user as a sudoer"
echo '%wheel ALL=(ALL) ALL' | EDITOR='tee -a' visudo

echo "Enabling autologin"
mkdir -p  /etc/systemd/system/getty@tty1.service.d/
touch /etc/systemd/system/getty@tty1.service.d/override.conf
tee -a /etc/systemd/system/getty@tty1.service.d/override.conf << END
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $user_name --noclear %I $TERM
END

echo "Installing common packages"
yes | pacman -S linux-headers dkms wget

echo "Installing common base"
yes | pacman -S xdg-user-dirs xorg-server-xwayland

echo "Installing fonts"
yes | pacman -S ttf-droid ttf-opensans ttf-dejavu ttf-liberation ttf-hack

echo "Installing common applications"
yes | pacman -S firefox keepassxc git openssh vim alacritty
EOF

umount -R /mnt
swapoff -a

echo "ArchLinux is ready. You can reboot now!"