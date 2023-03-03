#!/usr/bin/bash

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
    kgamma5 \
    khotkeys \
    kinfocenter \
    kmenuedit \
    kpipewire \
    kscreen \
    kscreenlocker \
    ksshaskpass \
    ksystemstats \
    kwallet-pam \
    kwayland-integration \
    kwin \
    kwrited \
    layer-shell-qt \
    libkscreen \
    libksysguard \
    milou \
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
    polkit-kde-agent \
    powerdevil \
    sddm-kcm \
    systemsettings \
    xdg-desktop-portal-kde

# Non-Plasma packages (add-ons, extensions, ...)
pacman -S --noconfirm \
    baloo-widgets \
    dolphin-plugins \
    ffmpegthumbs \
    kdeconnect \
    kdegraphics-thumbnailers \
    kdenetwork-filesharing \
    kio-extras \
    kio-fuse \
    libappindicator-gtk3 \
    phonon-qt5-vlc

# 3rd-party packages
pacman -S --noconfirm \
    iio-sensor-proxy \
    xdg-desktop-portal-gtk \
    xsettingsd

# KDE applications
pacman -S --noconfirm \
    ark \
    dolphin \
    gwenview \
    kate \
    kcalc \
    kcolorchooser \
    konsole \
    kwalletmanager \
    okular \
    partitionmanager \
    plasma-systemmonitor \
    spectacle

# Extra Plasma packages
pacman -S --noconfirm \
    plasma-wayland-session \
    sshfs
    
# Install VLC
pacman -S --noconfirm vlc

# Install and enable SDDM
pacman -S --noconfirm sddm sddm-kcm
systemctl enable sddm.service

# Run Qt applications with the Wayland plugin
pacman -S --noconfirm \
    qt5-wayland \
    qt6-wayland

tee -a /etc/environment << EOF

# Qt
QT_QPA_PLATFORM="wayland;xcb"
EOF

# Use KDE file picker
tee -a /etc/environment << EOF

# KDE file picker
GTK_USE_PORTAL=1
EOF

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
SSH_ASKPASS_REQUIRE=prefer
EOF

# Disable baloo (file indexer)
sudo -u ${NEW_USER} balooctl suspend
sudo -u ${NEW_USER} balooctl disable
sudo -u ${NEW_USER} balooctl purge

# Install Firefox Plasma integration extension
curl https://addons.mozilla.org/firefox/downloads/file/3859385/plasma_integration-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/plasma-browser-integration@kde.org.xpi

################################################
##### KDE Plasma configurations
################################################

# Set SDDM theme
kwriteconfig5 --file /etc/sddm.conf.d/kde_settings.conf --group Theme --key "Current" "breeze"

# Change window decorations
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ""
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ShowToolTips --type bool false

# Disable splash screen
sudo -u ${NEW_USER} kwriteconfig5 --file ksplashrc --group KSplash --key Engine "none"
sudo -u ${NEW_USER} kwriteconfig5 --file ksplashrc --group KSplash --key Theme "none"

# Disable app launch feedback
sudo -u ${NEW_USER} kwriteconfig5 --file klaunchrc --group BusyCursorSettings --key "Bouncing" --type bool false
sudo -u ${NEW_USER} kwriteconfig5 --file klaunchrc --group FeedbackStyle --key "BusyCursor" --type bool false

# Configure screen edges
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrc --group Effect-overview --key BorderActivate "7"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrc --group Effect-windowview --key BorderActivateAll "9"

# Konsole shortcut
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group org.kde.konsole.desktop --key "_launch" "Meta+Return,none,Konsole"

# Spectacle shortcut
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group "org.kde.spectacle.desktop" --key "RectangularRegionScreenShot" "Meta+Shift+S,none,Capture Rectangular Region"

# Overview shortcut
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Overview" "Meta+Tab,none,Toggle Overview"

# Close windows shortcut
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window Close" "Meta+Shift+Q,none,Close Window"

# Enable 2 desktops
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrc --group Desktops --key Name_2 "Desktop 2"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrc --group Desktops --key Number "2"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrc --group Desktops --key Rows "1"

# Configure konsole
sudo -u ${NEW_USER} kwriteconfig5 --file konsolerc --group "KonsoleWindow" --key "RememberWindowSize" --type bool false
sudo -u ${NEW_USER} kwriteconfig5 --file konsolerc --group "MainWindow" --key "MenuBar" "Disabled"

# Desktop shortcuts
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 1" "none,none,Activate Task Manager Entry 1"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 2" "none,none,Activate Task Manager Entry 2"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 3" "none,none,Activate Task Manager Entry 3"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 4" "none,none,Activate Task Manager Entry 4"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 5" "none,none,Activate Task Manager Entry 5"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 6" "none,none,Activate Task Manager Entry 6"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 7" "none,none,Activate Task Manager Entry 7"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 8" "none,none,Activate Task Manager Entry 8"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 9" "none,none,Activate Task Manager Entry 9"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 10" "none,none,Activate Task Manager Entry 10"

sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 1" "Meta+1,none,Switch to Desktop 1"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 2" "Meta+2,none,Switch to Desktop 2"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 3" "Meta+3,none,Switch to Desktop 3"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 4" "Meta+4,none,Switch to Desktop 4"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 5" "Meta+5,none,Switch to Desktop 5"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 6" "Meta+6,none,Switch to Desktop 6"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 7" "Meta+7,none,Switch to Desktop 7"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 8" "Meta+8,none,Switch to Desktop 8"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 9" "Meta+9,none,Switch to Desktop 9"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 10" "Meta+0,none,Switch to Desktop 10"

sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 1" "Meta+\!,none,Window to Desktop 1"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 2" "Meta+@,none,Window to Desktop 2"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 3" "Meta+#,none,Window to Desktop 3"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 4" "Meta+$,none,Window to Desktop 4"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 5" "Meta+%,none,Window to Desktop 5"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 6" "Meta+^,none,Window to Desktop 6"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 7" "Meta+&,none,Window to Desktop 7"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 8" "Meta+*,none,Window to Desktop 8"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 9" "Meta+(,none,Window to Desktop 9"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 10" "Meta+),none,Window to Desktop 10"
