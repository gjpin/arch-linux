#!/bin/bash

luks_password=""
username=""
user_password=""
hostname=""
timezone=""

read -p "LUKS password: " luks_password
read -p "Username: " username
read -p "User password: " user_password
read -p "Hostname: " hostname
read -p "Timezone (timedatectl list-timezones): " timezone

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
 kernel_options=" i915.enable_fbc=1"
 initramfs_modules="i915"
fi

# Update system clock
timedatectl set-ntp true

# Sync packages database
pacman -Sy --noconfirm

# Wipe drive
sgdisk --zap-all /dev/nvme0n1

# Create partition tables
parted --script --align optimal /dev/nvme0n1 \
    mkpart "EFI system partition" fat32 0% 512MiB \
    set 1 esp on \
    mkpart "root partition" ext4 512MiB 100%

# Eanble full system encryption with dm-crypt + LUKS (except /boot)
echo "$luks_password" | cryptsetup luksFormat /dev/nvme0n1p2
echo "$luks_password" | cryptsetup open /dev/nvme0n1p2 root

mkfs.ext4 /dev/mapper/root
mount /dev/mapper/root /mnt

mount --mkdir /dev/nvme0n1p1 /mnt/boot

# Install Arch Linux
pacstrap /mnt base base-devel efibootmgr linux linux-headers linux-lts linux-lts-headers \
linux-firmware device-mapper dosfstools e2fsprogs $cpu_microcode cryptsetup networkmanager \
wget man-db man-pages nano diffutils flatpak lm_sensors apparmor

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Configure system
arch-chroot /mnt /bin/bash << EOF
# Set system clock
timedatectl set-ntp true
ln -sf /usr/share/zoneinfo/"$timezone" /etc/localtime
hwclock --systohc

# Set locales
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
locale-gen

# Add persistent keymap
echo "KEYMAP=us" > /etc/vconsole.conf

# Set hostname
echo $hostname > /etc/hostname

# Create new user
useradd -m -G wheel -s /bin/bash $username
echo -en "$user_password\n$user_password" | passwd $username

# Generate initramfs
sed -i 's/^HOOKS.*/HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems fsck)/' /etc/mkinitcpio.conf
sed -i 's/^MODULES.*/MODULES=(ext4 $initramfs_modules)/' /etc/mkinitcpio.conf
mkinitcpio -P

# Setup systemd-boot
bootctl --path=/boot install

mkdir -p /boot/loader/
tee -a /boot/loader/loader.conf << END
default arch.conf
timeout 2
console-mode max
editor no
END

mkdir -p /boot/loader/entries/
tee -a /boot/loader/entries/arch.conf << END
title Arch Linux
linux /vmlinuz-linux
initrd /$cpu_microcode.img
initrd /initramfs-linux.img
options rd.luks.name=$(blkid -s UUID -o value /dev/nvme0n1p2)=root root=/dev/mapper/root rd.luks.options=discard$kernel_options nowatchdog lsm=landlock,lockdown,yama,apparmor,bpf quiet rw
END

tee -a /boot/loader/entries/arch-lts.conf << END
title Arch Linux LTS
linux /vmlinuz-linux-lts
initrd /$cpu_microcode.img
initrd /initramfs-linux-lts.img
options rd.luks.name=$(blkid -s UUID -o value /dev/nvme0n1p2)=root root=/dev/mapper/root rd.luks.options=discard$kernel_options nowatchdog lsm=landlock,lockdown,yama,apparmor,bpf quiet rw
END

# Setup Pacman hook for automatic systemd-boot updates
mkdir -p /etc/pacman.d/hooks/
tee -a /etc/pacman.d/hooks/systemd-boot.hook << END
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Updating systemd-boot
When = PostTransaction
Exec = /usr/bin/systemctl restart systemd-boot-update.service
END

# Set swappiness to 20
touch /etc/sysctl.d/99-swappiness.conf
echo 'vm.swappiness=20' > /etc/sysctl.d/99-swappiness.conf

# Enable periodic TRIM
systemctl enable fstrim.timer

# Enable NetworkManager service
systemctl enable NetworkManager.service

# Enable Apparmor service
systemctl enable apparmor.service

# Add user as a sudoer
echo '%wheel ALL=(ALL) ALL' | EDITOR='tee -a' visudo
EOF

umount -R /mnt
swapoff -a

echo "Arch Linux is ready. You can reboot now!"
