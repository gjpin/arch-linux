# Arch Linux install scripts

For GRUB with BTRFS snapshots see branch 'grub'

## Requirements

- UEFI
- NVMe SSD
- Single GPU (Intel or Radeon)
- TPM2

## Partitions layout

| Name                                    | Type  | FS Type | Mountpoint |     Size     |
| --------------------------------------- | :---: | :-----: | :--------: | :----------: |
| nvme0n1                                 | disk  |         |            |              |
| ├─nvme0n1p1                             | part  |  FAT32  |   /boot    |     1GiB     |
| ├─nvme0n1p2                             | part  |  LUKS2  |            |              |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├──system | crypt |  EXT4   |     /      | Rest of disk |

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
11. Copy wireguard config to /etc/wireguard/wg0.conf
12. Import wireguard connection to networkmanager: `sudo nmcli con import type wireguard file /etc/wireguard/wg0.conf`
13. Set wg0's firewalld zone: `sudo firewall-cmd --permanent --zone=trusted --add-interface=wg0`

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
gamescope -W 2560 -H 1440 -f -- %command%

# gamescope in 1440p + MangoHud
gamescope -W 2560 -H 1440 -f -- mangohud %command%

# gamescope upscale from 1080p to 1440p with FSR + mangohud
gamescope -h 1080 -H 1440 -U -f -- mangohud %command%
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

### Wake-on-LAN quirks
```bash
# References:
# https://wiki.archlinux.org/title/Wake-on-LAN#Fix_by_Kernel_quirks

# If WoL has been enabled and the computer does not shutdown

# Add kernel boot parameters to enable quirks
sed -i "s|=system|& xhci_hcd.quirks=270336|" /boot/loader/entries/arch.conf
sed -i "s|=system|& xhci_hcd.quirks=270336|" /boot/loader/entries/arch-lts.conf
```