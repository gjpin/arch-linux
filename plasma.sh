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
    kgamma \
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
    sshfs \
    kfind \
    quota-tools \
    filelight
    
# Install VLC
pacman -S --noconfirm vlc

# Use KDE file picker in GTK applications
tee -a /etc/environment << EOF

# KDE file picker
GTK_USE_PORTAL=1
EOF

# Disable baloo (file indexer)
sudo -u ${NEW_USER} balooctl suspend
sudo -u ${NEW_USER} balooctl disable
sudo -u ${NEW_USER} balooctl purge

################################################
##### SDDM
################################################

# Install SDDM
pacman -S --noconfirm sddm sddm-kcm

# Enable SDDM service
systemctl enable sddm.service

################################################
##### Wayland
################################################

# Run Qt applications with the Wayland plugin
pacman -S --noconfirm \
    qt5-wayland \
    qt6-wayland

tee -a /etc/environment << EOF

# Qt
QT_QPA_PLATFORM="wayland;xcb"
EOF

################################################
##### Konsole
################################################

# Create Konsole configs directory
mkdir -p /home/${NEW_USER}/.local/share/konsole

# Apply Konsole configurations
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/konsole/konsole_breeze_modern_dark.css -o /home/${NEW_USER}/.config/konsole_breeze_modern_dark.css

tee /home/${NEW_USER}/.config/konsolerc << EOF
MenuBar=Disabled

[Desktop Entry]
DefaultProfile=custom.profile

[KonsoleWindow]
RememberWindowSize=false

[TabBar]
TabBarUseUserStyleSheet=true
TabBarUserStyleSheetFile=file:///home/${NEW_USER}/.config/konsole_breeze_modern_dark.css
EOF

# Import Konsole custom profile
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/konsole/custom.profile -o /home/${NEW_USER}/.local/share/konsole/custom.profile

# Import Konsole custom color scheme
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/plasma/konsole/Breeze_Dark_Modern.profile -o /home/${NEW_USER}/.local/share/konsole/Breeze_Dark_Modern.profile

################################################
##### GTK theming
################################################

# Install GTK themes
flatpak install -y flathub org.gtk.Gtk3theme.Breeze org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark

# Install Gradience
flatpak install -y flathub com.github.GradienceTeam.Gradience

# Import Gradience Flatpak overrides
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.github.GradienceTeam.Gradience -o /home/${NEW_USER}/.local/share/flatpak/overrides/com.github.GradienceTeam.Gradience

# Apply Breeze Dark theme to GTK applications
mkdir -p /home/${NEW_USER}/.config/{gtk-3.0,gtk-4.0}
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/gtk/gtk.css -o /home/${NEW_USER}/.config/gtk-3.0/gtk.css
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/gtk/gtk.css -o /home/${NEW_USER}/.config/gtk-4.0/gtk.css

################################################
##### Firefox
################################################

# KDE specific configurations
tee -a ${FIREFOX_PROFILE_PATH}/user.js << 'EOF'

// KDE integration
// https://wiki.archlinux.org/title/firefox#KDE_integration
user_pref("widget.use-xdg-desktop-portal.mime-handler", 1);
user_pref("widget.use-xdg-desktop-portal.file-picker", 1);
EOF

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
##### Plasma shortcuts
################################################

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

################################################
##### Plasma UI / UX changes
################################################

# Import Plasma color schemes
mkdir -p /home/${NEW_USER}/.local/share/color-schemes
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

# Set Plasma theme
sudo -u ${NEW_USER} kwriteconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage "org.kde.breezedark.desktop"

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

# Replace plasmashell
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group "plasmashell.desktop" --key "_k_friendly_name" "plasmashell --replace"
sudo -u ${NEW_USER} kwriteconfig5 --file kglobalshortcutsrc --group "plasmashell.desktop" --key "_launch" "Ctrl+Alt+Del,none,plasmashell --replace"

# Enable 2 desktops
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrc --group Desktops --key Name_2 "Desktop 2"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrc --group Desktops --key Number "2"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrc --group Desktops --key Rows "1"

# Configure konsole
sudo -u ${NEW_USER} kwriteconfig5 --file konsolerc --group "KonsoleWindow" --key "RememberWindowSize" --type bool false
sudo -u ${NEW_USER} kwriteconfig5 --file konsolerc --group "MainWindow" --key "MenuBar" "Disabled"

# Window decorations
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 1 --key Description "Application settings for vscode"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 1 --key decocolor "VSCodeDarkModern"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 1 --key wmclass "code"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 1 --key wmclasscomplete --type bool true
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 1 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 2 --key Description "Application settings for blender"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 2 --key decocolor "Blender"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 2 --key decocolorrule 2
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 2 --key wmclass "\sblender"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 2 --key wmclasscomplete --type bool true
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 2 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 3 --key Description "Application settings for gimp"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 3 --key decocolor "Gimp"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 3 --key decocolorrule 2
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 3 --key wmclass "gimp"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 3 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 3 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 4 --key Description "Application settings for godot"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 4 --key decocolor "Godot"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 4 --key decocolorrule 2
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 4 --key wmclass "godot_editor godot"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 4 --key wmclasscomplete --type bool true
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 4 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 4 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 5 --key Description "Application settings for discord"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 5 --key decocolor "DiscordDark"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 5 --key decocolorrule 2
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 5 --key wmclass "discord"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 5 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 5 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 6 --key Description "Application settings for insomnia"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 6 --key decocolor "Insomnia"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 6 --key decocolorrule 2
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 6 --key wmclass "insomnia"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 6 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 6 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 7 --key Description "Application settings for heroic"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 7 --key decocolor "HeroicGamesLauncher"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 7 --key decocolorrule 2
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 7 --key wmclass "heroic"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 7 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 7 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 8 --key Description "Application settings for spotify"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 8 --key decocolor "Spotify"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 8 --key decocolorrule 2
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 8 --key wmclass "spotify"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 8 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 8 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 9 --key Description "Application settings for obsidian"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 9 --key decocolor "ObsidianDark"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 9 --key decocolorrule 2
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 9 --key wmclass "obsidian"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 9 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 9 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 10 --key Description "Application settings for slack"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 10 --key decocolor "SlackAubergineLight.colors"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 10 --key decocolorrule 2
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 10 --key wmclass "slack"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 10 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 10 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 11 --key Description "Application settings for konsole"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 11 --key decocolor "Konsole.colors"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 11 --key wmclass "konsole org.kde.konsole"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 11 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 11 --key wmclassmatch 1

sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group General --key count 10
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group General --key rules "1,2,3,4,5,6,7,8,9,10"