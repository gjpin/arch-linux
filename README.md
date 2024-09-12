# Arch Linux install scripts

WARNING: Running install.sh with delete all data in nvme0n1 and nvme1n1 (if using RAID0) without confirmation.

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

1. Disable secure boot and delete secure boot keys (automatically enters setup mode)
2. Boot into Arch Linux ISO
3. Connect to the internet. If using wifi, you can use `iwctl` to connect to a network:
   - scan for networks: `station wlan0 scan`
   - list available networks: `station wlan0 get-networks`
   - connect to a network: `station wlan0 connect SSID`
4. Update repos and install git: `pacman -Sy git`
5. (if previous step fails) Init and populate keyring: `pacman-key --init && pacman-key --populate`
6. Clone repo: `git clone https://github.com/gjpin/arch-linux.git`
7. Run script: `cd arch-linux && ./install.sh`
8. Reboot and enable secure boot
9. Enroll LUKS key in TPM2: `sudo systemd-cryptenroll --tpm2-pcrs=0+1+7 --tpm2-device=auto /dev/nvme0n1p2 OR /dev/md/ArchArray (if RAID0)`
10. Re-configure p10k: `p10k configure`
11. Install Flatpak and applications:
```
curl -LO https://raw.githubusercontent.com/gjpin/arch-linux/main/flatpak.sh
chmod +x flatpak.sh
./flatpak.sh
rm -f flatpak.sh
```

## Guides
See [HERE](https://github.com/gjpin/arch-linux/blob/main/GUIDES.md)

## References
See [HERE](https://github.com/gjpin/arch-linux/blob/main/REFERENCES.md)