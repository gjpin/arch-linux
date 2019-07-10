# **Arch Linux - Install and post-install bash scripts**
*Note: this is a collection of VERY SIMPLE Arch Linux install scripts.
It's custom made for my machine and needs. If there's any interest, I'm willing to refactor and make it more generic.*

## **Requirements**
* UEFI mode
* NVMe SSD
* TRIM compatible SSD
* Intel CPU

## Features
* LVM on LUKS
* SSD Periodic TRIM
* UFW (deny incoming, allow outgoing)
* Applications: firefox, keepassxc, git, openssh, vim, alacritty

## **Quickstart**
1. Connect to the internet. If using wifi, you can use wifi-menu
2. Download 1_install_arch.sh
3. Change the variables at the top
  * continent_country must have the following format: Continent/City . e.g. Europe/Berlin
4. Enable the closest mirror to you on /etc/pacman.d/mirrorlist
5. Make the script executable: chmod +x 1_install_arch.sh
6. Run the script: ./1_install_arch.sh
7. Reboot
8. wget 2_post_arch_install.sh
9. Make the script executable: chmod +x 2_post_arch_install.sh
10. 6. Run the script: ./2_post_arch_install.sh

## Setup
### Partitions
| Name | Type | Mountpoint |
| - | :-: | :-: |
| nvme0n1 | disk | |
| ├─nvme0n1p1 | part | /boot |
| ├─nvme0n1p2 | part |  |
| &nbsp;&nbsp;&nbsp;└─cryptoVols | crypt | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├─Arch-swap | lvm | [SWAP] |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└─Arch-root | lvm | / |

## How to chroot
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
cryptsetup luksOpen /dev/nvme0n1p2 cryptoVols
mount /dev/mapper/Arch-root /mnt
arch-chroot /mnt


**TODO**
* Make scripts idempotent
* Hotkey to automatically switch GTK+VSCode themes (dark x light)

## References
* [Efficient Encrypted UEFI-Booting Arch Installation](https://gist.github.com/HardenedArray/31915e3d73a4ae45adc0efa9ba458b07) on Github
* [First rice on my super old MacBook Air!](https://www.reddit.com/r/unixporn/comments/9y9w0r/sway_first_rice_on_my_super_old_macbook_air/) on Reddit
* [Archlinux Install – UEFI+LVM+LUKS+SystemdBoot](https://www.thelinuxsect.com/?p=36)