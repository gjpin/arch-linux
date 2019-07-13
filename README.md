# Modern Arch Linux setup
*Note: this is a collection of SIMPLE Arch Linux (post-)install scripts, custom made for my machine.*

## Features and setup
### Install script
* LVM on LUKS
* LUKS2
* systemd-boot (with Pacman hook for automatic updates)
* Automatic login (with systemd)
* SSD Periodic TRIM
* Intel microcode

### Post install script
* UFW (deny incoming, allow outgoing)
* Applications: firefox, keepassxc, git, openssh, vim, alacritty

### Partitions
| Name | Type | Mountpoint |
| - | :-: | :-: |
| nvme0n1 | disk | |
| ├─nvme0n1p1 | part | /boot |
| ├─nvme0n1p2 | part |  |
| &nbsp;&nbsp;&nbsp;└─cryptoVols | crypt | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├─Arch-swap | lvm | [SWAP] |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└─Arch-root | lvm | / |

## Requirements
* UEFI mode
* NVMe SSD
* TRIM compatible SSD
* Intel CPU

## Quickstart
1. Download and boot into the latest [Arch Linux iso](https://www.archlinux.org/download/)
2. Connect to the internet. If using wifi, you can use wifi-menu
3. wget [1_arch_install.sh](https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/1_arch_install.sh)
4. Change the variables at the top of the file
   * continent_country must have the following format: Continent/City . e.g. Europe/Berlin
5. Enable the closest mirror to you on /etc/pacman.d/mirrorlist (move it to the top)
6. Make the script executable: chmod +x 1_arch_install.sh
7. Run the script: ./1_arch_install.sh
8. Reboot
9. wget [2_arch_post_install.sh](https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/2_arch_post_install.sh)
9. Make the script executable: chmod +x 2_arch_post_install.sh
10. Run the script: ./2_arch_post_install.sh

## MISC
### How to chroot
```
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
cryptsetup luksOpen /dev/nvme0n1p2 cryptoVols
mount /dev/mapper/Arch-root /mnt
arch-chroot /mnt
```

### TODO
* Make post-install scripts idempotent
* Hotkey to automatically switch GTK+VSCode themes (dark x light)

### References
* Ricing: [First rice on my super old MacBook Air!](https://www.reddit.com/r/unixporn/comments/9y9w0r/sway_first_rice_on_my_super_old_macbook_air/) on Reddit