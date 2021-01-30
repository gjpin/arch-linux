#!/bin/bash

encryption_passphrase="test"
root_password="test"
user_password="test"
hostname="test"
username="test"
continent_city="Europe/Paris"
swap_size="2" # same as ram if using hibernation, otherwise minimum of 8

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
sgdisk --zap-all $DRIVE

echo "Partitioning drive with partition labels"
sgdisk --clear --new=1:0:+550MiB --typecode=1:ef00 --change-name=1:EFI --new=2:0:+"$swap_size"GiB --typecode=2:8200 --change-name=2:cryptswap --new=3:0:0 --typecode=3:8300 --change-name=3:cryptsystem $DRIVE

echo "Formatting EFI partition"
mkfs.fat -F32 -n EFI /dev/disk/by-partlabel/EFI

echo "Encrypting and opening system partition"
mkdir -p -m0700 /run/cryptsetup
echo "$encryption_passphrase" | cryptsetup -q --align-payload=8192 -h sha512 -s 512 --use-random --type luks2 -c aes-xts-plain64 luksFormat /dev/disk/by-partlabel/cryptsystem
echo "$encryption_passphrase" | cryptsetup open /dev/disk/by-partlabel/cryptsystem system

echo "Setting up encrypted swap"
cryptsetup open --type plain --key-file /dev/urandom /dev/disk/by-partlabel/cryptswap swap
mkswap -L swap /dev/mapper/swap
swapon -L swap

echo "Creating and mounting BTRFS subvolumes"
mkfs.btrfs --force --label system /dev/mapper/system
o=defaults,x-mount.mkdir
o_btrfs=$o,compress=zstd,ssd,noatime
mount -t btrfs LABEL=system /mnt
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
btrfs subvolume create /mnt/snapshots
umount -R /mnt
mount -t btrfs -o subvol=root,$o_btrfs LABEL=system /mnt
mount -t btrfs -o subvol=home,$o_btrfs LABEL=system /mnt/home
mount -t btrfs -o subvol=snapshots,$o_btrfs LABEL=system /mnt/.snapshots

echo "Mounting EFI partition"
mkdir /mnt/boot
mount LABEL=EFI /mnt/boot

echo "Installing Arch Linux"
yes '' | pacstrap /mnt base base-devel linux linux-headers linux-lts linux-lts-headers linux-firmware efibootmgr btrfs-progs dosfstools e2fsprogs device-mapper $cpu_microcode cryptsetup networkmanager wget man-db man-pages nano diffutils flatpak lm_sensors

echo "Generating fstab"
genfstab -L -p /mnt >> /mnt/etc/fstab
sed -i s+LABEL=swap+/dev/mapper/swap+ /mnt/etc/fstab

echo "Mounting swap at boot"
tee -a /mnt/etc/crypttab << EOF
cryptswap      /dev/disk/by-partlabel/cryptswap             /dev/urandom            swap,offset=2048,cipher=aes-xts-plain64,size=512
EOF

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
options rd.luks.name=$(blkid -s UUID -o value /dev/vda2)=cryptsystem root=UUID=$(btrfs filesystem show system | grep -Po 'uuid: \K.*') rootflags=subvol=root rd.luks.options=discard$kernel_options nmi_watchdog=0 quiet rw
END

touch /boot/loader/entries/arch-lts.conf
tee -a /boot/loader/entries/arch-lts.conf << END
title Arch Linux LTS
linux /vmlinuz-linux-lts
initrd /$cpu_microcode.img
initrd /initramfs-linux-lts.img
options rd.luks.name=$(blkid -s UUID -o value /dev/vda2)=cryptsystem root=UUID=$(btrfs filesystem show system | grep -Po 'uuid: \K.*') rootflags=subvol=root rd.luks.options=discard$kernel_options nmi_watchdog=0 quiet rw
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