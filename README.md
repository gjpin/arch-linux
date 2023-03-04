# Arch Linux install scripts
For GRUB with BTRFS snapshots see branch 'grub' 

## Requirements
- UEFI
- NVMe SSD
- Single GPU (Intel or Radeon)
- TPM2

## Partitions layout
| Name                                                 | Type  | FS Type | Mountpoint |      Size     |
| ---------------------------------------------------- | :---: | :-----: | :--------: | :-----------: |
| zram0                                                | rom   |         |   [SWAP]   |      8GB      |
| nvme0n1                                              | disk  |         |            |               |
| ├─nvme0n1p1                                          | part  |  FAT32  |    /boot   |    512MiB     |
| ├─nvme0n1p2                                          | part  |  LUKS2  |            |               |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├──system              | crypt |  BTRFS  |     /      |  Rest of disk |

## Installation guide
1. Disable secure boot and delete existing keys (go into setup mode)
2. Boot into Arch Linux ISO
3. Connect to the internet. If using wifi, you can use `iwctl` to connect to a network:
   - scan for networks: `station wlan0 scan`
   - list available networks: `station wlan0 get-networks`
   - connect to a network: `station wlan0 connect SSID`
4. Init keyring: `pacman -Sy archlinux-keyring`
5. Update repos and install git: `pacman -Sy git`
6. Clone repo: `git clone https://github.com/gjpin/arch-linux.git`
7. Run script: `install.sh`
8. Reboot and re-enable secure boot
9. Boot into new installation
10. Enroll LUKS key in TPM2: `sudo systemd-cryptenroll --tpm2-pcrs=0+1+7 --tpm2-device=auto /dev/nvme0n1p2`

## Misc guides
### How to chroot
```bash
cryptsetup luksOpen /dev/disk/by-partlabel/LUKS system
mount -t btrfs -o subvol=@,compress=zstd:3,noatime,discard,space_cache=v2,ssd LABEL=system /mnt
mount -t btrfs -o subvol=@home,compress=zstd:3,noatime,discard,space_cache=v2,ssd LABEL=system /mnt/home
mount /dev/nvme0n1p1 /mnt/boot
arch-chroot /mnt
```

### How to re-enroll keys in TPM2
```bash
sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1p2
sudo systemd-cryptenroll --tpm2-pcrs=0+1+7 --tpm2-device=auto /dev/nvme0n1p2
```

### How to show systemd-boot menu
```bash
Press 'space' during boot
```

### How to repair EFI
```bash
1. chroot
2. fsck -a /dev/nvme0n1p1
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

### AppArmor
```bash
# References:
# https://wiki.archlinux.org/title/AppArmor

# Install AppArmor
pacman -S --noconfirm apparmor

# Enable AppArmor service
systemctl enable apparmor.service

# Enable AppArmor as default security model
sed -i "s|tpm2-device=auto|& lsm=landlock,lockdown,yama,integrity,apparmor,bpf|" /boot/loader/entries/arch.conf
sed -i "s|tpm2-device=auto|& lsm=landlock,lockdown,yama,integrity,apparmor,bpf|" /boot/loader/entries/arch-lts.conf

# Enable caching AppArmor profiles
sed -i "s|^#write-cache|write-cache|g" /etc/apparmor/parser.conf
sed -i "s|^#Optimize=compress-fast|Optimize=compress-fast|g" /etc/apparmor/parser.conf
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