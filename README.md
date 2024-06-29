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
10. Copy wireguard config to /etc/wireguard/wg0.conf
11. Import wireguard connection to networkmanager: `sudo nmcli con import type wireguard file /etc/wireguard/wg0.conf`
12. Set wg0's firewalld zone: `sudo firewall-cmd --permanent --zone=trusted --add-interface=wg0`
13. Re-configure p10k: `p10k configure`
14. Install and configure flatpaks:
```bash
# Install not working via arch-chroot
sudo flatpak install -y flathub com.usebruno.Bruno
sudo flatpak install -y flathub com.spotify.Client

# Not able to open Firefox via arch-chroot
export FIREFOX_PROFILE_PATH=$(find /home/${USER}/.var/app/org.mozilla.firefox/.mozilla/firefox -type d -name "*.default-release")
sudo mv /extensions/* ${FIREFOX_PROFILE_PATH}/extensions
sudo rm -rf /extensions
sudo mv /user.js ${FIREFOX_PROFILE_PATH}
sudo chown ${USER}:${USER} ${FIREFOX_PROFILE_PATH}/user.js
sudo chown -R ${USER}:${USER} ${FIREFOX_PROFILE_PATH}/extensions

# If Gnome
mkdir -p ${FIREFOX_PROFILE_PATH}/chrome
ln -s /usr/lib/firefox-gnome-theme ${FIREFOX_PROFILE_PATH}/chrome/firefox-gnome-theme
echo '@import "firefox-gnome-theme/userChrome.css"' > ${FIREFOX_PROFILE_PATH}/chrome/userChrome.css
echo '@import "firefox-gnome-theme/userContent.css"' > ${FIREFOX_PROFILE_PATH}/chrome/userContent.css
tee -a ${FIREFOX_PROFILE_PATH}/user.js << 'EOF'

// Firefox Gnome theme
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.uidensity", 0);
user_pref("svg.context-properties.content.enabled", true);
user_pref("browser.theme.dark-private-windows", false);
user_pref("widget.gtk.rounded-bottom-corners.enabled", true);
user_pref("gnomeTheme.activeTabContrast", true);
EOF

# If Plasma
tee -a ${FIREFOX_PROFILE_PATH}/user.js << 'EOF'

// Plasma integration
// https://wiki.archlinux.org/title/firefox#KDE_integration
user_pref("widget.use-xdg-desktop-portal.mime-handler", 1);
user_pref("widget.use-xdg-desktop-portal.file-picker", 1);
EOF
```

## Misc guides
### ALVR (native)
1. Install SteamVR, launch it once and close it

### ALVR (Flatpak)
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

### Sunshine - Steam flatpak
1. If using Steam flatpak, then in Sunshine's app.json use the following instead:
```
flatpak run com.valvesoftware.Steam -gamepadui
```

### How to chroot

```bash
cryptsetup luksOpen /dev/disk/by-partlabel/LUKS system
mount -t ext4 LABEL=system /mnt
mount /dev/nvme0n1p1 /mnt/boot
arch-chroot /mnt
```

### How to re-enroll keys in TPM2

```bash
sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1p2 OR /dev/md/ArchArray
sudo systemd-cryptenroll --tpm2-pcrs=0+1+7 --tpm2-device=auto /dev/nvme0n1p2 OR /dev/md/ArchArray
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

### Download and apply GTK themes with Gradience

```bash
# Download Breeze themes
sudo -u ${NEW_USER} flatpak run --command=gradience-cli com.github.GradienceTeam.Gradience download -n "Breeze Dark"
sudo -u ${NEW_USER} flatpak run --command=gradience-cli com.github.GradienceTeam.Gradience download -n "Breeze Light"

# Apply Breeze Dark theme
sudo -u ${NEW_USER} flatpak run --command=gradience-cli com.github.GradienceTeam.Gradience apply -n "Breeze Dark" --gtk "both"
```

## References
### sysctl
```bash
# References:
# https://github.com/CryoByte33/steam-deck-utilities/blob/main/docs/tweak-explanation.md
# https://wiki.cachyos.org/configuration/general_system_tweaks/
# https://gitlab.com/cscs/maxperfwiz/-/blob/master/maxperfwiz?ref_type=heads

# Disabling watchdog will speed up your boot and shutdown, because one less module is loaded. Additionally disabling watchdog timers increases performance and lowers power consumption.
kernel.nmi_watchdog=0

# In some cases, split lock mitigate can slow down performance in some applications and games. https://github.com/doitsujin/dxvk/issues/2938
kernel.split_lock_mitigate=0

# This feature proactively defragments memory when Linux detects "downtime".
# Note that compaction has a non-trivial system-wide impact as pages belonging to different processes are moved around, which could also lead to latency spikes in unsuspecting applications.
vm.compaction_proactiveness=0

# PLU configures how many times a process can try to get a lock on a page before "fair" behavior kicks in, and guarantees that process access to a page. https://www.phoronix.com/review/linux-59-fairness
vm.page_lock_unfairness=1

# total available memory that contains free pages and reclaimable pages, the number of pages at which a process which is generating disk writes will itself start writing out dirty data. Note the optimum percentage may change depending on amount of available memory. Values resulting in 100MB-600MB are ideal.
vm.dirty_bytes=419430400

# total available memory that contains free pages and reclaimable pages, the number of pages at which the background kernel flusher threads will start writing out dirty data.Note the optimum percentage may change depending on amount of available memory. Values resulting in 50MB-400MB are ideal.
vm.dirty_background_bytes=209715200

# Dirty expire centisecs tunable is used to define when dirty data is old enough to be eligible for writeout by the kernel flusher threads, expressed in 100'ths of a second. Data which has been dirty in-memory for longer than this interval will be written out next time a flusher thread wakes up.
vm.dirty_expire_centisecs=3000

# The kernel flusher threads will periodically wake up and write 'old' data out to disk.  This tunable expresses the interval between those wakeups, in 100'ths of a second.
vm.dirty_writeback_centisecs=1500
```