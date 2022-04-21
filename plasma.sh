#!/bin/bash

# Download and run base script
curl https://raw.githubusercontent.com/gjpin/arch-linux/master/base.sh -o base.sh
chmod +x 2_base.sh
sh ./2_base.sh

# Install Plasma group
sudo pacman -S plasma --ignore=discover,plasma-sdk

# Enable SDDM
sudo systemctl enable sddm

# Install other Plasma applications
sudo pacman -S --noconfirm plasma-wayland-session xdg-desktop-portal ark dolphin dolphin-plugins gwenview \
kate kgpg konsole kwalletmanager okular spectacle kscreen kcalc filelight partitionmanager \
krunner kfind plasma-systemmonitor phonon-qt5-gstreamer libdbusmenu-glib power-profiles-daemon

sudo flatpak install -y flathub org.kde.keysmith

# Install KDE Connect
sudo pacman -S --noconfirm kdeconnect sshfs

# Install KeePassXC
sudo flatpak install -y flathub org.keepassxc.KeePassXC
sudo flatpak override --unshare=network org.keepassxc.KeePassXC

# Install Breeze-GTK flatpak theme
sudo flatpak install -y flathub org.gtk.Gtk3theme.Breeze

# Disable baloo (file indexer)
balooctl suspend
balooctl disable

# Run SDDM under Wayland
sudo mkdir -p /etc/sddm.conf.d/
sudo tee /etc/sddm.conf.d/10-wayland.conf << EOF
[Wayland]
CompositorCommand=kwin_wayland --no-lockscreen
EOF

# Enable OpenGL 3.1
kwriteconfig5 --file kwinrc --group Compositing --key GLCore --type bool true
kwriteconfig5 --file kwinrc --group Compositing --key OpenGLIsUnsafe --type bool false

# Configure Plasma
kwriteconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage "org.kde.breezetwilight.desktop"
kwriteconfig5 --file kdeglobals --group KDE --key SingleClick --type bool true
kwriteconfig5 --file kdeglobals --group KDE --key AnimationDurationFactor "0.5"

# Enable 2 desktops
kwriteconfig5 --file kwinrc --group Desktops --key Name_2 "Desktop 2"
kwriteconfig5 --file kwinrc --group Desktops --key Number "2"
kwriteconfig5 --file kwinrc --group Desktops --key Rows "1"

# Change window decorations
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ""
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX"
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ShowToolTips --type bool false

# Configure Konsole
kwriteconfig5 --file konsolerc --group KonsoleWindow --key SaveGeometryOnExit --type bool false
kwriteconfig5 --file konsolerc --group KonsoleWindow --key ShowMenuBarByDefault --type bool false
kwriteconfig5 --file konsolerc --group MainWindow --key MenuBar "Disabled"
kwriteconfig5 --file konsolerc --group MainWindow --key StatusBar "Disabled"
kwriteconfig5 --file konsolerc --group MainWindow --key ToolBarsMovable "Disabled"

# Disable screen edges
kwriteconfig5 --file kwinrc --group Effect-PresentWindows --key BorderActivateAll "9"
kwriteconfig5 --file kwinrc --group TabBox --key BorderActivate "9"

# Change Task Switcher behaviour
kwriteconfig5 --file kwinrc --group TabBox --key HighlightWindows  --type bool false
kwriteconfig5 --file kwinrc --group TabBox --key LayoutName "thumbnail_grid"

# Disable splash screen
kwriteconfig5 --file ksplashrc --group KSplash --key Engine "none"
kwriteconfig5 --file ksplashrc --group KSplash --key Theme "none"

# Import Konsole Github color schemes
wget -P $HOME/.local/share/konsole https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/konsole/dark.colorscheme
wget -P $HOME/.local/share/konsole https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/konsole/light.colorscheme

# Customize bash
tee -a ~/.bashrc.d/prompt << EOF
PS1="\[\e[1;36m\]\w\[\e[m\] \[\e[1;33m\]\\$\[\e[m\] "
PROMPT_COMMAND="export PROMPT_COMMAND=echo"
EOF

# Disable app launch feedback
kwriteconfig5 --file klaunchrc --group BusyCursorSettings --key "Bouncing" --type bool false
kwriteconfig5 --file klaunchrc --group FeedbackStyle --key "BusyCursor" --type bool false

# SDDM theme
sudo kwriteconfig5 --file /etc/sddm.conf.d/kde_settings.conf --group Theme --key "Current" "breeze"

# Enable overview
sudo kwriteconfig5 --file kwinrc --group Plugins --key "overviewEnabled" --type bool true
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Overview" "Meta+Tab,none,Toggle Overview"

# Use KDE Wallet to store ssh key passphrases
mkdir -p ~/.config/autostart/
tee -a ~/.config/autostart/ssh-add.desktop << EOF
[Desktop Entry]
Exec=ssh-add -q /home/$USER/.ssh/id_ed25519
Name=ssh-add
Type=Application
EOF

mkdir -p ~/.config/plasma-workspace/env/
tee -a ~/.config/plasma-workspace/env/askpass.sh << EOF
#!/bin/sh
export SSH_ASKPASS='/usr/bin/ksshaskpass'
EOF

chmod +x ~/.config/plasma-workspace/env/askpass.sh

##### SHORTCUTS
# Desktop switch
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 1" "none,none,Activate Task Manager Entry 1"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 2" "none,none,Activate Task Manager Entry 2"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 3" "none,none,Activate Task Manager Entry 3"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 4" "none,none,Activate Task Manager Entry 4"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 5" "none,none,Activate Task Manager Entry 5"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 6" "none,none,Activate Task Manager Entry 6"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 7" "none,none,Activate Task Manager Entry 7"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 8" "none,none,Activate Task Manager Entry 8"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 9" "none,none,Activate Task Manager Entry 9"
kwriteconfig5 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 10" "none,none,Activate Task Manager Entry 10"

kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 1" "Meta+1,none,Switch to Desktop 1"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 2" "Meta+2,none,Switch to Desktop 2"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 3" "Meta+3,none,Switch to Desktop 3"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 4" "Meta+4,none,Switch to Desktop 4"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 5" "Meta+5,none,Switch to Desktop 5"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 6" "Meta+6,none,Switch to Desktop 6"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 7" "Meta+7,none,Switch to Desktop 7"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 8" "Meta+8,none,Switch to Desktop 8"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 9" "Meta+9,none,Switch to Desktop 9"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 10" "Meta+0,none,Switch to Desktop 10"

kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 1" "Meta+\!,none,Window to Desktop 1"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 2" "Meta+@,none,Window to Desktop 2"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 3" "Meta+#,none,Window to Desktop 3"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 4" "Meta+$,none,Window to Desktop 4"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 5" "Meta+%,none,Window to Desktop 5"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 6" "Meta+^,none,Window to Desktop 6"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 7" "Meta+&,none,Window to Desktop 7"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 8" "Meta+*,none,Window to Desktop 8"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 9" "Meta+(,none,Window to Desktop 9"
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 10" "Meta+),none,Window to Desktop 10"

# Konsole
kwriteconfig5 --file kglobalshortcutsrc --group org.kde.konsole.desktop --key "_launch" "Meta+Return,none,Konsole"

# Close windows
kwriteconfig5 --file kglobalshortcutsrc --group kwin --key "Window Close" "Meta+Shift+Q,none,Close Window"

# Spectacle
kwriteconfig5 --file kglobalshortcutsrc --group "org.kde.spectacle.desktop" --key "RectangularRegionScreenShot" "Meta+Shift+S,none,Capture Rectangular Region"

echo "Your setup is ready. You can reboot now!"