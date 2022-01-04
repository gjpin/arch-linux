# Arch Linux install scripts

Note: These scripts are not meant to be another full-fledged Arch installer. They are made to fit my devices: Dell XPS 7390 and custom desktop build (Ryzen 3700X and RX 5700XT). In any case, as long as you don't use a Nvidia GPU, they should work fine.

## Install script

- LVM on LUKS
- LUKS2
- systemd-boot (with Pacman hook for automatic updates)
- systemd init hooks (instead of busybox)
- SSD Periodic TRIM
- Intel/AMD microcode
- Standard Kernel + LTS kernel as fallback
- Hibernate support
- NMI watchdog disabled
- Swappiness set to 20

### Requirements

- UEFI mode
- NVMe SSD
- TRIM compatible SSD
- CPU: Intel (Skylake or newer) / AMD
- GPU: AMDGPU - only if CPU vendor is AMD (this combination is hard-coded. For now, base script checks for CPU vendor and if it's AMD, then it'll also install required drivers for AMD GPU)

### Partitions

| Name                                                 | Type  | FS Type | Mountpoint |
| ---------------------------------------------------- | :---: | :-----: | :--------: |
| nvme0n1                                              | disk  |         |            |
| ├─nvme0n1p1                                          | part  |  FAT32  |   /boot    |
| ├─nvme0n1p2                                          | part  |         |            |
| &nbsp;&nbsp;&nbsp;└─cryptlvm                         | crypt |         |            |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├─vg0-swap |  lvm  |   Swap  |   [SWAP]   |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└─vg0-root |  lvm  |   EXT4  |     /      |

## Post install script

- KDE or Gnome
- PipeWire
- firewalld
- Automatic login
- Fonts
- paru (AUR helper)
- Plymouth
- Flatpak
- Syncthing

## Installation guide

1. Download and boot into the latest [Arch Linux iso](https://www.archlinux.org/download/)
2. Connect to the internet. If using wifi, you can use `iwctl` to connect to a network:
   - scan for networks: `station wlan0 scan`
   - list available networks: `station wlan0 get-networks`
   - connect to a network: `station wlan0 connect SSID`
3. Give highest priority to the closest mirror to you on /etc/pacman.d/mirrorlist by moving it to the top
4. Sync repos: `pacman -Sy` and install wget `pacman -S wget`
5. `wget https://raw.githubusercontent.com/gjpin/arch-linux/master/1_install.sh`
6. Change the variables at the top of the file (lines 3 through 9)
   - continent_country must have the following format: Zone/SubZone . e.g. Europe/Berlin
   - run `timedatectl list-timezones` to see full list of zones and subzones
7. Run the script: `./1_install.sh`
8. Reboot into Arch Linux
9. Connect to wifi with `nmtui`
10. `wget https://raw.githubusercontent.com/gjpin/arch-linux/master/2_gnome.sh` or `2_plasma.sh`
11. Run the script: `./2_gnome.sh` or `./2_plasma.sh`

## Misc guides
### How to enable secure boot

1. `sudo pacman -S --noconfirm sbctl`
2. Confirm secure boot is disabled and delete existing keys in the bios (should automatically go into setup mode)
3. Confirm status (setup mode): `sudo sbctl status`
4. Create new keys: `sudo sbctl create-keys`
5. Enroll new keys: `sudo sbctl enroll-keys`
6. Confirm status (setup mode should now be disabled): `sudo sbctl status`
7. Confirm what needs to be signed: `sudo sbctl verify`
8. Sign with new keys:

- `sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI`
- `sudo sbctl sign -s /boot/EFI/systemd/systemd-bootx64.efi`
- `sudo sbctl sign -s /boot/vmlinuz-linux`
- `sudo sbctl sign -s /boot/vmlinuz-linux-lts`

9. Reboot and enable secure boot in the bios
10. Confirm status (secure boot enabled): `sudo sbctl status`
11. Setup hook to auto-sign on package changes:
```
sudo tee -a /etc/pacman.d/hooks/sbctl.hook << END
[Trigger]
Type = Path
Operation = Install
Operation = Upgrade
Operation = Remove
Target = boot/*
Target = efi/*
Target = usr/lib/modules/*/vmlinuz
Target = usr/lib/initcpio/*
Target = usr/lib/**/efi/*.efi*

[Action]
Description = Signing EFI binaries...
When = PostTransaction
Exec = /usr/bin/sbctl sign-all -g
END
```

### How to chroot

```
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
cryptsetup luksOpen /dev/nvme0n1p2 cryptlvm
mount /dev/vg0/root /mnt
arch-chroot /mnt
```

### Gaming
```
# Steam Flatpak
sudo flatpak install -y flathub com.valvesoftware.Steam
sudo flatpak override --filesystem=/mnt/data/games/steam com.valvesoftware.Steam

# Lutris Flatpak
sudo flatpak install flathub-beta net.lutris.Lutris//beta
sudo flatpak install -y flathub org.gnome.Platform.Compat.i386 org.freedesktop.Platform.GL32.default org.freedesktop.Platform.GL.default
sudo flatpak override --filesystem=/mnt/data/games/lutris net.lutris.Lutris

# Set primary monitor for xwayland applications/games
sudo pacman -S --noconfirm xorg-xrandr
xrandr --output XWAYLAND0 --primary
```