#!/usr/bin/bash

################################################
##### Set variables
################################################

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

read -p "Visual Studio Code (yes / no): " VSCODE
export VSCODE

read -p "RAID0 (yes / no): " RAID0
export RAID0

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
    export LIBVA_ENV_VAR="LIBVA_DRIVER_NAME=iHD"
elif lspci | grep "VGA" | grep "AMD" > /dev/null; then
    export GPU_PACKAGES="vulkan-radeon libva-mesa-driver radeontop"
    export MKINITCPIO_MODULES=" amdgpu"
    export LIBVA_ENV_VAR="LIBVA_DRIVER_NAME=radeonsi"
fi

################################################
##### Single disk
################################################

# References:
# https://www.rodsbooks.com/gdisk/sgdisk-walkthrough.html
# https://www.dwarmstrong.org/archlinux-install/

if [ ${RAID0} != "yes" ]; then
    # Delete old partition layout and re-read partition table
    wipefs -af /dev/nvme0n1
    sgdisk --zap-all /dev/nvme0n1
    partprobe /dev/nvme0n1

    # Partition disk and re-read partition table
    sgdisk -n 1:0:+1G -t 1:ef00 -c 1:EFI /dev/nvme0n1
    sgdisk -n 2:0:0 -t 2:8309 -c 2:ROOT /dev/nvme0n1
    partprobe /dev/nvme0n1

    # Encrypt and open ROOT partition
    echo ${LUKS_PASSWORD} | cryptsetup --type luks2 --hash sha512 --use-random luksFormat /dev/disk/by-partlabel/ROOT
    echo ${LUKS_PASSWORD} | cryptsetup luksOpen /dev/disk/by-partlabel/ROOT system

    # Format partition to EXT4
    mkfs.ext4 -L system /dev/mapper/system

    # Mount root device
    mount -t ext4 LABEL=system /mnt

    # Format and mount EFI/boot partition
    mkfs.fat -F32 -n EFI /dev/disk/by-partlabel/EFI
    mount --mkdir /dev/nvme0n1p1 /mnt/boot
fi

################################################
##### RAID0
################################################

# References:
# https://wiki.archlinux.org/title/RAID#Installation
# https://github.com/kretcheu/dicas/blob/master/raid0.md

if [ ${RAID0} = "yes" ]; then
    # Prepare and partition nvme0n1
    sgdisk --zap-all /dev/nvme0n1
    mdadm --misc --zero-superblock --force /dev/nvme0n1
    partprobe /dev/nvme0n1

    sgdisk -n 1:0:+1G -t 1:ef00 -c 1:EFI /dev/nvme0n1
    sgdisk -n 2:0:0 -t 2:fd00 -c 2:ROOT /dev/nvme0n1
    partprobe /dev/nvme0n1

    # Prepare and partition nvme1n1
    sgdisk --zap-all /dev/nvme1n1
    mdadm --misc --zero-superblock --force /dev/nvme1n1
    partprobe /dev/nvme1n1

    sgdisk /dev/nvme0n1 -R /dev/nvme1n1 -G
    partprobe /dev/nvme1n1

    # Build array
    mdadm --create /dev/md/root --level=0 --raid-disks=2 /dev/nvme0n1p2 /dev/nvme1n1p2

    # Update configuration file
    mdadm --detail --scan >> /etc/mdadm.conf

    # Assemble array
    mdadm --assemble --scan

    # Encrypt and open LUKS partition in array
    echo ${LUKS_PASSWORD} | cryptsetup --type luks2 --hash sha512 --use-random luksFormat /dev/md/root
    echo ${LUKS_PASSWORD} | cryptsetup luksOpen /dev/md/root system

    # Format the RAID filesystem to EXT4
    mkfs.ext4 -L system -b 4096 -E stride=128,stripe-width=256 /dev/mapper/system

    # Mount root device
    mount -t ext4 LABEL=system /mnt

    # Format and mount EFI/boot partition
    mkfs.fat -F32 -n EFI /dev/disk/by-partlabel/EFI
    mount --mkdir /dev/nvme0n1p1 /mnt/boot
fi

################################################
##### Install system
################################################

# References:
# https://wiki.archlinux.org/title/RAID#Update_configuration_file_2

# Import mirrorlist
tee /etc/pacman.d/mirrorlist << 'EOF'
Server = https://europe.mirror.pkgbuild.com/$repo/os/$arch
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
EOF

# Synchronize package databases
pacman -Syy

# Install system
pacstrap /mnt base base-devel linux linux-lts linux-firmware e2fsprogs ${CPU_MICROCODE}

# Generate filesystem tab
genfstab -U /mnt >> /mnt/etc/fstab

# Configure system
mkdir -p /mnt/install-arch
cp ./plasma.sh /mnt/install-arch/plasma.sh
cp ./gnome.sh /mnt/install-arch/gnome.sh
cp ./gaming.sh /mnt/install-arch/gaming.sh
cp ./setup.sh /mnt/install-arch/setup.sh
arch-chroot /mnt /bin/bash /install-arch/setup.sh
rm -rf /mnt/install-arch

# Update mdadm configuration file
if [ ${RAID0} = "yes" ]; then
    mdadm --detail --scan >> /mnt/etc/mdadm.conf
fi

# Unmount filesystem
umount -R /mnt