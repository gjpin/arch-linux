#!/usr/bin/bash

################################################
##### Plasma
################################################

# Plasma packages
pacman -S --noconfirm \
    bluedevil \
    breeze \
    breeze-gtk \
    drkonqi \
    flatpak-kcm \
    kactivitymanagerd \
    kde-cli-tools \
    kde-gtk-config \
    kdecoration \
    kdeplasma-addons \
    kgamma \
    kglobalacceld \
    kinfocenter \
    kmenuedit \
    kpipewire \
    kscreen \
    kscreenlocker \
    ksshaskpass \
    ksystemstats \
    kwallet-pam \
    kwayland \
    kwayland-integration \
    kwin \
    kwrited \
    layer-shell-qt \
    libkscreen \
    libksysguard \
    libplasma \
    milou \
    ocean-sound-theme \
    oxygen \
    oxygen-sounds \
    plasma-activities \
    plasma-activities-stats \
    plasma-browser-integration \
    plasma-desktop \
    plasma-disks \
    plasma-firewall \
    plasma-integration \
    plasma-nm \
    plasma-pa \
    plasma-systemmonitor \
    plasma-thunderbolt \
    plasma-vault \
    plasma-workspace \
    plasma-workspace-wallpapers \
    plasma5support \
    polkit-kde-agent \
    powerdevil \
    print-manager \
    qqc2-breeze-style \
    systemsettings \
    wacomtablet \
    xdg-desktop-portal-kde

# Non-Plasma packages (add-ons, extensions, ...)
# https://community.kde.org/Distributions/Packaging_Recommendations#Non-Plasma_packages
pacman -S --noconfirm \
    baloo-widgets \
    dolphin-plugins \
    ffmpegthumbs \
    kde-inotify-survey \
    kdeconnect \
    kdegraphics-thumbnailers \
    kdenetwork-filesharing \
    kimageformats \
    kio-admin \
    kio-extras \
    kio-fuse \
    phonon-qt6-vlc \
    qt6-imageformats \
    xwaylandvideobridge

# 3rd-party packages
# https://community.kde.org/Distributions/Packaging_Recommendations#3rd-party_packages
pacman -S --noconfirm \
    fprintd \
    icoutils \
    iio-sensor-proxy \
    libappindicator-gtk3 \
    qt-imageformats \
    switcheroo-control \
    xdg-desktop-portal-gtk \
    xsettingsd

# KDE applications
pacman -S --noconfirm \
    ark \
    dolphin \
    filelight \
    gwenview \
    kate \
    kcalc \
    kcolorchooser \
    kfind \
    kompare \
    konsole \
    kwalletmanager \
    okular \
    partitionmanager \
    plasma-systemmonitor \
    spectacle \
    keysmith

# Extra Plasma packages
pacman -S --noconfirm \
    sshfs \
    quota-tools \
    kommit

# Install VLC
pacman -S --noconfirm vlc

# Use KDE file picker in GTK applications
tee -a /etc/environment << EOF

# KDE file picker
GDK_DEBUG=portals
EOF

# Disable baloo (file indexer)
sudo -u ${NEW_USER} balooctl6 suspend
sudo -u ${NEW_USER} balooctl6 disable
sudo -u ${NEW_USER} balooctl6 purge

# Allow KDE Connect through firewall
firewall-offline-cmd --zone=home --add-service=kdeconnect

################################################
##### SDDM
################################################

# Install SDDM
pacman -S --noconfirm sddm sddm-kcm

# Enable SDDM service
systemctl enable sddm.service

################################################
##### GTK theming
################################################

# Apply Breeze Dark theme to GTK applications
mkdir -p /home/${NEW_USER}/.config/{gtk-3.0,gtk-4.0}
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/gtk/kde-gtk.css -o /home/${NEW_USER}/.config/gtk-3.0/gtk.css
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/gtk/kde-gtk.css -o /home/${NEW_USER}/.config/gtk-4.0/gtk.css

# Select GTK theme
mkdir -p /home/${NEW_USER}/.config/xsettingsd
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/xsettingsd/xsettingsd.conf -o /home/${NEW_USER}/.config/xsettingsd/xsettingsd.conf

################################################
##### SSH
################################################

# Use the KDE Wallet to store ssh key passphrases
# https://wiki.archlinux.org/title/KDE_Wallet#Using_the_KDE_Wallet_to_store_ssh_key_passphrases
tee /home/${NEW_USER}/.config/autostart/ssh-add.desktop << EOF
[Desktop Entry]
Exec=ssh-add -q
Name=ssh-add
Type=Application
EOF

tee /home/${NEW_USER}/.config/environment.d/ssh_askpass.conf << EOF
SSH_ASKPASS='/usr/bin/ksshaskpass'
GIT_ASKPASS=ksshaskpass
SSH_ASKPASS=ksshaskpass
SSH_ASKPASS_REQUIRE=prefer
EOF

################################################
##### Autologin
################################################

# References:
# https://wiki.archlinux.org/title/SDDM#Autologin

# Enable autologin
if [ ${AUTOLOGIN} = "yes" ]; then
tee /etc/sddm.conf.d/autologin.conf << EOF
[Autologin]
User=${NEW_USER}
Session=plasmawayland
EOF
fi

################################################
##### Plasma shortcuts
################################################

# Konsole shortcut
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group org.kde.konsole.desktop --key "_launch" "Meta+Return,none,Konsole"

# Toggle overview shortcut
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Overview" "Meta+Tab,Meta+W,Toggle Overview"

# Close windows shortcut
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Close" "Meta+Shift+Q,none,Close Window"

# Disable task manager entry activation
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 1" "none,none,Activate Task Manager Entry 1"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 2" "none,none,Activate Task Manager Entry 2"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 3" "none,none,Activate Task Manager Entry 3"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 4" "none,none,Activate Task Manager Entry 4"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 5" "none,none,Activate Task Manager Entry 5"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 6" "none,none,Activate Task Manager Entry 6"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 7" "none,none,Activate Task Manager Entry 7"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 8" "none,none,Activate Task Manager Entry 8"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 9" "none,none,Activate Task Manager Entry 9"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 10" "none,none,Activate Task Manager Entry 10"

# Go to virtual desktop
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 1" "Meta+1,none,Switch to Desktop 1"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 2" "Meta+2,none,Switch to Desktop 2"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 3" "Meta+3,none,Switch to Desktop 3"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 4" "Meta+4,none,Switch to Desktop 4"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 5" "Meta+5,none,Switch to Desktop 5"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 6" "Meta+6,none,Switch to Desktop 6"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 7" "Meta+7,none,Switch to Desktop 7"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 8" "Meta+8,none,Switch to Desktop 8"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 9" "Meta+9,none,Switch to Desktop 9"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 10" "Meta+0,none,Switch to Desktop 10"

# Move window to virtual desktop
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 1" "Meta+\!,none,Window to Desktop 1"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 2" "Meta+@,none,Window to Desktop 2"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 3" "Meta+#,none,Window to Desktop 3"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 4" "Meta+$,none,Window to Desktop 4"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 5" "Meta+%,none,Window to Desktop 5"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 6" "Meta+^,none,Window to Desktop 6"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 7" "Meta+&,none,Window to Desktop 7"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 8" "Meta+*,none,Window to Desktop 8"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 9" "Meta+(,none,Window to Desktop 9"
sudo -u ${NEW_USER} kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 10" "Meta+),none,Window to Desktop 10"

################################################
##### Plasma UI / UX changes
################################################

# Set SDDM theme
kwriteconfig6 --file /etc/sddm.conf.d/kde_settings.conf --group Theme --key "Current" "breeze"

# Set Plasma theme
sudo -u ${NEW_USER} kwriteconfig6 --file kdeglobals --group KDE --key LookAndFeelPackage "org.kde.breezedark.desktop"

# Enable 2 desktops
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrc --group Desktops --key Name_2 "Desktop 2"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrc --group Desktops --key Number "2"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrc --group Desktops --key Rows "1"

# Change window decorations
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ""
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key ShowToolTips --type bool false

# Disable app launch feedback
sudo -u ${NEW_USER} kwriteconfig6 --file klaunchrc --group BusyCursorSettings --key "Bouncing" --type bool false
sudo -u ${NEW_USER} kwriteconfig6 --file klaunchrc --group FeedbackStyle --key "BusyCursor" --type bool false

# Disable cursor shake
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrc --group Plugins --key "shakecursorEnabled" --type bool false

# Disable windows outline
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "Common" --key OutlineIntensity "OutlineOff"

################################################
##### Titlebar color schemes
################################################

# References:
# https://github.com/eritbh/kde-application-titlebar-themes

# Create directory for custom color schemes
mkdir -p /home/${NEW_USER}/.local/share/color-schemes

# VSCode
curl -O --output-dir /home/${NEW_USER}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/colors/VSCodeModernDark.colors

sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "0fcd2e39-42a2-4e82-a8b0-ee01dbe06bd6" --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "0fcd2e39-42a2-4e82-a8b0-ee01dbe06bd6" --key decocolor "VSCodeModernDark"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "0fcd2e39-42a2-4e82-a8b0-ee01dbe06bd6" --key Description "Application settings for Code"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "0fcd2e39-42a2-4e82-a8b0-ee01dbe06bd6" --key decocolorrule "2"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "0fcd2e39-42a2-4e82-a8b0-ee01dbe06bd6" --key wmclass "code Code"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "0fcd2e39-42a2-4e82-a8b0-ee01dbe06bd6" --key wmclasscomplete "true"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "0fcd2e39-42a2-4e82-a8b0-ee01dbe06bd6" --key wmclassmatch "1"

# Discord
curl -O --output-dir /home/${NEW_USER}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/colors/DiscordOnyx.colors

sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "2100c0f9-f5ae-410a-ab1c-892232f95c06" --key Description "Application settings for discord"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "2100c0f9-f5ae-410a-ab1c-892232f95c06" --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "2100c0f9-f5ae-410a-ab1c-892232f95c06" --key decocolor "DiscordOnyx"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "2100c0f9-f5ae-410a-ab1c-892232f95c06" --key decocolorrule "2"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "2100c0f9-f5ae-410a-ab1c-892232f95c06" --key wmclass "discord"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "2100c0f9-f5ae-410a-ab1c-892232f95c06" --key wmclassmatch "1"

# Heroic
curl -O --output-dir /home/${NEW_USER}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/colors/HeroicGamesLauncher.colors

sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "474e9587-e3c9-4d3b-adb8-81126272ced3" --key Description "Application settings for heroic"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "474e9587-e3c9-4d3b-adb8-81126272ced3" --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "474e9587-e3c9-4d3b-adb8-81126272ced3" --key decocolor "HeroicGamesLauncher"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "474e9587-e3c9-4d3b-adb8-81126272ced3" --key decocolorrule "2"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "474e9587-e3c9-4d3b-adb8-81126272ced3" --key wmclass "heroic"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "474e9587-e3c9-4d3b-adb8-81126272ced3" --key wmclassmatch "1"

# Obsidian
curl -O --output-dir /home/${NEW_USER}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/colors/ObsidianDark.colors

sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "eaf84238-f041-4f87-b04b-0ba58bcddff3" --key Description "Application settings for obsidian"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "eaf84238-f041-4f87-b04b-0ba58bcddff3" --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "eaf84238-f041-4f87-b04b-0ba58bcddff3" --key decocolor "ObsidianDark"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "eaf84238-f041-4f87-b04b-0ba58bcddff3" --key decocolorrule "2"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "eaf84238-f041-4f87-b04b-0ba58bcddff3" --key wmclass "obsidian"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "eaf84238-f041-4f87-b04b-0ba58bcddff3" --key wmclassmatch "1"

# Spotify
curl -O --output-dir /home/${NEW_USER}/.local/share/color-schemes https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/colors/Spotify.colors

sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "f251c05a-63f7-4d9c-a7c8-9bfb6728acb4" --key Description "Application settings for Spotify"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "f251c05a-63f7-4d9c-a7c8-9bfb6728acb4" --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "f251c05a-63f7-4d9c-a7c8-9bfb6728acb4" --key decocolor "Spotify"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "f251c05a-63f7-4d9c-a7c8-9bfb6728acb4" --key decocolorrule "2"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "f251c05a-63f7-4d9c-a7c8-9bfb6728acb4" --key wmclass "spotify Spotify"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "f251c05a-63f7-4d9c-a7c8-9bfb6728acb4" --key wmclasscomplete "true"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "f251c05a-63f7-4d9c-a7c8-9bfb6728acb4" --key wmclassmatch "1"

# General
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "General" --key count "5"
sudo -u ${NEW_USER} kwriteconfig6 --file kwinrulesrc --group "General" --key rules "474e9587-e3c9-4d3b-adb8-81126272ced3,eaf84238-f041-4f87-b04b-0ba58bcddff3,2100c0f9-f5ae-410a-ab1c-892232f95c06,0fcd2e39-42a2-4e82-a8b0-ee01dbe06bd6,f251c05a-63f7-4d9c-a7c8-9bfb6728acb4"