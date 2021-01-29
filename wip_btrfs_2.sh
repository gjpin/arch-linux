timedatectl set-ntp true

#create boot partition

cryptsetup luksFormat /dev/nvme0n1p2
mkfs.fat -F32 -n LINUXEFI /dev/nvme0n1p1
mkfs.btrfs -L Arch /dev/mapper/cryptroot

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
mount /dev/nvme0n1p1 /mnt/boot

pacstrap /mnt base base-devel linux linux-firmware intel-ucode amd-ucode \
wpa_supplicant btrfs-progs dosfstools e2fsprogs zsh zsh-completions \
zsh-syntax-highlighting tmux rsync openssh git vim neovim htop networkmanager \
openvpn networkmanager-openvpn fzf ruby python nodejs

genfstab /mnt >> /mnt/etc/fstab

# CHROOT

nvim /etc/locale.gen # Uncomment en_GB.UTF-8
locale-gen
echo LANG=en_GB.UTF-8 > /etc/locale.conf
echo keymap=uk > /etc/vconsole.conf
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc

echo new-hostname > /etc/hostname

# /etc/mkinitcpio.conf
 HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)
+ HOOKS=(base systemd autodetect keyboard sd-vconsole modconf block sd-encrypt filesystems fsck)
+ BINARIES=(btrfs)

mkinitcpio -P

bootctl --path=/boot install


# /boot/loader/entries/arch.conf
title Arch Linux
linux /vmlinuz-linux
initrd  /amd-ucode.img
initrd /initramfs-linux.img
options rd.luks.name=UUID_OF_LUKS_PARTITION=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rd.luks.options=discard rw

#/boot/loader/loader.conf igual ao que tenho

###### Swapfile/ hibernation
# mount swapfile subvolume
mkdir /swapspace
mount -o noatime,subvol=@swap /dev/mapper/cryptroot /swapspace

# create swapfile
truncate -s 0 /swapspace/swapfile
chattr +C /swapspace/swapfile
btrfs property set /swapspace/swapfile compression none

fallocate -l 32G /swapspace/swapfile
mkswap /swapspace/swapfile

chmod 600 /swapspace/swapfile

# activate swapfile
swapon /swapspace/swapfile

# add to /etc/fstab
/dev/mapper/cryptroot /swapspace btrfs rw,noatime,space_cachesubvol=@swap 0 0
/swapspace/swapfile none swap defaults,discard 0 0

# Hibernation into swap file on Btrfs
# https://wiki.archlinux.org/index.php/Power_management/Suspend_and_hibernate#Hibernation_into_swap_file_on_Btrfs
# then Then add resume and resume_offset to /boot/loader/entries/arch.conf
# options rd.luks.key=UUID_OF_LUKS_PARTITION=/myhostname.key:UUID=UUID_OF_USB_PARTITION rd.luks.name=UUID_OF_LUKS_PARTITION=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rd.luks.options=discard,keyfile-timeout=10s resume=/dev/mapper/cryptroot resume_offset=OFFSET_CALC rw





###########

# automate btrfs snapshots (once a day, once a week)
mkdir -p /usr/local/bin/
tee -a touch /usr/local/bin/ << END
dt=$(date '+%d/%m/%Y %H:%M:%S');
btrfs subvolume snapshot @ .snapshots/root/$dt
btrfs subvolume snapshot @ .snapshots/home/$dt
END

touch /etc/systemd/system/btrfs-snapshots.timer
tee -a touch /etc/systemd/system/btrfs-snapshots.timer << END
[Unit]
Description=Take BTRFS snapshots daily and weekly

[Timer]
OnCalendar=daily
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
END

systemctl start btrfs-snapshots.timer
systemctl enable btrfs-snapshots.timer




###
remover snapshots do guia acima

criar snapshots com snapper
https://wiki.archlinux.org/index.php/Snapper

ver seccao: Preventing slowdowns
    - reduzir numero de automatic snapshots
    - ver updatedb

preserving log files section

see Snapshots on boot