#!/bin/bash

encryption_passphrase=""
root_password=""
user_password=""
hostname=""
username=""
continent_city=""
swap_size="16" # same as ram if using hibernation, otherwise minimum of 8

# Set different microcode, kernel params and initramfs modules according to CPU vendor
cpu_vendor=$(cat /proc/cpuinfo | grep vendor | uniq)
cpu_microcode=""
kernel_options=""
initramfs_modules=""
if [[ $cpu_vendor =~ "AuthenticAMD" ]]
then
 cpu_microcode="amd-ucode"
 initramfs_modules="amdgpu"
elif [[ $cpu_vendor =~ "GenuineIntel" ]]
then
 cpu_microcode="intel-ucode"
 kernel_options=" i915.fastboot=1 i915.enable_fbc=1 i915.enable_guc=2"
 initramfs_modules="intel_agp i915"
fi

echo "Updating system clock"
timedatectl set-ntp true

echo "Syncing packages database"
pacman -Sy --noconfirm

echo "Wiping drive"
sgdisk --zap-all /dev/vda

echo "Creating partitions"
printf "n\n1\n4096\n+512M\nef00\nw\ny\n" | gdisk /dev/vda
printf "n\n2\n\n\n8e00\nw\ny\n" | gdisk /dev/vda

echo "Setting up cryptographic volume"
printf "%s" "$encryption_passphrase" | cryptsetup -h sha512 -s 512 --use-random --type luks2 luksFormat /dev/vda2
printf "%s" "$encryption_passphrase" | cryptsetup luksOpen /dev/vda2 cryptroot

echo "Formatting the partitions"
mkfs.fat -F32 -n LINUXEFI /dev/vda1
mkfs.btrfs -L Arch /dev/mapper/cryptroot

echo "Setting up BTRFS"
mount -o compress=zstd,noatime /dev/mapper/cryptroot /mnt
btrfs subvol create /mnt/@
btrfs subvol create /mnt/@home
btrfs subvol create /mnt/@swap

mkdir /mnt/snapshots
btrfs subvol create /mnt/snapshots/@
btrfs subvol create /mnt/snapshots/@home

umount /mnt
mkdir -p /mnt/{boot,home,.snapshots}
mount -o compress=zstd,noatime,subvol=@ /dev/mapper/cryptroot /mnt
mount -o compress=zstd,noatime,subvol=@home /dev/mapper/cryptroot /mnt/home
mount -o compress=zstd,noatime,subvol=/snapshots/@ /dev/mapper/cryptroot /mnt/.snapshots/root
mount -o compress=zstd,noatime,subvol=/snapshots/@home /dev/mapper/cryptroot /mnt/.snapshots/home
mount /dev/vda1 /mnt/boot

echo "Installing Arch Linux"
yes '' | pacstrap /mnt base base-devel linux linux-headers linux-lts linux-lts-headers linux-firmware efibootmgr btrfs-progs dosfstools e2fsprogs lvm2 device-mapper $cpu_microcode cryptsetup networkmanager wget man-db man-pages nano diffutils flatpak lm_sensors

echo "Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

echo "Configuring new system"
arch-chroot /mnt /bin/bash << EOF
echo "Setting system clock"
timedatectl set-ntp true
timedatectl set-timezone $continent_city
hwclock --systohc --localtime

echo "Setting locales"
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
locale-gen

echo "Adding persistent keymap"
echo "KEYMAP=us" > /etc/vconsole.conf

echo "Setting hostname"
echo $hostname > /etc/hostname

echo "Setting root password"
echo -en "$root_password\n$root_password" | passwd

echo "Creating new user"
useradd -m -G wheel,video -s /bin/bash $username
echo -en "$user_password\n$user_password" | passwd $username

echo "Generating initramfs"
sed -i 's/^HOOKS.*/HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt fsck)/' /etc/mkinitcpio.conf
sed -i 's/^MODULES.*/MODULES=(btrfs $initramfs_modules)/' /etc/mkinitcpio.conf
sed -i 's/#COMPRESSION="lz4"/COMPRESSION="lz4"/g' /etc/mkinitcpio.conf
mkinitcpio -P

echo "Setting up systemd-boot"
bootctl --path=/boot install

mkdir -p /boot/loader/
tee -a /boot/loader/loader.conf << END
default arch.conf
timeout 3
END

mkdir -p /boot/loader/entries/
touch /boot/loader/entries/arch.conf
tee -a /boot/loader/entries/arch.conf << END
title Arch Linux
linux /vmlinuz-linux
initrd /$cpu_microcode.img
initrd /initramfs-linux.img
options rd.luks.name=$(blkid -s UUID -o value /dev/vda2)=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rd.luks.options=discard$kernel_options nmi_watchdog=0 quiet rw
END

touch /boot/loader/entries/arch-lts.conf
tee -a /boot/loader/entries/arch-lts.conf << END
title Arch Linux LTS
linux /vmlinuz-linux-lts
initrd /$cpu_microcode.img
initrd /initramfs-linux-lts.img
options rd.luks.name=$(blkid -s UUID -o value /dev/vda2)=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rd.luks.options=discard$kernel_options nmi_watchdog=0 quiet rw
END

echo "Setting up Pacman hook for automatic systemd-boot updates"
mkdir -p /etc/pacman.d/hooks/
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

echo "Setting up swap"
echo "Mounting swapfile subvolume"
mkdir /swapspace
mount -o noatime,subvol=@swap /dev/mapper/cryptroot /swapspace

echo "Creating swapfile"
truncate -s 0 /swapspace/swapfile
chattr +C /swapspace/swapfile
btrfs property set /swapspace/swapfile compression none
fallocate -l "$swap_size"G /swapspace/swapfile
mkswap /swapspace/swapfile
chmod 600 /swapspace/swapfile

echo "Activating swapfile"
swapon /swapspace/swapfile

echo "Adding swap entry to fstab"
tee -a /etc/crypttab << END
/dev/mapper/cryptroot /swapspace btrfs rw,noatime,space_cachesubvol=@swap 0 0
/swapspace/swapfile none swap defaults,discard 0 0
END

echo "Setting swappiness to 20"
touch /etc/sysctl.d/99-swappiness.conf
echo 'vm.swappiness=20' > /etc/sysctl.d/99-swappiness.conf

echo "Enabling periodic TRIM"
systemctl enable fstrim.timer

echo "Enabling NetworkManager"
systemctl enable NetworkManager

echo "Adding user as a sudoer"
echo '%wheel ALL=(ALL) ALL' | EDITOR='tee -a' visudo
EOF

umount -R /mnt
swapoff -a

echo "Arch Linux is ready. You can reboot now!"