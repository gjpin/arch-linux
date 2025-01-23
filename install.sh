#!/usr/bin/bash

################################################
##### Logs
################################################

# Define the log file
LOGFILE="install.log"

# Start logging all output to the log file
exec > >(tee -a "$LOGFILE") 2>&1

# Log each command before executing it
log_command() {
    echo "\$ $BASH_COMMAND" >> "$LOGFILE"
}
trap log_command DEBUG

################################################
##### Set variables
################################################

read -p "RAID0 (yes / no): " RAID0
export RAID0

read -sp "LUKS password: " LUKS_PASSWORD
export LUKS_PASSWORD

read -p "Username: " NEW_USER
export NEW_USER

read -sp "User password: " NEW_USER_PASSWORD
export NEW_USER_PASSWORD

read -p "Hostname: " NEW_HOSTNAME
export NEW_HOSTNAME

read -p "Timezone (timedatectl list-timezones): " TIMEZONE
export TIMEZONE

read -p "Desktop environment (plasma / gnome): " DESKTOP_ENVIRONMENT
export DESKTOP_ENVIRONMENT

read -p "Gaming (yes / no): " GAMING
export GAMING

read -p "Steam native (yes / no): " STEAM_NATIVE
export STEAM_NATIVE

read -p "VR (yes / no): " VR
export VR

read -p "Autologin (yes / no): " AUTOLOGIN
export AUTOLOGIN

# CPU vendor
if cat /proc/cpuinfo | grep "vendor" | grep "GenuineIntel" > /dev/null; then
    export CPU_MICROCODE="intel-ucode"
elif cat /proc/cpuinfo | grep "vendor" | grep "AuthenticAMD" > /dev/null; then
    export CPU_MICROCODE="amd-ucode"
    export AMD_SCALING_DRIVER="amd_pstate=active"
fi

# GPU vendor
if lspci | grep "VGA" | grep "Intel" > /dev/null; then
    export GPU_PACKAGES="vulkan-intel intel-media-driver intel-gpu-tools"
    export GPU_MKINITCPIO_MODULES="i915"
    export LIBVA_ENV_VAR="LIBVA_DRIVER_NAME=iHD"
elif lspci | grep "VGA" | grep "AMD" > /dev/null; then
    export GPU_PACKAGES="vulkan-radeon libva-mesa-driver radeontop mesa-vdpau"
    export GPU_MKINITCPIO_MODULES="amdgpu"
    export LIBVA_ENV_VAR="LIBVA_DRIVER_NAME=radeonsi"
fi

################################################
##### Partitioning
################################################

# References:
# https://www.rodsbooks.com/gdisk/sgdisk-walkthrough.html
# https://www.dwarmstrong.org/archlinux-install/
# https://wiki.archlinux.org/title/RAID#Installation

if [ ${RAID0} = "no" ]; then
    # Read partition table
    partprobe /dev/nvme0n1

    # Delete old partition layout
    wipefs -af /dev/nvme0n1
    sgdisk --zap-all --clear /dev/nvme0n1

    # Read partition table
    partprobe /dev/nvme0n1

    # Partition disk and re-read partition table
    sgdisk -n 1:0:+1G -t 1:ef00 -c 1:EFI /dev/nvme0n1
    sgdisk -n 2:0:0 -t 2:8309 -c 2:LUKS /dev/nvme0n1

    # Read partition table
    partprobe /dev/nvme0n1
elif [ ${RAID0} = "yes" ]; then
    # Install mdadm
    pacman -S --noconfirm mdadm

    # Read partition tables
    partprobe /dev/nvme0n1
    partprobe /dev/nvme1n1

    # Delete old partition layouts
    wipefs -af /dev/nvme0n1
    wipefs -af /dev/nvme1n1
    sgdisk --zap-all --clear /dev/nvme0n1
    sgdisk --zap-all --clear /dev/nvme1n1

    # Read partition tables
    partprobe /dev/nvme0n1
    partprobe /dev/nvme1n1

    # Erase old RAID configuration information
    mdadm --misc --zero-superblock /dev/nvme0n1
    mdadm --misc --zero-superblock /dev/nvme1n1

    # Partition disks
    sgdisk -n 1:0:+1G -t 1:ef00 -c 1:EFI /dev/nvme0n1
    sgdisk -n 2:0:0 -t 2:fd00 -c 2:RAID /dev/nvme0n1
    sgdisk -n 1:0:+1G -t 1:ef00 -c 1:EFIDUMMY /dev/nvme1n1
    sgdisk -n 2:0:0 -t 2:fd00 -c 2:RAID /dev/nvme1n1

    # Read partition tables
    partprobe /dev/nvme0n1
    partprobe /dev/nvme1n1

    # Build RAID array
    mdadm --create /dev/md/ArchArray --level=0 --metadata=1.2 --chunk=512 --raid-devices=2 --force /dev/nvme0n1p2 /dev/nvme1n1p2

    # Update mdadm configuration file
    mdadm --detail --scan >> /etc/mdadm.conf
fi

################################################
##### LUKS / System and boot partitions
################################################

# References:
# https://github.com/tytso/e2fsprogs/blob/master/misc/mke2fs.conf.in
# https://wiki.archlinux.org/title/RAID#Format_the_RAID_filesystem

if [ ${RAID0} = "no" ]; then
    # Encrypt and open LUKS partition
    echo ${LUKS_PASSWORD} | cryptsetup --type luks2 --hash sha512 --use-random luksFormat /dev/disk/by-partlabel/LUKS
    echo ${LUKS_PASSWORD} | cryptsetup luksOpen /dev/disk/by-partlabel/LUKS system

    # Format partition to EXT4
    mkfs.ext4 -L system /dev/mapper/system

    # Mount root device
    mount -t ext4 LABEL=system /mnt

    # Format and mount EFI/boot partition
    mkfs.fat -F32 -n EFI /dev/disk/by-partlabel/EFI
    mount --mkdir /dev/nvme0n1p1 /mnt/boot
elif [ ${RAID0} = "yes" ]; then
    # Mount RAID partition
    mdadm --assemble /dev/md/ArchArray /dev/nvme0n1p2 /dev/nvme1n1p2

    # Encrypt and open LUKS partition
    echo ${LUKS_PASSWORD} | cryptsetup --type luks2 --hash sha512 --use-random luksFormat /dev/md/ArchArray
    echo ${LUKS_PASSWORD} | cryptsetup luksOpen /dev/md/ArchArray system

    # Format partition to EXT4
    mkfs.ext4 -L system /dev/mapper/system

    # Mount root device
    mount -t ext4 LABEL=system /mnt

    # Format and mount EFI/boot partition
    mkfs.fat -F32 -n EFI /dev/disk/by-partlabel/EFI
    mount --mkdir /dev/nvme0n1p1 /mnt/boot
fi

################################################
##### Install system
################################################

# Import mirrorlist
tee /etc/pacman.d/mirrorlist << 'EOF'
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
EOF

# Synchronize package databases
pacman -Syy

# Install system
pacstrap /mnt base base-devel linux linux-headers linux-lts linux-lts-headers linux-firmware e2fsprogs mdadm tpm2-tools tpm2-tss ${CPU_MICROCODE}

# Generate filesystem tab
genfstab -U /mnt >> /mnt/etc/fstab

# Update mdadm configuration file
if [ ${RAID0} = "yes" ]; then
    mdadm --detail --scan >> /mnt/etc/mdadm.conf
fi

# Configure system
mkdir -p /mnt/install-arch
cp ./plasma.sh /mnt/install-arch/plasma.sh
cp ./gnome.sh /mnt/install-arch/gnome.sh
cp ./gaming.sh /mnt/install-arch/gaming.sh
cp ./setup.sh /mnt/install-arch/setup.sh
arch-chroot /mnt /bin/bash /install-arch/setup.sh
rm -rf /mnt/install-arch
umount -R /mnt