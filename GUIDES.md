# Table of Contents

- [Guides](#guides)
  - [Sunshine](#sunshine)
  - [ALVR](#alvr)
    - [Flatpak](#alvr-flatpak)
    - [Native](#alvr-native)
  - [How to chroot](#how-to-chroot)
  - [How to re-enroll keys in TPM2](#how-to-re-enroll-keys-in-tpm2)
  - [How to show systemd-boot menu](#how-to-show-systemd-boot-menu)
  - [How to repair EFI](#how-to-repair-efi)
  - [How to revert to a previous Flatpak commit](#how-to-revert-to-a-previous-flatpak-commit)
  - [How to use Gamescope + MangoHud in Steam](#how-to-use-gamescope--mangohud-in-steam)
- [Troubleshooting](#troubleshooting)
  - [Keyring issues](#keyring-issues)
- [System Configuration](#system-configuration)
  - [Auto-mount extra drive (drive in use)](#auto-mount-extra-drive-drive-in-use)
  - [Auto-mount extra drive (from scratch)](#auto-mount-extra-drive-from-scratch)
  - [Wake-on-LAN quirks](#wake-on-lan-quirks)
- [Customization](#customization)
  - [Download and apply GTK themes with Gradience](#download-and-apply-gtk-themes-with-gradience)

# Guides

## Sunshine
If using Steam native, then in Sunshine's app.json use the following instead:

```
steam-runtime -gamepadui
```

## ALVR
### Flatpak

1. Install SteamVR
2. Run:

```bash
sudo setcap CAP_SYS_NICE+eip ~/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher
```

3. Launch and close SteamVR
4. Open ALVR
5. In the ALVR Dashboard under All Settings (Advanced) > Audio, enable Game Audio and Microphone
6. In the same place under Microphone, click Expand and set Devices to custom. Enter `default` for the name for both Sink and Source
7. In the ALVR Dashboard, under All Settings (Advanced) > Connection, set the On connect script and On disconnect script to the absolute path of the script (relative to the Flatpak environment), i.e. `/home/$USER/.var/app/com.valvesoftware.Steam/audio-flatpak-setup.sh`
8. Restart Steam and ALVR

### Native

0. See more tips in the official ALVR wiki: [troubleshooting](https://github.com/alvr-org/ALVR/wiki/Linux-Troubleshooting) and [tweaks](https://github.com/alvr-org/ALVR/wiki/Settings-tutorial)
1. Install SteamVR, launch it once and close it
2. Add the following commandline option of SteamVR (SteamVR -> Manage/Right Click -> Properties -> General -> Launch Options):

```
~/.local/share/Steam/steamapps/common/SteamVR/bin/vrmonitor.sh %command%
```

3. Add workaround for non closable SteamVR window:

```bash
# References:
# https://github.com/ValveSoftware/SteamVR-for-Linux/issues/577#issuecomment-1872400869

sed -ri 's/("preload".*)true/\1false/g' ~/.steam/steam/steamapps/common/SteamVR/drivers/lighthouse/resources/webhelperoverlays.json
sed -ri 's/("preload".*)true/\1false/g' ~/.steam/steam/steamapps/common/SteamVR/resources/webhelperoverlays.json
```

4. Apply SteamVR patches (optional):

```bash
curl -s https://raw.githubusercontent.com/alvr-org/ALVR-Distrobox-Linux-Guide/main/patch_bindings_spam.sh | sh -s /home/zero/.steam/steam/steamapps/common/SteamVR
```

5. Change ALVR settings:

```bash
# References:
# https://github.com/alvr-org/ALVR/wiki/ALVR-in-distrobox

Presets:
- Preferred framerate: 90hz

Video:
- Bitrate: constant
   - 200mbps
- Preferred codec: AV1
- Foveated encoding: on
   - Center region width: 0.680 (increased 50% from default)
   - Center region height: 0.600 (increased 50% from default)
- Color correction: on
   - Sharpening: 1.00
- Maximum buffering: 1.50 frames
- Optimize game render latench: off
- Transcoding view resolution: absolute
   - Width: 2064
   - Height: 2208
- Emulated headset view resolution: absolute
   - Width: 2064
   - Height: 2208
- Preferred FPS: 90hz

Headset:
- Controllers: on
   - Emulation mode: Quest 3 Touch Plus

Connection:
- Stream protocol: TCP
```

6. Change SteamVR settings:

```bash
- Disable SteamVR Home
- Render Resolution: Custom - 100%
- Disable Advanced Supersample Filtering
- Set steamvr as openxr runtime
```

## How to chroot

```bash
cryptsetup luksOpen /dev/disk/by-partlabel/LUKS system
mount -t ext4 LABEL=system /mnt
mount /dev/nvme0n1p1 /mnt/boot
arch-chroot /mnt
```

## How to re-enroll keys in TPM2

```bash
sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/md/ArchArray OR /dev/nvme0n1p2
sudo systemd-cryptenroll --tpm2-pcrs=0+7 --tpm2-device=auto /dev/md/ArchArray OR /dev/nvme0n1p2
```

## How to show systemd-boot menu

```bash
Press 'space' during boot
```

## How to repair EFI

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

## How to use Gamescope + MangoHud in Steam

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

## Auto-mount extra drive (drive in use)

```bash
# Encrypt and open LUKS partition
sudo cryptsetup luksOpen /dev/disk/by-partlabel/LUKSDATA data

# Mount root device
sudo mkdir -p /data
sudo mount -t ext4 LABEL=data /data

# Auto-mount
sudo tee -a /etc/fstab << EOF

# data disk
/dev/mapper/data /data ext4 defaults 0 0
EOF

sudo tee -a /etc/crypttab << EOF

data UUID=$(sudo blkid -s UUID -o value /dev/nvme1n1p1) none
EOF

# Auto unlock
sudo systemd-cryptenroll --tpm2-device=auto /dev/nvme1n1p1
```

## Auto-mount extra drive (from scratch)

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

data UUID=$(sudo blkid -s UUID -o value /dev/nvme1n1p1) none
EOF

# Change ownership to user
sudo chown -R $USER:$USER /data

# Auto unlock
sudo systemd-cryptenroll --tpm2-pcrs=0+7 --tpm2-device=auto /dev/nvme1n1p1
```

## Wake-on-LAN quirks

```bash
# References:
# https://wiki.archlinux.org/title/Wake-on-LAN#Fix_by_Kernel_quirks

# If WoL has been enabled and the computer does not shutdown

# Add kernel boot parameters to enable quirks
tee /etc/cmdline.d/wol.conf << EOF
xhci_hcd.quirks=270336
EOF
```

## Download and apply GTK themes with Gradience

```bash
# Download Breeze themes
sudo -u ${NEW_USER} flatpak run --command=gradience-cli com.github.GradienceTeam.Gradience download -n "Breeze Dark"
sudo -u ${NEW_USER} flatpak run --command=gradience-cli com.github.GradienceTeam.Gradience download -n "Breeze Light"

# Apply Breeze Dark theme
sudo -u ${NEW_USER} flatpak run --command=gradience-cli com.github.GradienceTeam.Gradience apply -n "Breeze Dark" --gtk "both"
```