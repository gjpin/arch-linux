#!/bin/bash

# References:
# https://wiki.archlinux.org/title/KDE
# https://wiki.archlinux.org/title/KDE_Wallet#Using_the_KDE_Wallet_to_store_ssh_key_passphrases
# https://wiki.archlinux.org/title/Baloo
# https://wiki.archlinux.org/title/SDDM
# https://www.reddit.com/r/linux_gaming/comments/vc2xfb/comment/icghppf/

################################################
##### KDE Plasma
################################################

# Install KDE Plasma
pacman -S --noconfirm \
    plasma-desktop \
    bluedevil \
    kinfocenter \
    kscreen \
    kwallet-pam \
    kwayland-integration \
    plasma-disks \
    plasma-nm \
    plasma-pa \
    plasma-systemmonitor \
    plasma-thunderbolt \
    plasma-vault \
    plasma-workspace-wallpapers \
    powerdevil \
    xdg-desktop-portal-kde \
    konsole \
    kate \
    dolphin \
    ark \
    plasma-wayland-session \
    kwalletmanager \
    spectacle \
    okular \
    gwenview \
    plasma-browser-integration \
    kdeplasma-addons \
    plasma-firewall \
    kdeconnect \
    sshfs \
    vlc \
    libappindicator-gtk3

# Disable baloo (file indexer)
sudo -u ${NEW_USER} balooctl suspend
sudo -u ${NEW_USER} balooctl disable
sudo -u ${NEW_USER} balooctl purge

# Install and enable SDDM
pacman -S --noconfirm sddm sddm-kcm
systemctl enable sddm.service

# Install Phonon backend
pacman -S --noconfirm phonon-qt5-vlc

# Use the KDE Wallet to store ssh key passphrases
pacman -S --noconfirm ksshaskpass

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

################################################
##### Firefox configurations
################################################

# Set environment variable required by Firefox's file picker
tee /home/${NEW_USER}/.config/environment.d/firefox-kde.conf << EOF
GTK_USE_PORTAL=1
EOF

# Set Firefox profile path
FIREFOX_PROFILE_PATH=$(realpath /home/${NEW_USER}/.mozilla/firefox/*.default-release)

# Install Firefox's Plasma Integration extension
curl https://addons.mozilla.org/firefox/downloads/file/3859385/plasma_integration-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/plasma-browser-integration@kde.org.xpi

# Import Firefox' user configurations
tee -a ${FIREFOX_PROFILE_PATH}/user.js << EOF

// Use KDE Plasma's file picker
user_pref("widget.use-xdg-desktop-portal.mime-handler", 1);
user_pref("widget.use-xdg-desktop-portal.file-picker", 1);

// Prevent duplicate entries in KDE Plasma's media player widget
user_pref("media.hardwaremediakeys.enabled", false);
EOF

################################################
##### KDE Plasma configurations
################################################

# Set SDDM theme
kwriteconfig5 --file /etc/sddm.conf.d/kde_settings.conf --group Theme --key "Current" "breeze"

# Set Plasma theme
sudo -u ${NEW_USER} kwriteconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage "org.kde.breezetwilight.desktop"

# Increase animation speed
sudo -u ${NEW_USER} kwriteconfig5 --file kdeglobals --group KDE --key AnimationDurationFactor "0.5"

# Change window decorations
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ""
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ShowToolTips --type bool false

# Change Task Switcher behaviour
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrc --group TabBox --key LayoutName "thumbnail_grid"

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

# Force BreezeDark titlebar color scheme for specific applications
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group General --key count "10"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group General --key rules "1,2,3,4,5,6,7,8,9,10"

sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 1 --key Description "Application settings for code"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 1 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 1 --key decocolor "BreezeDark"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 1 --key decocolorrule "2"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 1 --key wmclass "code"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 1 --key wmclassmatch "2"

sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 2 --key Description "Application settings for insomnia"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 2 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 2 --key decocolor "BreezeDark"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 2 --key decocolorrule "2"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 2 --key wmclass "insomnia"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 2 --key wmclassmatch "2"

sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 3 --key Description "Application settings for podman desktop"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 3 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 3 --key decocolor "BreezeDark"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 3 --key decocolorrule "2"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 3 --key wmclass "podman"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 3 --key wmclassmatch "2"

sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 4 --key Description "Application settings for spotify"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 4 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 4 --key decocolor "BreezeDark"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 4 --key decocolorrule "2"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 4 --key wmclass "spotify"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 4 --key wmclassmatch "2"

sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 5 --key Description "Application settings for gimp"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 5 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 5 --key decocolor "BreezeDark"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 5 --key decocolorrule "2"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 5 --key wmclass "gimp"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 5 --key wmclassmatch "2"

sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 6 --key Description "Application settings for heroic games launcher"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 6 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 6 --key decocolor "BreezeDark"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 6 --key decocolorrule "2"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 6 --key wmclass "heroic"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 6 --key wmclassmatch "2"

sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 7 --key Description "Application settings for obsidian"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 7 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 7 --key decocolor "BreezeDark"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 7 --key decocolorrule "2"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 7 --key wmclass "obsidian"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 7 --key wmclassmatch "2"

sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 8 --key Description "Application settings for godot"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 8 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 8 --key decocolor "BreezeDark"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 8 --key decocolorrule "2"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 8 --key wmclass "godot"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 8 --key wmclassmatch "2"

sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 9 --key Description "Application settings for blender"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 9 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 9 --key decocolor "BreezeDark"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 9 --key decocolorrule "2"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 9 --key wmclass "blender"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 9 --key wmclassmatch "2"

sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 10 --key Description "Application settings for discord"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 10 --key clientmachine "localhost"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 10 --key decocolor "BreezeDark"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 10 --key decocolorrule "2"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 10 --key wmclass "discord"
sudo -u ${NEW_USER} kwriteconfig5 --file kwinrulesrc --group 10 --key wmclassmatch "2"

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

################################################
##### Theming
################################################

# References:
# https://marketplace.visualstudio.com/items?itemName=kde.breeze

# Install VSCode's Breeze theme
sudo -u ${NEW_USER} xvfb-run code --install-extension kde.breeze
sed -i '/{/a "workbench.colorTheme": "Breeze Dark",' "/home/${NEW_USER}/.config/Code/User/settings.json"

################################################
##### Better Qt / GTK integration
################################################

# https://wiki.archlinux.org/title/Uniform_look_for_Qt_and_GTK_applications#Breeze
# https://wiki.archlinux.org/title/Uniform_look_for_Qt_and_GTK_applications#GTK_apps_do_not_fully_use_KDE_system_settings

# Improve integration of GTK applications
pacman -S --noconfirm breeze-gtk kde-gtk-config

# Install Breeze theme (Flatpak)
flatpak install -y flathub org.gtk.Gtk3theme.Breeze

# Make Flatpak GTK3 apps use Breeze cursor
cp -R /usr/share/icons/* /home/${NEW_USER}/.icons

flatpak override --filesystem=/home/${NEW_USER}/.icons:ro

# Support Qt bindings for GTK
pacman -S --noconfirm gnome-settings-daemon gsettings-desktop-schemas gsettings-qt

# Use Breeze's color scheme in GTK4 applications
ln -s /home/${NEW_USER}/.config/gtk-3.0/colors.css /home/${NEW_USER}/.config/gtk-4.0/colors-breeze.css

echo '@import "colors-adwaita.css"' > /home/${NEW_USER}/.config/gtk-4.0/gtk.css
chattr +i /home/${NEW_USER}/.config/gtk-4.0/gtk.css

tee /home/${NEW_USER}/.config/gtk-4.0/colors-adwaita.css << EOF
@import "colors-breeze.css";

@define-color accent_color @theme_selected_bg_color_breeze;
@define-color accent_bg_color @theme_selected_bg_color_breeze;
@define-color accent_fg_color @theme_selected_fg_color_breeze;

@define-color success_color @success_color_breeze;
@define-color success_bg_color @success_color_breeze;
@define-color success_fg_color @theme_fg_color_breeze;

@define-color warning_color @warning_color_breeze;
@define-color warning_bg_color @warning_color_breeze;
@define-color warning_fg_color @theme_fg_color_breeze;

@define-color error_color @error_color_breeze;
@define-color error_bg_color @error_color_breeze;
@define-color error_fg_color @theme_fg_color_breeze;

@define-color window_bg_color @theme_base_color_breeze;
@define-color window_fg_color @theme_text_color_breeze;

@define-color headerbar_bg_color @theme_header_background_breeze;
@define-color headerbar_fg_color @theme_header_foreground_breeze;
@define-color headerbar_backdrop_color @theme_header_background_backdrop_breeze;
@define-color headerbar_border_color @borders_breeze;

@define-color popover_bg_color @theme_bg_color_breeze;
@define-color popover_fg_color @theme_fg_color_breeze;

@define-color view_bg_color @content_view_bg_breeze;
@define-color view_fg_color @theme_text_color_breeze;

@define-color card_bg_color @theme_bg_color_breeze;
@define-color card_fg_color @theme_fg_color_breeze;

@define-color scrollbar_outline_color @borders_breeze;
EOF