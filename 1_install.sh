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
 kernel_options=" i915.enable_fbc=1 i915.enable_guc=2"
 initramfs_modules="intel_agp i915"
fi

# Update system clock
timedatectl set-ntp true

# Sync packages database
pacman -Sy --noconfirm

# Wipe drive
sgdisk --zap-all /dev/nvme0n1

# Create partition tables
printf "n\n1\n4096\n+512M\nef00\nw\ny\n" | gdisk /dev/nvme0n1
printf "n\n2\n\n\n8e00\nw\ny\n" | gdisk /dev/nvme0n1

# Setup cryptographic volume
mkdir -p -m0700 /run/cryptsetup
echo "$encryption_passphrase" | cryptsetup -q --align-payload=8192 -h sha512 -s 512 --use-random --type luks2 -c aes-xts-plain64 luksFormat /dev/nvme0n1p2
echo "$encryption_passphrase" | cryptsetup luksOpen /dev/nvme0n1p2 cryptlvm

# Create physical volume
pvcreate /dev/mapper/cryptlvm

# Create volume
vgcreate vg0 /dev/mapper/cryptlvm

# Create logical volumes
lvcreate -L +"$swap_size"GB vg0 -n swap
lvcreate -l +100%FREE vg0 -n root

# Setup / partition
yes | mkfs.ext4 /dev/vg0/root
mount /dev/vg0/root /mnt

# Setup /boot partition
yes | mkfs.fat -F32 /dev/nvme0n1p1
mkdir /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot

# Setup swap
yes | mkswap /dev/vg0/swap
swapon /dev/vg0/swap

# Install Arch Linux
yes '' | pacstrap /mnt base base-devel efibootmgr linux linux-headers linux-lts linux-lts-headers \
linux-firmware lvm2 device-mapper dosfstools e2fsprogs $cpu_microcode cryptsetup networkmanager\
wget man-db man-pages nano diffutils flatpak lm_sensors apparmor

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Configure system
arch-chroot /mnt /bin/bash << EOF
# Set system clock
timedatectl set-ntp true
timedatectl set-timezone $continent_city
hwclock --systohc --localtime

# Set locales
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
locale-gen

# Add persistent keymap
echo "KEYMAP=us" > /etc/vconsole.conf

# Set hostname
echo $hostname > /etc/hostname

# Set root password
echo -en "$root_password\n$root_password" | passwd

# Create new user
useradd -m -G wheel,video -s /bin/bash $username
echo -en "$user_password\n$user_password" | passwd $username

# Generate initramfs
sed -i 's/^HOOKS.*/HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
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
options rd.luks.name=$(blkid -s UUID -o value /dev/nvme0n1p2)=cryptlvm root=/dev/vg0/root resume=/dev/vg0/swap rd.luks.options=discard$kernel_options nmi_watchdog=0 quiet rw
lsm=landlock,lockdown,yama,apparmor,bpf
END

tee -a /boot/loader/entries/arch-lts.conf << END
title Arch Linux LTS
linux /vmlinuz-linux-lts
initrd /$cpu_microcode.img
initrd /initramfs-linux-lts.img
options rd.luks.name=$(blkid -s UUID -o value /dev/nvme0n1p2)=cryptlvm root=/dev/vg0/root resume=/dev/vg0/swap rd.luks.options=discard$kernel_options nmi_watchdog=0 quiet rw
lsm=landlock,lockdown,yama,apparmor,bpf
END

# Setup Pacman hook for automatic systemd-boot updates
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
