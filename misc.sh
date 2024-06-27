#!/usr/bin/bash

################################################
##### Swapfile
################################################

# References:
# https://wiki.archlinux.org/title/swap#Swap_file
# https://wiki.archlinux.org/title/swap#Swappiness
# https://wiki.archlinux.org/title/Improving_performance#zram_or_zswap
# https://wiki.gentoo.org/wiki/Zram
# https://www.dwarmstrong.org/zram-swap/
# https://www.reddit.com/r/Fedora/comments/mzun99/new_zram_tuning_benchmarks/

# Create swap file
dd if=/dev/zero of=/swapfile bs=1M count=8k status=progress

# Set swapfile permissions
chmod 0600 /swapfile

# Format swapfile to swap
mkswap -U clear /swapfile

# Activate swap file
swapon /swapfile

# Add swapfile to fstab configuration
tee -a /etc/fstab << EOF
# swapfile
/swapfile none swap defaults 0 0
EOF

# Set swappiness
echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf

# Set vfs cache pressure
echo 'vm.vfs_cache_pressure=50' > /etc/sysctl.d/99-vfs-cache-pressure.conf

################################################
##### ffmpeg-full (AUR)
################################################

# References:
# https://wiki.archlinux.org/title/FFmpeg#Installation

# Install dependencies
pacman -S --noconfirm tesseract-data-eng tesseract

# Install ffmpeg
if lspci | grep "VGA" | grep "Intel" > /dev/null; then
    pacman -S --noconfirm vpl-gpu-rt
    pacman -S --noconfirm ffmpeg
elif lspci | grep "VGA" | grep "AMD" > /dev/null; then
    sudo -u ${NEW_USER} paru -S --noconfirm ffmpeg-amd-full
fi

################################################
##### Plasma UI / UX changes
################################################

# Disable splash screen
sudo -u ${NEW_USER} kwriteconfig6 --file ksplashrc --group KSplash --key Engine "none"
sudo -u ${NEW_USER} kwriteconfig6 --file ksplashrc --group KSplash --key Theme "none"

# Replace plasmashell
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group "plasmashell.desktop" --key "_k_friendly_name" "plasmashell --replace"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group "plasmashell.desktop" --key "_launch" "Ctrl+Alt+Del,none,plasmashell --replace"

# Configure konsole
sudo -u ${NEW_USER} kwriteconfig6 --file konsolerc --group "KonsoleWindow" --key "RememberWindowSize" --type bool false
sudo -u ${NEW_USER} kwriteconfig6 --file konsolerc --group "MainWindow" --key "MenuBar" "Disabled"

################################################
##### Plasma UI / UX changes
################################################

# Import Plasma color schemes
mkdir -p /home/${NEW_USER}/.local/share/color-schemes
curl -O --output-dir /home/${NEW_USER}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/colors/Aseprite.colors
curl -O --output-dir /home/${NEW_USER}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/colors/Blender.colors
curl -O --output-dir /home/${NEW_USER}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/colors/DiscordDark.colors
curl -O --output-dir /home/${NEW_USER}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/colors/Gimp.colors
curl -O --output-dir /home/${NEW_USER}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/colors/Godot.colors
curl -O --output-dir /home/${NEW_USER}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/colors/HeroicGamesLauncher.colors
curl -O --output-dir /home/${NEW_USER}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/colors/Insomnia.colors
curl -O --output-dir /home/${NEW_USER}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/colors/ObsidianDark.colors
curl -O --output-dir /home/${NEW_USER}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/colors/SlackAubergineLightcolors.colors
curl -O --output-dir /home/${NEW_USER}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/colors/Spotify.colors
curl -O --output-dir /home/${NEW_USER}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/colors/VSCodeDarkModern.colors
curl -O --output-dir /home/${NEW_USER}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/colors/Konsole.colors

# Window decorations
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 1 --key Description "Application settings for vscode"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 1 --key decocolor "VSCodeDarkModern"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 1 --key wmclass "code"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 1 --key wmclasscomplete --type bool true
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 1 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 2 --key Description "Application settings for blender"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 2 --key decocolor "Blender"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 2 --key decocolorrule 2
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 2 --key wmclass "\sblender"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 2 --key wmclasscomplete --type bool true
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 2 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 3 --key Description "Application settings for gimp"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 3 --key decocolor "Gimp"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 3 --key decocolorrule 2
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 3 --key wmclass "gimp"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 3 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 3 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 4 --key Description "Application settings for godot"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 4 --key decocolor "Godot"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 4 --key decocolorrule 2
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 4 --key wmclass "godot_editor godot"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 4 --key wmclasscomplete --type bool true
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 4 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 4 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 5 --key Description "Application settings for discord"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 5 --key decocolor "DiscordDark"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 5 --key decocolorrule 2
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 5 --key wmclass "discord"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 5 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 5 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 6 --key Description "Application settings for insomnia"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 6 --key decocolor "Insomnia"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 6 --key decocolorrule 2
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 6 --key wmclass "insomnia"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 6 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 6 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 7 --key Description "Application settings for heroic"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 7 --key decocolor "HeroicGamesLauncher"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 7 --key decocolorrule 2
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 7 --key wmclass "heroic"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 7 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 7 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 8 --key Description "Application settings for spotify"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 8 --key decocolor "Spotify"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 8 --key decocolorrule 2
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 8 --key wmclass "spotify"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 8 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 8 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 9 --key Description "Application settings for obsidian"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 9 --key decocolor "ObsidianDark"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 9 --key decocolorrule 2
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 9 --key wmclass "obsidian"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 9 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 9 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 10 --key Description "Application settings for slack"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 10 --key decocolor "SlackAubergineLight"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 10 --key decocolorrule 2
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 10 --key wmclass "slack"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 10 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 10 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 11 --key Description "Application settings for konsole"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 11 --key decocolor "Konsole"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 11 --key wmclass "konsole org.kde.konsole"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 11 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 11 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 12 --key Description "Application settings for Aseprite"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 12 --key decocolor "Aseprite"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 12 --key wmclass "aseprite"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 12 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group 12 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group General --key count 12
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group General --key rules "1,2,3,4,5,6,7,8,9,10,11,12"

################################################
##### Konsole
################################################

# Create Konsole configs directory
mkdir -p /home/${NEW_USER}/.local/share/konsole

# Apply Konsole configurations
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/konsole/konsole_breeze_modern_dark.css -o /home/${NEW_USER}/.local/share/konsole/konsole_breeze_modern_dark.css

tee /home/${NEW_USER}/.config/konsolerc << EOF
MenuBar=Disabled

[Desktop Entry]
DefaultProfile=custom.profile

[KonsoleWindow]
RememberWindowSize=false

[TabBar]
TabBarUseUserStyleSheet=true
TabBarUserStyleSheetFile=file:///home/${NEW_USER}/.local/share/konsole/konsole_breeze_modern_dark.css
EOF

# Import Konsole custom profile
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/konsole/custom.profile -o /home/${NEW_USER}/.local/share/konsole/custom.profile

# Import Konsole custom color scheme
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/konsole/Breeze_Dark_Modern.colorscheme -o /home/${NEW_USER}/.local/share/konsole/Breeze_Dark_Modern.colorscheme

################################################
##### Sunshine (Flatpak) - untested
################################################

# References:
# https://github.com/LizardByte/Sunshine/blob/master/packaging/linux/flatpak/scripts/additional-install.sh
# https://github.com/LizardByte/Sunshine/blob/master/packaging/linux/sunshine.service.in
# https://github.com/LizardByte/Sunshine/blob/master/packaging/linux/flatpak/sunshine_kms.desktop
# https://docs.lizardbyte.dev/projects/sunshine/en/latest/about/setup.html#install
# https://docs.lizardbyte.dev/projects/sunshine/en/latest/about/advanced_usage.html#port

# Download Sunshine
curl https://github.com/LizardByte/Sunshine/releases/latest/download/sunshine_x86_64.flatpak -L -O

# Install Sunshine
flatpak install -y sunshine_x86_64.flatpak

# Remove Sunshine flatpak
rm -f sunshine_x86_64.flatpak

# Sunshine udev rules
tee /etc/udev/rules.d/60-sunshine.rules << 'EOF'
KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"
EOF
udevadm control --reload-rules
udevadm trigger
modprobe uinput

# Configure Sunshine systemd service
# tee /home/${NEW_USER}/.config/systemd/user/sunshine.service << 'EOF'
# [Unit]
# Description=Sunshine self-hosted game stream host for Moonlight.
# StartLimitIntervalSec=500
# StartLimitBurst=5
# PartOf=graphical-session.target
# Wants=xdg-desktop-autostart.target
# After=xdg-desktop-autostart.target

# [Service]
# ExecStart=/usr/bin/flatpak run dev.lizardbyte.sunshine
# ExecStop=/usr/bin/flatpak kill dev.lizardbyte.sunshine
# Restart=on-failure
# RestartSec=5s

# [Install]
# WantedBy=xdg-desktop-autostart.target
# EOF

# sudo -u ${NEW_USER} systemctl --user enable sunshine

# Create Sunshine shortcut
tee /home/${NEW_USER}/.local/share/applications/sunshine_kms.desktop << EOF
[Desktop Entry]
Name=Sunshine (KMS)
Exec=sudo -i PULSE_SERVER=unix:$(pactl info | awk '/Server String/{print$3}') flatpak run dev.lizardbyte.sunshine
Terminal=true
Type=Application
NoDisplay=true
EOF

# Allow Sunshine in firewall
firewall-cmd --permanent --add-port=48010/tcp
firewall-cmd --permanent --add-port=47998/udp
firewall-cmd --permanent --add-port=47999/udp
firewall-cmd --permanent --add-port=48000/udp

################################################
##### AppArmor
################################################

# References:
# https://wiki.archlinux.org/title/AppArmor
# https://wiki.archlinux.org/title/Audit_framework
# https://github.com/roddhjav/apparmor.d

# Install AppArmor
pacman -S --noconfirm apparmor

# Enable AppArmor service
systemctl enable --now apparmor.service

# Enable AppArmor as default security model
sed -i "s|=system|& lsm=landlock,lockdown,yama,integrity,apparmor,bpf|" /boot/loader/entries/arch.conf
sed -i "s|=system|& lsm=landlock,lockdown,yama,integrity,apparmor,bpf|" /boot/loader/entries/arch-lts.conf

# Enable caching AppArmor profiles
sed -i "s|^#write-cache|write-cache|g" /etc/apparmor/parser.conf
sed -i "s|^#Optimize=compress-fast|Optimize=compress-fast|g" /etc/apparmor/parser.conf

# Install and enable Audit Framework
pacman -S --noconfirm audit

systemctl enable auditd.service

# Allow user to read audit logs and get desktop notification on DENIED actions
groupadd -r audit

gpasswd -a ${NEW_USER} audit

sed -i "s|^log_group.*|log_group = audit|g" /etc/audit/auditd.conf

pacman -S --noconfirm python-notify2 python-psutil

mkdir -p /home/${NEW_USER}/.config/autostart

tee /home/${NEW_USER}/.config/autostart/apparmor-notify.desktop << EOF
[Desktop Entry]
Type=Application
Name=AppArmor Notify
Comment=Receive on screen notifications of AppArmor denials
TryExec=aa-notify
Exec=aa-notify -p -s 1 -w 60 -f /var/log/audit/audit.log
StartupNotify=false
NoDisplay=true
EOF

# Install additional AppArmor profiles
sudo -u ${NEW_USER} paru -S --noconfirm apparmor.d-git

################################################
##### Node.js
################################################

# References:
# https://github.com/nvm-sh/nvm#manual-install

# Install NVM
sudo -u ${NEW_USER} paru -S --noconfirm nvm

# Source NVM permanently
tee /home/${NEW_USER}/.zshrc.d/nvm << 'EOF'
# Source NVM
source /usr/share/nvm/init-nvm.sh
EOF

# Node updater
tee /home/${NEW_USER}/.local/bin/update-node << 'EOF'
#!/usr/bin/bash

# Source NVM
source /usr/share/nvm/init-nvm.sh

# Update node and npm
nvm install --lts
nvm install-latest-npm
EOF

chmod +x /home/${NEW_USER}/.local/bin/update-node

# Add node updater to updater function
sed -i '2 i \ ' /home/${NEW_USER}/.zshrc.d/update-all
sed -i '2 i \ \ update-node' /home/${NEW_USER}/.zshrc.d/update-all
sed -i '2 i \ \ # Update Node' /home/${NEW_USER}/.zshrc.d/update-all

# Source NVM temporarily
source /usr/share/nvm/init-nvm.sh

# Install Node LTS and latest supported NPM version
sudo -u ${NEW_USER} nvm install --lts
sudo -u ${NEW_USER} nvm install-latest-npm

################################################
##### ALVR (Flatpak)
################################################

# References:
# https://github.com/alvr-org/ALVR/wiki/Flatpak

# Download ALVR
curl https://github.com/alvr-org/ALVR/releases/latest/download/com.valvesoftware.Steam.Utility.alvr.flatpak -L -O

# Install ALVR
flatpak install -y --bundle com.valvesoftware.Steam.Utility.alvr.flatpak

# Remove ALVR flatpak
rm -f com.valvesoftware.Steam.Utility.alvr.flatpak

# Allow ALVR in firewall
firewall-cmd --zone=block --add-service=alvr
firewall-cmd --zone=trusted --add-service=alvr

firewall-cmd --permanent --zone=block --add-service=alvr
firewall-cmd --permanent --zone=trusted --add-service=alvr

# Create ALVR dashboard alias
tee /home/${NEW_USER}/.zshrc.d/alvr << 'EOF'
alias alvr="flatpak run --command=alvr_dashboard com.valvesoftware.Steam"
EOF

# Create ALVR desktop shortcut
curl https://raw.githubusercontent.com/alvr-org/ALVR/master/alvr/xtask/flatpak/com.valvesoftware.Steam.Utility.alvr.desktop -o /home/${NEW_USER}/.local/share/applications/com.valvesoftware.Steam.Utility.alvr.desktop

################################################
##### ALVR (native)
################################################

# References:
# https://github.com/alvr-org/ALVR/blob/master/alvr/xtask/flatpak/com.valvesoftware.Steam.Utility.alvr.desktop
# https://github.com/alvr-org/ALVR/wiki/Installation-guide#portable-targz

# Download ALVR
curl https://github.com/alvr-org/ALVR/releases/latest/download/alvr_streamer_linux.tar.gz -L -O

# Extract ALVR
tar -xzf alvr_streamer_linux.tar.gz
mv alvr_streamer_linux /home/${NEW_USER}/.alvr

# Cleanup ALVR.tar.gz
rm -f alvr_streamer_linux.tar.gz

# Create ALVR shortcut
tee /home/${NEW_USER}/.local/share/applications/alvr.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=ALVR
GenericName=Game
Comment=ALVR is an open source remote VR display which allows playing SteamVR games on a standalone headset such as Gear VR or Oculus Go/Quest.
Exec=/home/${NEW_USER}/.alvr/bin/alvr_dashboard
Icon=alvr
Categories=Game;
StartupNotify=true
PrefersNonDefaultGPU=true
X-KDE-RunOnDiscreteGpu=true
StartupWMClass=ALVR
EOF

# Allow ALVR in firewall
firewall-cmd --zone=block --add-service=alvr
firewall-cmd --zone=trusted --add-service=alvr

firewall-cmd --permanent --zone=block --add-service=alvr
firewall-cmd --permanent --zone=trusted --add-service=alvr

################################################
##### homed
################################################

# https://wiki.archlinux.org/title/Systemd-homed
# https://www.freedesktop.org/software/systemd/man/latest/homectl.html

# Enable systemd-homed service
systemctl enable --now systemd-homed.service

# Create user record
# https://systemd.io/USER_RECORD/
tee /root/user_record << EOF
{
    "userName" : "${NEW_USER}",
    "enforcePasswordPolicy" : false,
    "secret" : {
        "password" : [
            "${NEW_USER_PASSWORD}"
        ]
    },
    "privileged" : {
        "hashedPassword" : [
            "$(echo "${NEW_USER_PASSWORD}" | mkpasswd --method=SHA-512 --stdin)"
        ]
    },
    "shell" : "/usr/bin/zsh",
    "storage": "luks",
    "memberOf" : [
        "${NEW_USER}",
        "wheel"
    ]
}
EOF

# Create user with provided user record
homectl create --identity=/root/user_record

# Remove user record
rm -f /root/user_record

# Add user to libvirt group
homectl update ${NEW_USER} -G libvirt

################################################
##### Steam (Flatpak)
################################################

# Install Steam
flatpak install -y flathub com.valvesoftware.Steam

# Create directory for Steam games
mkdir -p /home/${NEW_USER}/games/steam

# Import Flatpak overrides
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.valvesoftware.Steam -o /home/${NEW_USER}/.local/share/flatpak/overrides/com.valvesoftware.Steam

# Steam controllers udev rules
curl -sSL https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-input.rules -o /etc/udev/rules.d/60-steam-input.rules
udevadm control --reload-rules

# Configure MangoHud for Steam
mkdir -p /home/${NEW_USER}/.var/app/com.valvesoftware.Steam/config/MangoHud
tee /home/${NEW_USER}/.var/app/com.valvesoftware.Steam/config/MangoHud/MangoHud.conf << EOF
legacy_layout=0
horizontal
gpu_stats
cpu_stats
ram
fps
frametime=0
hud_no_margin
table_columns=14
frame_timing=1
engine_version
vulkan_driver
EOF

################################################
##### 32-bit packages + native steam/heroic
################################################

# Enable multilib repository
tee -a /etc/pacman.conf << EOF

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF

# Install 32-bit packages
if lspci | grep "VGA" | grep "Intel" > /dev/null; then
    pacman -S --noconfirm lib32-vulkan-intel
elif lspci | grep "VGA" | grep "AMD" > /dev/null; then
    pacman -S --noconfirm lib32-vulkan-radeon
fi

pacman -S --noconfirm lib32-mesa

# Install Gamemode
pacman -S --noconfirm gamemode lib32-gamemode

# Install Gamescope
pacman -S --noconfirm gamescope

# Install MangoHud
pacman -S --noconfirm mangohud lib32-mangohud

# Configure MangoHud
# https://wiki.archlinux.org/title/MangoHud
mkdir -p /home/${NEW_USER}/.config/MangoHud

tee /home/${NEW_USER}/.config/MangoHud/MangoHud.conf << EOF
legacy_layout=0
horizontal
gpu_stats
cpu_stats
ram
fps
frametime=0
hud_no_margin
table_columns=14
frame_timing=1
engine_version
vulkan_driver
EOF

# Install Steam
pacman -S --noconfirm steam
pacman -Rs --noconfirm lib32-amdvlk

# Steam controllers udev rules
curl -sSL https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-input.rules -o /etc/udev/rules.d/60-steam-input.rules
udevadm control --reload-rules

# Install Heroic Games Launcher
sudo -u ${NEW_USER} paru -S --noconfirm heroic-games-launcher-bin

################################################
##### Firefox (native)
################################################

# References:
# https://wiki.archlinux.org/title/Firefox
# https://github.com/pyllyukko/user.js/blob/master/user.js

# Install Firefox
pacman -S --noconfirm firefox

# Set Firefox as default browser and handler for http/s
sudo -u ${NEW_USER} xdg-settings set default-web-browser firefox.desktop
sudo -u ${NEW_USER} xdg-mime default firefox.desktop x-scheme-handler/http
sudo -u ${NEW_USER} xdg-mime default firefox.desktop x-scheme-handler/https

# Run Firefox natively under Wayland
tee -a /home/${NEW_USER}/.zshenv << EOF

# Firefox
export MOZ_ENABLE_WAYLAND=1
EOF

# Temporarily open firefox to create profile folder
sudo -u ${NEW_USER} timeout 5 firefox --headless

# Set Firefox profile path
export FIREFOX_PROFILE_PATH=$(find /home/${NEW_USER}/.mozilla/firefox -type d -name "*.default-release")

# Import extensions
mkdir -p ${FIREFOX_PROFILE_PATH}/extensions
curl https://addons.mozilla.org/firefox/downloads/file/4003969/ublock_origin-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/uBlock0@raymondhill.net.xpi
curl https://addons.mozilla.org/firefox/downloads/file/4018008/bitwarden_password_manager-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/{446900e4-71c2-419f-a6a7-df9c091e268b}.xpi
curl https://addons.mozilla.org/firefox/downloads/file/3998783/floccus-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/floccus@handmadeideas.org.xpi
curl https://addons.mozilla.org/firefox/downloads/file/3932862/multi_account_containers-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/@testpilot-containers.xpi

# Import Firefox configs
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/firefox/user.js -o ${FIREFOX_PROFILE_PATH}/user.js

################################################
##### OpenSnitch
################################################

# Install OpenSnitch
pacman -S --noconfirm opensnitch

# Enable OpenSnitch
systemctl enable opensnitchd.service

# Autostart OpenSnitch UI
ln -s /usr/share/applications/opensnitch_ui.desktop /home/${NEW_USER}/.config/autostart/opensnitch_ui.desktop

# Import configs
mkdir -p /etc/opensnitchd
curl -O --output-dir /etc/opensnitchd https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/opensnitch/default-config.json

# Import rules
mkdir -p /etc/opensnitchd/rules

RULES=('bitwarden' 'chromium' 'curl' 'discord' 'dockerd' 'firefox' 'flatpak' 'fwupdmgr' 'git-remote-http' 'insomnia' 'networkmanager' 'obsidian' 'pacman' 'paru' 'plasmashell' 'ssh' 'syncthing' 'systemd-timesyncd' 'visual-studio-code' 'wireguard')
for RULE in "${RULES[@]}"
do
    curl -O --output-dir /etc/opensnitchd/rules https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/opensnitch/rules/${RULE}.json
done

################################################
##### Gnome Shell Extensions
################################################

# AppIndicator and KStatusNotifierItem Support
# https://extensions.gnome.org/extension/615/appindicator-support/
pacman -S --noconfirm libappindicator-gtk3
curl -sSL https://extensions.gnome.org/extension-data/appindicatorsupportrgcjonas.gmail.com.v56.shell-extension.zip -o shell-extension.zip
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions/appindicatorsupportrgcjonas.gmail.com
unzip shell-extension.zip -d /home/${NEW_USER}/.local/share/gnome-shell/extensions/appindicatorsupportrgcjonas.gmail.com
rm -f shell-extension.zip

# GSConnect
# https://extensions.gnome.org/extension/1319/gsconnect/
pacman -S --noconfirm openssl
curl -sSL https://extensions.gnome.org/extension-data/gsconnectandyholmes.github.io.v55.shell-extension.zip -o shell-extension.zip
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions/gsconnect@andyholmes.github.io
unzip shell-extension.zip -d /home/${NEW_USER}/.local/share/gnome-shell/extensions/gsconnect@andyholmes.github.io
rm -f shell-extension.zip

# Legacy (GTK3) Theme Scheme Auto Switcher
# https://extensions.gnome.org/extension/4998/legacy-gtk3-theme-scheme-auto-switcher/
curl -sSL https://extensions.gnome.org/extension-data/legacyschemeautoswitcherjoshimukul29.gmail.com.v7.shell-extension.zip -o shell-extension.zip
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions/legacyschemeautoswitcher@joshimukul29.gmail.com
unzip shell-extension.zip -d /home/${NEW_USER}/.local/share/gnome-shell/extensions/legacyschemeautoswitcher@joshimukul29.gmail.com
rm -f shell-extension.zip

################################################
##### Wayland configurations
################################################

# References:
# https://wiki.archlinux.org/title/Wayland#Electron
# https://wiki.archlinux.org/title/wayland#XWayland

# Run Electron applications natively under Wayland
tee /home/${NEW_USER}/.config/electron-flags.conf << EOF
--enable-features=WaylandWindowDecorations
--ozone-platform-hint=auto
EOF

# Run VSCode under Wayland
ln -s /home/${NEW_USER}/.config/electron-flags.conf /home/${NEW_USER}/.config/code-flags.conf

################################################
##### Podman
################################################

# References:
# https://wiki.archlinux.org/title/Podman
# https://wiki.archlinux.org/title/Buildah
# https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md

# Install Podman and dependencies
pacman -S --noconfirm podman passt netavark aardvark-dns

# Install Buildah
pacman -S --noconfirm buildah

# Enable kernel.unprivileged_userns_clone
echo 'kernel.unprivileged_userns_clone=1' > /etc/sysctl.d/99-unprivileged-userns-clone.conf

# Enable unprivileged ping
echo 'net.ipv4.ping_group_range=0 165535' > /etc/sysctl.d/99-unprivileged-ping.conf

# Create docker/podman alias
tee /home/${NEW_USER}/.zshrc.d/podman << EOF
alias docker=podman
EOF

# Re-enable unqualified search registries
tee -a /etc/containers/registries.conf.d/00-unqualified-search-registries.conf << EOF
unqualified-search-registries = ["docker.io"]
EOF

tee -a /etc/containers/registries.conf.d/01-registries.conf << EOF
[[registry]]
location = "docker.io"
EOF

# Install Podman desktop
flatpak install -y flathub io.podman_desktop.PodmanDesktop

# Install Pods
flatpak install -y flathub com.github.marhkb.Pods

################################################
##### Gnome - Qt theming
################################################

# https://github.com/GabePoel/KvLibadwaita
# https://github.com/tsujan/Kvantum/blob/master/Kvantum/doc/Theme-Config

# Qt
pacman -S --noconfirm kvantum
sudo -u ${NEW_USER} paru -S --noconfirm kvantum-theme-libadwaita-git
mkdir -p /home/${NEW_USER}/Kvantum
echo 'theme=KvLibadwaita' >> /home/${NEW_USER}/Kvantum/kvantum.kvconfig
tee -a /etc/environment << EOF

# Qt
QT_QPA_PLATFORM=wayland
QT_STYLE_OVERRIDE=kvantum
XCURSOR_THEME=Adwaita
XCURSOR_SIZE=24
EOF

################################################
##### Hashicorp tools
################################################

# Install HashiCorp tools and vscode extensions
pacman -S --noconfirm terraform packer
sudo -u ${NEW_USER} xvfb-run code --install-extension HashiCorp.terraform
sudo -u ${NEW_USER} xvfb-run code --install-extension HashiCorp.HCL

################################################
##### Other apps
################################################

# Install Open Lens
flatpak install -y flathub dev.k8slens.OpenLens
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/dev.k8slens.OpenLens -o /home/${NEW_USER}/.local/share/flatpak/overrides/dev.k8slens.OpenLens

# Install Obsidian
flatpak install -y flathub md.obsidian.Obsidian
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/md.obsidian.Obsidian -o /home/${NEW_USER}/.local/share/flatpak/overrides/md.obsidian.Obsidian