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

| Name                                                 | Type  | Mountpoint |
| ---------------------------------------------------- | :---: | :--------: |
| nvme0n1                                              | disk  |            |
| ├─nvme0n1p1                                          | part  |   /boot    |
| ├─nvme0n1p2                                          | part  |            |
| &nbsp;&nbsp;&nbsp;└─cryptlvm                         | crypt |            |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;├─vg0-swap |  lvm  |   [SWAP]   |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;└─vg0-root |  lvm  |     /      |

## Post install script

- Gnome / KDE / Sway / i3 (separate scripts)
- PipeWire instead of PulseAudio
- UFW (deny incoming, allow outgoing)
- Automatic login
- Fonts
- paru (AUR helper)
- Plymouth
- Flatpak support
- Syncthing
- Browsers:
  - Firefox (see below: MISC - Firefox required configs for VA-API support)
  - Chrome: via Flatpak, with hardware acceleration enabled
  - Chromium: via Flatpak, with hardware acceleration enabled

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
10. `wget https://raw.githubusercontent.com/gjpin/arch-linux/master/2_gnome.sh` or `2_plasma.sh` or `2_sway.sh`
11. Run the script: `./2_gnome.sh` or `./2_plasma.sh` or `./2_sway.sh`

## Misc guides

### Firefox required configs for VA-API support

- Run `flatpak --user override --socket=wayland --env=MOZ_WEBRENDER=1 --env=MOZ_ENABLE_WAYLAND=1 --env=GTK_USE_PORTAL=1 org.mozilla.firefox`
- At about:config set `gfx.webrender.enabled`, `media.ffmpeg.vaapi.enabled` `widget.wayland-dmabuf-vaapi.enabled` to true and `media.ffvpx.enabled` to false and then restart browser
  - Read original blog post [here](https://mastransky.wordpress.com/2020/06/03/firefox-on-fedora-finally-gets-va-api-on-wayland/)
  - Note: base script already sets the required environment variables. Only changing these 2 configs suffices

### How to install Paru (AUR helper)

```
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
makepkg -si --noconfirm
cd ..
rm -rf paru-bin
```

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

### How to chroot

```
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
cryptsetup luksOpen /dev/nvme0n1p2 cryptlvm
mount /dev/vg0/root /mnt
arch-chroot /mnt
```

### How to install Firefox Gnome theme

```
echo "Installing Firefox Flatpak Gnome theme"
git clone https://github.com/rafaelmardojai/firefox-gnome-theme/ && cd firefox-gnome-theme
./scripts/install.sh -f ~/.var/app/org.mozilla.firefox/.mozilla/firefox
rm -rf ~/firefox-gnome-theme
```

### How to install Lutris and Steam (Flatpak)

```
# Sources:
# https://gitlab.com/freedesktop-sdk/freedesktop-sdk/-/wikis/Mesa-git
# https://github.com/GloriousEggroll/proton-ge-custom#flatpak
# https://github.com/flathub/net.lutris.Lutris

# Add Flatpak repos
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --user --if-not-exists flathub-beta https://flathub.org/beta-repo/flathub-beta.flatpakrepo
flatpak update --appstream

# Install mesa-git
flatpak install --user --assumeyes flathub-beta org.freedesktop.Platform.GL.mesa-git//20.08 org.freedesktop.Platform.GL32.mesa-git//20.08

# Install Lutris
flatpak install --user --assumeyes flathub-beta net.lutris.Lutris//beta
flatpak install --user --assumeyes flathub org.gnome.Platform.Compat.i386 org.freedesktop.Platform.GL32.default org.freedesktop.Platform.GL.default

# Give Lutris Flatpak access to external drive
flatpak override --user --filesystem=/mnt/data/games/lutris net.lutris.Lutris

# Install Steam
flatpak install --user --assumeyes flathub com.valvesoftware.Steam
flatpak install --user --assumeyes com.valvesoftware.Steam.CompatibilityTool.Proton

# Give Steam Flatpak access to external drive
flatpak override --user --filesystem=/mnt/data/games/steam com.valvesoftware.Steam

# Make Steam and Lutris Flatpak use mesa-git
sed -i "s,Exec=,Exec=env FLATPAK_GL_DRIVERS=mesa-git ," ~/.local/share/flatpak/exports/share/applications/com.valvesoftware.Steam.desktop
sed -i "s,Exec=,Exec=env FLATPAK_GL_DRIVERS=mesa-git ," ~/.local/share/flatpak/exports/share/applications/net.lutris.Lutris.desktop

# Download latest release from GloriousEggroll/proton-ge-custom and move it to Steam Flatpak
curl -Ls https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | grep -wo "https.*tar.gz" | wget -qi -
mkdir -p ~/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d/
tar -xzf Proton-* -C ~/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d/

# To enable proton ge: https://github.com/GloriousEggroll/proton-ge-custom#enabling

# Allow Steam Link through the Firewall
sudo ufw allow from 192.168.1.0/24 to any port 27036:27037 proto tcp comment "steam link"
sudo ufw allow from 192.168.1.0/24 to any port 27031:27036 proto udp comment "steam link"
```
