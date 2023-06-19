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
| nvme0n1                                              | disk  |         |            |               |
| ├─nvme0n1p1                                          | part  |  FAT32  |    /boot   |    1GiB     |
| ├─nvme0n1p2                                          | part  |  LUKS2  |            |               |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├──system              | crypt |  EXT4   |     /      |  Rest of disk |

## Installation guide
1. Disable secure boot and delete existing keys (go into setup mode)
2. Boot into Arch Linux ISO
3. Connect to the internet. If using wifi, you can use `iwctl` to connect to a network:
   - scan for networks: `station wlan0 scan`
   - list available networks: `station wlan0 get-networks`
   - connect to a network: `station wlan0 connect SSID`
4. Init keyring: `pacman-key --init && pacman-key --populate`
5. Update repos and install git: `pacman -Sy git`
6. Clone repo: `git clone https://github.com/gjpin/arch-linux.git`
7. Run script: `cd arch-linux && ./install.sh`
8. Reboot and re-enable secure boot
9. Boot into new installation
10. Enroll LUKS key in TPM2: `sudo systemd-cryptenroll --tpm2-pcrs=0+1+7 --tpm2-device=auto /dev/nvme0n1p2`
11. Configure Firefox:
```
# Set Firefox profile path
FIREFOX_PROFILE_PATH=$(realpath /${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox/*.default-release)

# Import Firefox configs
wget https://raw.githubusercontent.com/gjpin/arch-linux/main/extra/firefox.js -O ${FIREFOX_PROFILE_PATH}/user.js

# Create extensisons folder
mkdir -p ${FIREFOX_PROFILE_PATH}/extensions

# Import extensions
curl https://addons.mozilla.org/firefox/downloads/file/4003969/ublock_origin-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/uBlock0@raymondhill.net.xpi
curl https://addons.mozilla.org/firefox/downloads/file/4018008/bitwarden_password_manager-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/{446900e4-71c2-419f-a6a7-df9c091e268b}.xpi
curl https://addons.mozilla.org/firefox/downloads/file/3998783/floccus-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/floccus@handmadeideas.org.xpi
curl https://addons.mozilla.org/firefox/downloads/file/3932862/multi_account_containers-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/@testpilot-containers.xpi
```

## Misc guides
### How to chroot
```bash
cryptsetup luksOpen /dev/disk/by-partlabel/LUKS system
mount -t ext4 LABEL=system /mnt
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

# gamescope in 1440p
gamescope -W 2560 -H 1440 -f -e -- %command%

# gamescope in 1440p + MangoHud
gamescope -W 2560 -H 1440 -f -e -- mangohud %command%

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

## keyring issues
```bash
killall gpg-agent
rm -rf /etc/pacman.d/gnupgp
pacman-key --init
pacman-key --populate
```

## Auto-mount extra drive
```bash
# Delete old partition layout and re-read partition table
sudo wipefs -af /dev/nvme1n1
sudo sgdisk --zap-all --clear /dev/nvme1n1
sudo partprobe /dev/nvme1n1

# Partition disk and re-read partition table
sudo sgdisk -n 1:0:0 -t 1:8309 -c 1:LUKSDATA /dev/nvme1n1
sudo partprobe /dev/nvme1n1

# Encrypt and open LUKS partition
sudo cryptsetup --type luks2 --hash sha512 --use-random luksFormat /dev/disk/by-partlabel/LUKSDATA
sudo cryptsetup luksOpen /dev/disk/by-partlabel/LUKSDATA data

# Format partition to EXT4
sudo mkfs.ext4 -L data /dev/mapper/data

# Mount root device
sudo mkdir -p /data
sudo mount -t ext4 LABEL=data /data

# Auto-mount
sudo tee -a /etc/fstab << EOF

# data disk
/dev/mapper/data /data ext4 defaults 0 0
EOF

sudo tee -a /etc/crypttab << EOF

data UUID=$(blkid -s UUID -o value /dev/nvme1n1p1) none
EOF

# Change ownership to user
sudo chown -R $USER:$USER /data

# Auto unlock
sudo systemd-cryptenroll --tpm2-device=auto /dev/nvme1n1p1
```