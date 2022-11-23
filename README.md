# Arch Linux install scripts
## Requirements
- UEFI
- NVMe SSD
- Single GPU (Intel or Radeon)
- TPM2

## Features
- Encrypted root with TPM2 unlock
- Secure boot with custom keys
- GRUB with Snapper snapshots + password protected editing
- zram
- SSD Periodic TRIM
- Intel/AMD microcode
- Standard Kernel + LTS kernel
- Vulkan drivers
- Hardware video acceleration
- Pipewire
- Flatpak
- Docker
- AppArmor
- ZSH
- KDE Plasma or Gnome
   - SwayWM: working, but unfinished
- Steam / Heroic via Flatpak with mesa-git (optional)
- Check install.sh and setup*.sh for all features

## Partitions layout
| Name                                                 | Type  | FS Type | Mountpoint |      Size     |
| ---------------------------------------------------- | :---: | :-----: | :--------: | :-----------: |
| zram0                                                | rom   |         |   [SWAP]   |      8GB      |
| nvme0n1                                              | disk  |         |            |               |
| ├─nvme0n1p1                                          | part  |  FAT32  |    /boot   |    512MiB     |
| ├─nvme0n1p2                                          | part  |  LUKS2  |            |               |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├──cryptdev            | crypt |  BTRFS  |     /      |  Rest of disk |

## Installation guide
1. Disable secure boot and delete existing keys (go into setup mode)
2. Boot into Arch Linux ISO
3. Connect to the internet. If using wifi, you can use `iwctl` to connect to a network:
   - scan for networks: `station wlan0 scan`
   - list available networks: `station wlan0 get-networks`
   - connect to a network: `station wlan0 connect SSID`
4. Download install script: `curl https://raw.githubusercontent.com/gjpin/arch-linux/main/install.sh -O`
5. Make script executable: `chmod +x install.sh`
6. Run script: `./install.sh`
7. Reboot and re-enable secure boot
8. Boot into new installation
9. Enroll LUKS key in TPM2: `sudo systemd-cryptenroll --tpm2-pcrs=0+1+7 --tpm2-device=auto /dev/nvme0n1p2`
10. Create /boot backup: `sudo rsync -a --delete /boot/ /.bootbackup`
11. Import WireGuard config to /etc/wireguard
12. Enable WireGuard connection: `sudo nmcli con import type wireguard file /etc/wireguard/wg0.conf`
13. Set wg0's firewalld zone: `sudo firewall-cmd --permanent --zone=trusted --add-interface=wg0`
14. Create snapper snapshot: `sudo snapper -c root create -d "**System install**"`

## Misc guides
### How to chroot
```bash
mkdir -p /mnt/boot
cryptsetup open /dev/nvme0n1p2 cryptdev
mount /dev/mapper/cryptdev /mnt -o subvol=@
mount /dev/nvme0n1p1 /mnt/boot
arch-chroot /mnt
```

### How to re-enroll keys in TPM2
```bash
sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1p2
sudo systemd-cryptenroll --tpm2-pcrs=0+1+7 --tpm2-device=auto /dev/nvme0n1p2
```

### How to show GRUB menu
```bash
Press ESC during boot 
```

### How to repair EFI
```bash
1. chroot
2. fsck -a /dev/nvme0n1p1
```

### How to rollback to another snapshot
```bash
1. Boot to a working snapshot
2. (sudo su)
3. mount /dev/mapper/cryptdev /mnt
4. mount --mkdir /dev/nvme0n1p1 /mnt/boot
5. mv /mnt/@ /mnt/@.broken
   or
   btrfs subvolume delete /mnt/@
6. grep -r '<date>' /mnt/@snapshots/*/info.xml
7. btrfs subvolume snapshot /mnt/@snapshots/${NUMBER}/snapshot /mnt/@
8. cp -R /mnt/@snapshots/${NUMBER}/snapshot/.bootbackup/* /mnt/boot
9. umount /mnt
10. reboot -f
```

## How to revert to a previous Flatpak commit
```bash
# List available commits
flatpak remote-info --log flathub org.godotengine.Godot

# Downgrade to specific version
sudo flatpak update --commit=${HASH} org.godotengine.Godot

# Pin version
flatpak mask org.godotengine.Godot
```

### How to use Gamescope + MangoHud in Steam
```bash
# MangoHud
mangohud %command%

# gamescope native resolution
gamescope -f -e -- %command%

# gamescope native resolution + MangoHud
gamescope -f -e -- mangohud %command%

# gamescope upscale from 1080p to 1440p with FSR + mangohud
gamescope -h 1080 -H 1440 -U -f -e -- mangohud %command%
```

## Additional AppArmor profiles
```bash
# References:
# https://github.com/roddhjav/apparmor.d

# Install additional AppArmor profiles in enforce mode
git clone https://aur.archlinux.org/apparmor.d-git.git
cd apparmor.d-git
sed -i "|./configure --complain|./configure|" PKGBUILD
makepkg -s
sudo pacman -U apparmor.d-*.pkg.tar.zst \
  --overwrite etc/apparmor.d/tunables/global \
  --overwrite etc/apparmor.d/tunables/xdg-user-dirs \
  --overwrite etc/apparmor.d/abstractions/trash
cd ..
rm -rf apparmor.d-git
```