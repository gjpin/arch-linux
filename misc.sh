#!/usr/bin/bash

################################################
##### LazyVim
################################################

# Install LazyVim
# https://www.lazyvim.org/installation
git clone https://github.com/LazyVim/starter /home/${NEW_USER}/.config/nvim
rm -rf /home/${NEW_USER}/.config/nvim/.git

# Install arctic.nvim (Dark Modern) color scheme in neovim
# https://github.com/rockyzhang24/arctic.nvim/tree/v2
# https://www.lazyvim.org/plugins/colorscheme
tee /home/${NEW_USER}/.config/nvim/lua/plugins/colorscheme.lua << 'EOF'
return {
    {
        "gjpin/arctic.nvim",
        branch = "v2",
        dependencies = { "rktjmp/lush.nvim" }
    },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "arctic",
        }
    }
}
EOF

################################################
##### Firefox (native)
################################################

# References:
# https://github.com/rafaelmardojai/firefox-gnome-theme
# Theme is manually installed and not from AUR, since Firefox flatpak cannot access it

# Install Firefox
pacman -S --noconfirm firefox

# Set Firefox as default browser and handler for http/s
sudo -u ${NEW_USER} xdg-settings set default-web-browser firefox.desktop
sudo -u ${NEW_USER} xdg-mime default firefox.desktop x-scheme-handler/http
sudo -u ${NEW_USER} xdg-mime default firefox.desktop x-scheme-handler/https

# Temporarily open firefox to create profile
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

# Desktop environment specific configurations
if [ ${DESKTOP_ENVIRONMENT} = "gnome" ]; then
    # Firefox Gnome theme integration
    mkdir -p ${FIREFOX_PROFILE_PATH}/chrome
    git clone https://github.com/rafaelmardojai/firefox-gnome-theme.git ${FIREFOX_PROFILE_PATH}/chrome/firefox-gnome-theme
    echo '@import "firefox-gnome-theme/userChrome.css"' > ${FIREFOX_PROFILE_PATH}/chrome/userChrome.css
    echo '@import "firefox-gnome-theme/userContent.css"' > ${FIREFOX_PROFILE_PATH}/chrome/userContent.css
    curl -sSL https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/firefox/gnome.js >> ${FIREFOX_PROFILE_PATH}/user.js

    # Firefox theme updater
    tee -a /usr/local/bin/update-all << 'EOF'

################################################
##### Firefox
################################################

# Update Firefox theme
FIREFOX_PROFILE_PATH=$(realpath ${HOME}/.mozilla/firefox -type d -name "*.default-release")
git -C ${FIREFOX_PROFILE_PATH}/chrome/firefox-gnome-theme pull
EOF
elif [ ${DESKTOP_ENVIRONMENT} = "plasma" ]; then
    # Better KDE Plasma integration
    curl -sSL https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/firefox/plasma.js >> ${FIREFOX_PROFILE_PATH}/user.js
fi

################################################
##### Android
################################################

# Install all Android tools
sudo -u ${NEW_USER} paru -S --noconfirm \
    android-sdk \
    android-sdk-platform-tools \
    android-emulator \
    android-sdk-cmdline-tools-latest

################################################
##### Tailscale
################################################

# References:
# https://wiki.archlinux.org/title/Tailscale
# https://tailscale.com/download/linux/arch

# Install Tailscale
pacman -S --noconfirm tailscale

# Enable Tailscale service
systemctl enable --now tailscaled.service

# Set Tailscale's network zone
firewall-offline-cmd --zone=home --add-interface=tailscale0

################################################
##### Sunshine (native - to build)
################################################

# References:
# https://github.com/LizardByte/Sunshine
# https://docs.lizardbyte.dev/projects/sunshine/en/latest/
# https://docs.lizardbyte.dev/projects/sunshine/en/latest/about/advanced_usage.html#port

# Install sunshine
sudo -u ${NEW_USER} paru -S --noconfirm sunshine

# Import sunshine configurations
mkdir -p /home/${NEW_USER}/.config/sunshine

curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sunshine/sunshine.conf -o /home/${NEW_USER}/.config/sunshine/sunshine.conf

if [ ${DESKTOP_ENVIRONMENT} = "gnome" ]; then
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sunshine/apps-gnome.json -o /home/${NEW_USER}/.config/sunshine/apps.json
elif [ ${DESKTOP_ENVIRONMENT} = "plasma" ]; then
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sunshine/apps-plasma.json -o /home/${NEW_USER}/.config/sunshine/apps.json
fi

# Allow Sunshine through firewall
firewall-offline-cmd --zone=home --add-port=47984/tcp
firewall-offline-cmd --zone=home --add-port=47989/tcp
firewall-offline-cmd --zone=home --add-port=48010/tcp
firewall-offline-cmd --zone=home --add-port=47998/udp
firewall-offline-cmd --zone=home --add-port=47999/udp
firewall-offline-cmd --zone=home --add-port=48000/udp

# Launch Sunshine on session startup (systemd service is not working in Gnome Wayland)
cp /usr/share/applications/sunshine.desktop /home/${NEW_USER}/.config/autostart/sunshine.desktop

################################################
##### Fonts
################################################

# Enable stem darkening on all fonts
tee -a /etc/environment << EOF

# Enable stem darkening on all fonts
FREETYPE_PROPERTIES="cff:no-stem-darkening=0 autofitter:no-stem-darkening=0"
EOF

################################################
##### Power preferences
################################################

# Change CPU governor to Performance
echo governor='performance' >> /etc/default/cpupower

# Enable cpupower systemd service
systemctl enable cpupower.service

# Corectrl
if lspci | grep "VGA" | grep "AMD" > /dev/null; then
    # Install corectrl
    pacman -S --noconfirm corectrl

    # Launch CoreCtrl on session startup
    cp /usr/share/applications/org.corectrl.CoreCtrl.desktop /home/${NEW_USER}/.config/autostart/org.corectrl.CoreCtrl.desktop

    # Don't ask for user password
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/corectrl/90-corectrl.rules -o /etc/polkit-1/rules.d/90-corectrl.rules
    sed -i "s/your-user-group/${NEW_USER}/" /etc/polkit-1/rules.d/90-corectrl.rules

    # Import corectrl configs and profiles
    mkdir -p /home/${NEW_USER}/.config/corectrl/profiles
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/corectrl/corectrl.ini -o /home/${NEW_USER}/.config/corectrl/corectrl.ini
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/corectrl/profiles/_global_.ccpro -o /home/${NEW_USER}/.config/corectrl/profiles/_global_.ccpro
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/corectrl/profiles/alvr_dashboard.ccpro -o /home/${NEW_USER}/.config/corectrl/profiles/alvr_dashboard.ccpro
fi

################################################
##### GTK theming
################################################

# Install Gradience
flatpak install -y flathub com.github.GradienceTeam.Gradience

# Import Gradience Flatpak overrides
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.github.GradienceTeam.Gradience -o /home/${NEW_USER}/.local/share/flatpak/overrides/com.github.GradienceTeam.Gradience

################################################
##### WiVRn
################################################

# References:
# https://github.com/Meumeu/WiVRn
# https://wiki.archlinux.org/title/avahi

# Install WiVRn server
sudo -u ${NEW_USER} paru -S --noconfirm wivrn-server

# Allow WiVRn through firewall
firewall-offline-cmd --zone=block --add-rich-rule='rule family="ipv4" source address="10.100.100.0/24" port port="9757" protocol="tcp" accept log prefix="WiVRn TCP"'
firewall-offline-cmd --zone=block --add-rich-rule='rule family="ipv4" source address="10.100.100.0/24" port port="9757" protocol="udp" accept log prefix="WiVRn UDP"'

# Install Avahi
pacman -S --noconfirm avahi nss-mdns

# Allow Avahi through firewall
firewall-offline-cmd --zone=block --add-rich-rule='rule family="ipv4" source address="10.100.100.0/24" port port="5353" protocol="udp" accept log prefix="Avahi"'

################################################
##### Development (languages, LSP, neovim)
################################################

# Install rust with rustup
pacman -S --noconfirm rustup
sudo -u ${NEW_USER} rustup default stable

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
##### Sunshine (flatpak)
################################################

# References:
# https://github.com/LizardByte/Sunshine
# https://docs.lizardbyte.dev/projects/sunshine/en/latest/
# https://docs.lizardbyte.dev/projects/sunshine/en/latest/about/setup.html#install
# https://docs.lizardbyte.dev/projects/sunshine/en/latest/about/advanced_usage.html#port
# https://github.com/LizardByte/Sunshine/tree/master/packaging/linux/flatpak
# https://github.com/LizardByte/Sunshine/blob/master/packaging/linux/flatpak/scripts/additional-install.sh
# https://github.com/LizardByte/Sunshine/blob/master/packaging/linux/sunshine.service.in
# https://github.com/LizardByte/Sunshine/blob/master/packaging/linux/flatpak/sunshine_kms.desktop

# Download Sunshine flatpak
curl https://github.com/LizardByte/Sunshine/releases/latest/download/sunshine_x86_64.flatpak -L -O

# Install Sunshine
flatpak install -y sunshine_x86_64.flatpak

# Remove Sunshine flatpak
rm -f sunshine_x86_64.flatpak

# Sunshine udev rules
tee /etc/udev/rules.d/60-sunshine.rules << 'EOF'
KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"
EOF

# Configure systemd service
tee /home/${NEW_USER}/.config/systemd/user/sunshine.service << EOF
[Unit]
Description=Sunshine self-hosted game stream host for Moonlight
StartLimitIntervalSec=500
StartLimitBurst=5
PartOf=graphical-session.target
Wants=xdg-desktop-autostart.target
After=xdg-desktop-autostart.target

[Service]
Environment="PULSE_SERVER=unix:/run/user/$(id -u ${NEW_USER})/pulse/native"
ExecStart=/usr/bin/flatpak run dev.lizardbyte.sunshine
ExecStop=/usr/bin/flatpak kill dev.lizardbyte.sunshine
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=xdg-desktop-autostart.target
EOF

sudo -u ${NEW_USER} systemctl --user enable sunshine

# Create Sunshine shortcut
tee /home/${NEW_USER}/.local/share/applications/sunshine_kms.desktop << EOF
[Desktop Entry]
Name=Sunshine (KMS)
Exec=sudo -i PULSE_SERVER=unix:$(pactl info | awk '/Server String/{print$3}') flatpak run dev.lizardbyte.sunshine
Terminal=true
Type=Application
NoDisplay=true
EOF

# Configure Sunshine
mkdir -p /home/${NEW_USER}/.var/app/dev.lizardbyte.sunshine/config/sunshine
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sunshine/sunshine.conf -o /home/${NEW_USER}/.var/app/dev.lizardbyte.sunshine/config/sunshine/sunshine.conf

if [ ${DESKTOP_ENVIRONMENT} = "gnome" ]; then
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sunshine/apps-gnome.json -o /home/${NEW_USER}/.var/app/dev.lizardbyte.sunshine/config/sunshine/apps.json
elif [ ${DESKTOP_ENVIRONMENT} = "plasma" ]; then
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sunshine/apps-plasma.json -o /home/${NEW_USER}/.var/app/dev.lizardbyte.sunshine/config/sunshine/apps.json
fi

# Allow Sunshine through firewall
firewall-offline-cmd --zone=block --add-rich-rule='rule family="ipv4" source address="10.100.100.0/24" port port="48010" protocol="tcp" accept log prefix="Sunshine - RTSP TCP"'
firewall-offline-cmd --zone=block --add-rich-rule='rule family="ipv4" source address="10.100.100.0/24" port port="48010" protocol="udp" accept log prefix="Sunshine - RTSP UDP"'
firewall-offline-cmd --zone=block --add-rich-rule='rule family="ipv4" source address="10.100.100.0/24" port port="47998" protocol="udp" accept log prefix="Sunshine - Video"'
firewall-offline-cmd --zone=block --add-rich-rule='rule family="ipv4" source address="10.100.100.0/24" port port="48000" protocol="udp" accept log prefix="Sunshine - Audio"'

################################################
##### AppArmor profiles
################################################

# References:
# https://wiki.archlinux.org/title/AppArmor
# https://wiki.archlinux.org/title/Audit_framework
# https://github.com/roddhjav/apparmor.d

# Allow user to read audit logs and get desktop notification on DENIED actions
groupadd -r audit

usermod -a -G audit ${NEW_USER}

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
##### ALVR (aur)
################################################

# References:
# https://github.com/alvr-org/ALVR/wiki/Installation-guide

# Install ALVR
sudo -u ${NEW_USER} paru -S --noconfirm alvr-bin

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

# Allow ALVR through firewall
firewall-offline-cmd --zone=block --add-service=alvr
firewall-offline-cmd --zone=home --add-service=alvr

firewall-offline-cmd --zone=block --add-service=alvr
firewall-offline-cmd --zone=home --add-service=alvr

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

# Install Heroic Games Launcher
sudo -u ${NEW_USER} paru -S --noconfirm heroic-games-launcher-bin

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
##### Docker
################################################

# References:
# https://wiki.archlinux.org/title/docker

# Install Docker and plugins
pacman -S --noconfirm docker docker-compose docker-buildx

# Enable Docker socket
systemctl enable docker.socket

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

flatpak install -y flathub org.blender.Blender
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/org.blender.Blender -o ${HOME}/.local/share/flatpak/overrides/org.blender.Blender

flatpak install -y flathub org.libreoffice.LibreOffice
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/org.libreoffice.LibreOffice -o ${HOME}/.local/share/flatpak/overrides/org.libreoffice.LibreOffice

flatpak install -y org.sqlitebrowser.sqlitebrowser
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/org.sqlitebrowser.sqlitebrowser -o ${HOME}/.local/share/flatpak/overrides/org.sqlitebrowser.sqlitebrowser

flatpak install -y flathub io.beekeeperstudio.Studio
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/io.beekeeperstudio.Studio -o ${HOME}/.local/share/flatpak/overrides/io.beekeeperstudio.Studio
