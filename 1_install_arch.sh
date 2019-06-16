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
echo "Creating EFI partition"
printf "n\n1\n4096\n+100M\nef00\nw\ny\n" | gdisk /dev/nvme0n1

echo "Creating boot partition"
printf "n\n2\n\n+512M\n\nw\ny\n" | gdisk /dev/nvme0n1

echo "Creating root partition"
printf "n\n3\n\n\n\nw\ny\n" | gdisk /dev/nvme0n1

echo "Zeroing partitions"
cat /dev/zero > /dev/nvme0n1p1
cat /dev/zero > /dev/nvme0n1p2
cat /dev/zero > /dev/nvme0n1p3

echo "Creating EFI filesystem"
yes | mkfs.vfat -F 32 /dev/nvme0n1p1
yes | mkfs.ext2 /dev/nvme0n1p2

echo "Encrypting root partition"
printf "%s" "$encryption_passphrase" | cryptsetup -c aes-xts-plain64 -h sha512 -s 512 --use-random luksFormat /dev/nvme0n1p3
printf "%s" "$encryption_passphrase" | cryptsetup luksOpen /dev/nvme0n1p3 cryptoVol

echo "Setting up LVM"
pvcreate /dev/mapper/cryptoVol
vgcreate Arch /dev/mapper/cryptoVol
lvcreate -L +"$swap_size"GB Arch -n swap
lvcreate -l +100%FREE Arch -n root

echo "Creating filesystems on encrypted partition"
yes | mkswap /dev/mapper/Arch-swap
yes | mkfs.ext4 /dev/mapper/Arch-root

echo "Mounting new system"
mount /dev/mapper/Arch-root /mnt
swapon /dev/mapper/Arch-swap
mkdir /mnt/boot
mount /dev/nvme0n1p2 /mnt/boot
mkdir /mnt/boot/efi
mount /dev/nvme0n1p1 /mnt/boot/efi

###############################
# Install ArchLinux
###############################
echo "Installing Arch"
yes '' | pacstrap /mnt base base-devel grub-efi-x86_64 efibootmgr dialog wpa_supplicant

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
echo 'LANG="en_US.UTF-8"' >> /etc/locale.conf
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

echo "Installing Grub"
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux

echo "Configuring Grub"
sed -i 's/^GRUB_TIMEOUT.*/GRUB_TIMEOUT=0/' /etc/default/grub
sed -i /GRUB_CMDLINE_LINUX=/c\GRUB_CMDLINE_LINUX=\"cryptdevice=/dev/nvme0n1p3:cryptoVol resume=/dev/mapper/Arch-swap\" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
EOF

echo "ArchLinux is ready. You can reboot now!"