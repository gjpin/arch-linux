# Arch Linux install scripts
## Requirements
- UEFI mode
- NVMe SSD
- Single GPU (either Intel or Radeon)
- TPM2

## Install script
- Encrypted root and swap (LUKS2)
- Secure boot with custom keys
- systemd-boot (with Pacman hook for automatic updates)
- SSD Periodic TRIM
- Intel/AMD microcode
- Standard Kernel + LTS kernel as fallback
- Hibernation support
- Swappiness set to 20
- Apparmor

### Partitions
| Name                                                 | Type  | FS Type | Mountpoint |
| ---------------------------------------------------- | :---: | :-----: | :--------: |
| nvme0n1                                              | disk  |         |            |
| ├─nvme0n1p1                                          | part  |  FAT32  |   /boot    |
| ├─nvme0n1p2                                          | part  |         |            |
| &nbsp;&nbsp;&nbsp;└─swap                             | crypt |   Swap  |   [SWAP]   |
| ├─nvme0n1p3                                          | part  |         |            |
| &nbsp;&nbsp;&nbsp;└─root                             | crypt |   EXT4  |     /      |

## Post install script
- Automatically unlock LUKS2 with TPM2
- KDE Plasma or Gnome
- PipeWire
- firewalld
- Automatic login
- Fonts
- paru (AUR helper)
- Flatpak
- Syncthing

## Installation guide
1. Disable secure boot and delete existing keys (go into setup mode)
2. Boot into Arch Linux ISO
3. Connect to the internet. If using wifi, you can use `iwctl` to connect to a network:
   - scan for networks: `station wlan0 scan`
   - list available networks: `station wlan0 get-networks`
   - connect to a network: `station wlan0 connect SSID`
4. Give highest priority to the closest mirror to you on `/etc/pacman.d/mirrorlist` by moving it to the top
5. Sync repos: `pacman -Sy`
6. Download install script: `curl https://raw.githubusercontent.com/gjpin/arch-linux/master/install.sh -o install.sh`
7. Make script executable: `chmod +x install.sh`
8. Run script: `./install.sh`
9. Reboot and re-enable secure boot
10. Boot into new installation
11. Connect to network with ```nmtui```
12. Download KDE Plasma or Gnome install script. eg. `curl https://raw.githubusercontent.com/gjpin/arch-linux/master/plasma.sh -o plasma.sh`

## Misc guides
### How to chroot
```
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
cryptsetup open /dev/nvme0n1p3 root
mount /dev/mapper/root /mnt

arch-chroot /mnt
```