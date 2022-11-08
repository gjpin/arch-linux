#!/bin/bash

################################################
##### Set variables
################################################

read -p "LUKS password: " LUKS_PASSWORD
export LUKS_PASSWORD

read -p "Username: " NEW_USER
export NEW_USER

read -p "User password: " NEW_USER_PASSWORD
export NEW_USER_PASSWORD

read -p "Hostname: " NEW_HOSTNAME
export NEW_HOSTNAME

read -p "Timezone (timedatectl list-timezones): " TIMEZONE
export TIMEZONE

read -p "Desktop environment (plasma / gnome / sway): " DESKTOP_ENVIRONMENT
export DESKTOP_ENVIRONMENT

read -p "Gaming (yes / no): " GAMING
export GAMING

# CPU vendor
if cat /proc/cpuinfo | grep "vendor" | grep "GenuineIntel" > /dev/null; then
    export CPU_MICROCODE="intel-ucode"
elif cat /proc/cpuinfo | grep "vendor" | grep "AuthenticAMD" > /dev/null; then
    export CPU_MICROCODE="amd-ucode"
fi

# GPU vendor
if lspci | grep "VGA" | grep "Intel" > /dev/null; then
    export GPU_PACKAGES="vulkan-intel intel-media-driver intel-gpu-tools"
    export MKINITCPIO_MODULES=" i915"
    export LIBVA_ENV_VAR="export LIBVA_DRIVER_NAME=iHD"
elif lspci | grep "VGA" | grep "AMD" > /dev/null; then
    export GPU_PACKAGES="vulkan-radeon libva-mesa-driver radeontop"
    export MKINITCPIO_MODULES=" amdgpu"
    export LIBVA_ENV_VAR="export LIBVA_DRIVER_NAME=radeonsi"
fi

################################################
##### Partitioning
################################################

# References:
# https://www.rodsbooks.com/gdisk/sgdisk-walkthrough.html
# https://www.dwarmstrong.org/archlinux-install/

# Delete old partition layout and re-read partition table
wipefs -af /dev/nvme0n1
sgdisk --zap-all --clear /dev/nvme0n1
partprobe /dev/nvme0n1

# Partition disk and re-read partition table
sgdisk -n 0:0:+512MiB -t 0:ef00 -c 0:boot /dev/nvme0n1
sgdisk -n 0:0:0 -t 0:8309 -c 0:luks /dev/nvme0n1
partprobe /dev/nvme0n1

################################################
##### LUKS / BTRFS
################################################

# Encrypt and open LUKS partition
echo ${LUKS_PASSWORD} | cryptsetup --type luks2 --hash sha512 --use-random luksFormat /dev/nvme0n1p2
echo ${LUKS_PASSWORD} | cryptsetup luksOpen /dev/nvme0n1p2 cryptdev

# Create BTRFS
mkfs.btrfs -L archlinux /dev/mapper/cryptdev

# Mount root device
mount /dev/mapper/cryptdev /mnt

# Create BTRFS subvolumes
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@cache
btrfs subvolume create /mnt/@libvirt
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@tmp

# Mount BTRFS subvolumes
umount /mnt

export SV_OPTS="rw,noatime,compress-force=zstd:1,space_cache=v2"

mount -o ${SV_OPTS},subvol=@ /dev/mapper/cryptdev /mnt

mkdir -p /mnt/{home,.snapshots,var/cache,var/lib/libvirt,var/log,var/tmp}

mount -o ${SV_OPTS},subvol=@home /dev/mapper/cryptdev /mnt/home
mount -o ${SV_OPTS},subvol=@snapshots /dev/mapper/cryptdev /mnt/.snapshots
mount -o ${SV_OPTS},subvol=@cache /dev/mapper/cryptdev /mnt/var/cache
mount -o ${SV_OPTS},subvol=@libvirt /dev/mapper/cryptdev /mnt/var/lib/libvirt
mount -o ${SV_OPTS},subvol=@log /dev/mapper/cryptdev /mnt/var/log
mount -o ${SV_OPTS},subvol=@tmp /dev/mapper/cryptdev /mnt/var/tmp

################################################
##### EFI / Boot
################################################

# Format and mount EFI/boot partition
mkfs.fat -F32 -n boot /dev/nvme0n1p1
mount --mkdir /dev/nvme0n1p1 /mnt/boot

################################################
##### Install system
################################################

# Import mirrorlist
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/mirrorlist -o /etc/pacman.d/mirrorlist

# Synchronize package databases
pacman -Syy

# Install system
pacstrap /mnt base base-devel linux linux-lts linux-firmware btrfs-progs ${CPU_MICROCODE}

# Generate filesystem tab
genfstab -U /mnt >> /mnt/etc/fstab

# Configure system
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/setup.sh -o setup.sh
cp setup.sh /mnt/setup.sh
chmod +x /mnt/setup.sh
arch-chroot /mnt /bin/bash /setup.sh
umount -R /mnt