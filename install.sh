#!/bin/bash

# (Variables) User input
LUKS_PASSWORD=""
USERNAME=""
USER_PASSWORD=""
HOSTNAME=""
TIMEZONE=""

read -p "LUKS password: " LUKS_PASSWORD
read -p "Username: " USERNAME
read -p "User password: " USER_PASSWORD
read -p "Hostname: " HOSTNAME
read -p "Timezone (timedatectl list-timezones): " TIMEZONE

# (Variables) CPU vendor
if [[ $(cat /proc/cpuinfo | grep vendor | uniq) =~ "AuthenticAMD" ]]
then
 CPU_MICROCODE="amd-ucode"
 INITRAMFS_MODULES="amdgpu"
elif [[ $(cat /proc/cpuinfo | grep vendor | uniq) =~ "GenuineIntel" ]]
then
 CPU_MICROCODE="intel-ucode"
 INITRAMFS_MODULES="i915"
fi

# (Variables) Swap size
TOTAL_MEM=$(free -g | grep Mem: | awk '{print $2}')
SWAP_SIZE=$(( $TOTAL_MEM + 1 ))

# Update system clock
timedatectl set-ntp true

# Sync packages database
pacman -Sy --noconfirm

# Zero out all GPT data structures
sgdisk --zap-all /dev/nvme0n1

# Create partition tables (sgdisk -L)
sgdisk -og /dev/nvme0n1
sgdisk --new 1:4096:+512M --typecode 1:ef00 --change-name 1:"EFI System Partition" /dev/nvme0n1
sgdisk --new 2:0:+"$SWAP_SIZE"G --typecode 2:8309 --change-name 2:"Swap Partition" /dev/nvme0n1
ENDSECTOR=$(sgdisk -E /dev/nvme0n1)
sgdisk --new 3:0:"$ENDSECTOR" --typecode 3:8309 --change-name 3:"Root Partition" /dev/nvme0n1

# Prepare swap partition: encrypt swap partition and create swap filesystem
echo "$LUKS_PASSWORD" | cryptsetup luksFormat /dev/nvme0n1p2
echo "$LUKS_PASSWORD" | cryptsetup open /dev/nvme0n1p2 swap
mkswap /dev/mapper/swap
swapon /dev/mapper/swap

# Prepare root partition: encrypt root partition and create ext4 filesystem
echo "$LUKS_PASSWORD" | cryptsetup luksFormat /dev/nvme0n1p3
echo "$LUKS_PASSWORD" | cryptsetup open /dev/nvme0n1p3 root
mkfs.ext4 /dev/mapper/root
mount /dev/mapper/root /mnt

# Prepare boot partition: create fat32 filesystem
mkfs.fat -F32 /dev/nvme0n1p1
mount --mkdir /dev/nvme0n1p1 /mnt/boot

# Install Arch Linux
pacstrap /mnt base base-devel linux linux-lts linux-firmware apparmor networkmanager "$CPU_MICROCODE"

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Configure system
arch-chroot /mnt /bin/bash << EOF
# Set system clock
timedatectl set-ntp true
ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
hwclock --systohc

# Set locales
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
locale-gen

# Add persistent keymap
echo "KEYMAP=us" > /etc/vconsole.conf

# Set hostname
echo $HOSTNAME > /etc/hostname

# Create new user
useradd -m -G wheel -s /bin/bash $USERNAME
echo -en "$USER_PASSWORD\n$USER_PASSWORD" | passwd $USERNAME

# Generate initramfs
sed -i 's/^HOOKS.*/HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems fsck)/' /etc/mkinitcpio.conf
sed -i 's/^MODULES.*/MODULES=(ext4 $INITRAMFS_MODULES)/' /etc/mkinitcpio.conf
mkinitcpio -P

# Setup systemd-boot
bootctl --path=/boot install

tee /boot/loader/loader.conf << END
default arch.conf
timeout 2
console-mode max
editor no
END

tee /boot/loader/entries/arch.conf << END
title Arch Linux
linux /vmlinuz-linux
initrd /$CPU_MICROCODE.img
initrd /initramfs-linux.img
options rd.luks.name=$(blkid -s UUID -o value /dev/nvme0n1p3)=root root=/dev/mapper/root rd.luks.name=$(blkid -s UUID -o value /dev/nvme0n1p2)=swap resume=/dev/mapper/swap rd.luks.options=discard lsm=landlock,lockdown,yama,apparmor,bpf nowatchdog rw quiet splash
END

tee /boot/loader/entries/arch-lts.conf << END
title Arch Linux LTS
linux /vmlinuz-linux-lts
initrd /$CPU_MICROCODE.img
initrd /initramfs-linux-lts.img
options rd.luks.name=$(blkid -s UUID -o value /dev/nvme0n1p3)=root root=/dev/mapper/root rd.luks.name=$(blkid -s UUID -o value /dev/nvme0n1p2)=swap resume=/dev/mapper/swap rd.luks.options=discard lsm=landlock,lockdown,yama,apparmor,bpf nowatchdog rw quiet splash
END

# Setup Pacman hook for automatic systemd-boot updates
mkdir -p /etc/pacman.d/hooks/
tee /etc/pacman.d/hooks/systemd-boot.hook << END
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
tee /etc/sysctl.d/99-swappiness.conf << END
vm.swappiness=20
END

# Enable periodic TRIM
systemctl enable fstrim.timer

# Enable NetworkManager service
systemctl enable NetworkManager.service

# Enable Apparmor service
systemctl enable apparmor.service

# Install and configure sudo
echo '%wheel ALL=(ALL) ALL' | EDITOR='tee -a' visudo

# Setup secure boot
pacman -S --noconfirm sbctl
sbctl create-keys
sbctl enroll-keys --yes-this-might-brick-my-machine
sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
sbctl sign -s /boot/EFI/systemd/systemd-bootx64.efi
sbctl sign -s /boot/vmlinuz-linux
sbctl sign -s /boot/vmlinuz-linux-lts

tee /etc/pacman.d/hooks/sbctl.hook << END
[Trigger]
Type = Path
Operation = Install
Operation = Upgrade
Operation = Remove
Target = boot/*
Target = efi/*
Target = usr/lib/modules/*/vmlinuz
Target = usr/lib/initcpio/*
Target = usr/lib/**/efi/*.efi*

[Action]
Description = Signing EFI binaries...
When = PostTransaction
Exec = /usr/bin/sbctl sign-all -g
END

exit
EOF

umount -R /mnt
swapoff -a

echo "Arch Linux is ready. You can reboot now!"