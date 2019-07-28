# Modern Arch Linux install scripts
![screenshot](https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/screenshot.png)

## Installation
* Increase cowspace partition so that git can be downloaded without before chroot: `mount -o remount,size=2G /run/archiso/cowspace`
* Install git: `pacman -Sy git`
* Clone repository: `git clone https://github.com/exah-io/minimal-arch-linux.git`
* Run install script: `bash minimal-arch-linux/1_arch_install.sh`

## Features and setup
### Install script
* LVM on LUKS
* LUKS2
* systemd-boot (with Pacman hook for automatic updates)
* Automatic login (with systemd)
* SSD Periodic TRIM
* Intel microcode
* Automatic sort of mirrors list by speed, synced within the last 12 hours and filtered by HTTPS protocol (Reflector with Pacman hook)

### Post install script
* UFW (deny incoming, allow outgoing)
* TLP (default settings)
* swaywm:
   * autostart on tty1
   * waybar: onclick pavucontrol (volume control) and nmtui (ncli network manager)
   * swayidle and swaylock: automatic sleep and lock
   * Alacritty terminal
   * rofi as application launcher
   * slurp and grim for screenshots
* zsh:
   * powerlevel9k theme
   * History
   * Load NVM on first invocation
   * ~~Force wayland for QT applications~~ disabled due to incompatibility with keepassxc
   * ~~Force wayland for GTK applications~~ disabled due to electron apps incompatibility (code oss)
* GTK theme and icons: Qogir
* Other applications: firefox, keepassxc, git, openssh, vim, alacritty, thunar (with USB automonting), NVM (with node.js LTS), tumbler, evince, gimp, inkscape, thunderbird, upower, htop, code oss, nnn

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
3. Clear all existing partitions (see MISC section below)
4. wget [1_arch_install.sh](https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/1_arch_install.sh)
5. Change the variables at the top of the file
   * continent_country must have the following format: Continent/City . e.g. Europe/Berlin
6. Enable the closest mirror to you on /etc/pacman.d/mirrorlist (move it to the top)
7. Make the script executable: chmod +x 1_arch_install.sh
8. Run the script: ./1_arch_install.sh
9. Reboot
10. wget [2_arch_post_install.sh](https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/2_arch_post_install.sh)
11. Make the script executable: chmod +x 2_arch_post_install.sh
12. Run the script: ./2_arch_post_install.sh

## MISC
### How to clear all partitions
```
gdisk /dev/nvme0n1
x
z
w
```

### How to disable VS Code online services
* Search for @tag:usesOnlineServices in VSCode settings and disable online services

### How to setup Github with SSH Key
```
git config --global user.email "github external email"
git config --global user.name "username"
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
copy SSH key and add to Github (eg. mousepad ~/.ssh/id_rsa.pub and copy content)
```

### How to chroot
```
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
cryptsetup luksOpen /dev/nvme0n1p2 cryptoVols
mount /dev/mapper/Arch-root /mnt
arch-chroot /mnt
```

### How to install yay
```
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
yes | makepkg -si
cd ..
rm -rf yay-bin
```

### References
* Ricing: [First rice on my super old MacBook Air!](https://www.reddit.com/r/unixporn/comments/9y9w0r/sway_first_rice_on_my_super_old_macbook_air/) on Reddit
