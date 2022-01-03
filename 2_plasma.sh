#!/bin/bash

# Download and run base script
wget https://raw.githubusercontent.com/gjpin/arch-linux/master/2_base.sh
chmod +x 2_base.sh
sh ./2_base.sh

# Install Plasma group
sudo pacman -S plasma --ignore=discover,plasma-sdk

# Enable SDDM
sudo systemctl enable sddm

# Install other Plasma applications
sudo pacman -S --noconfirm plasma-wayland-session xdg-desktop-portal ark dolphin dolphin-plugins gwenview \
kate kgpg konsole kwalletmanager okular spectacle kscreen kcalc filelight partitionmanager \
krunner kfind plasma-systemmonitor phonon-qt5-gstreamer libdbusmenu-glib

sudo flatpak install -y flathub org.kde.keysmith

# Install KDE Connect
sudo pacman -S --noconfirm kdeconnect sshfs

# Install KeePassXC
sudo flatpak install -y flathub org.keepassxc.KeePassXC
sudo flatpak override --nofilesystem=host org.keepassxc.KeePassXC
sudo flatpak override --nodevice=all org.keepassxc.KeePassXC
sudo flatpak override --nosocket=x11 org.keepassxc.KeePassXC
sudo flatpak override --unshare=network org.keepassxc.KeePassXC
sudo flatpak override --filesystem=${HOME}/Sync/credentials org.keepassxc.KeePassXC

# Install Breeze-GTK flatpak theme and allow Flatpaks to access GTK configs
sudo flatpak install -y flathub org.gtk.Gtk3theme.Breeze
sudo flatpak install -y flathub org.gtk.Gtk3theme.Breeze-dark
sudo flatpak override --filesystem=xdg-config/gtk-3.0:ro
sudo flatpak override --filesystem=xdg-config/gtk-4.0:ro

# Disable baloo (file indexer)
balooctl suspend
balooctl disable

# Setup autologin
sudo mkdir -p /etc/sddm.conf.d/
sudo tee -a /etc/sddm.conf.d/autologin.conf << EOF
[Autologin]
User=$USER
Session=plasmawayland
EOF

# Customize bash
tee -a ${HOME}/.bashrc.d/prompt << EOF
PS1="\[\e[1;36m\]\w\[\e[m\] \[\e[1;33m\]\\$\[\e[m\] "
PROMPT_COMMAND="export PROMPT_COMMAND=echo"
EOF

# Download wallpaper
mkdir $HOME/Pictures/wallpapers/
wget -P $HOME/Pictures/wallpapers/ https://raw.githubusercontent.com/gjpin/arch-linux/master/images/wallpapers/hans-isaacson-MC5tMO1V-vs-unsplash.jpg

# Import konsole Github color schemes
wget -P ${HOME}/.local/share/konsole https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/konsole/dark.colorscheme
wget -P ${HOME}/.local/share/konsole https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/konsole/light.colorscheme

# Configure Plasma
kwriteconfig5 --file kdeglobals --group KDE --key LookAndFeelPackage "org.kde.breezetwilight.desktop"
kwriteconfig5 --file kdeglobals --group KDE --key SingleClick --type bool true
kwriteconfig5 --file kdeglobals --group KDE --key AnimationDurationFactor "0.5"
kwriteconfig5 --file kdeglobals --group General --key Name "Breeze Light"

# Enable OpenGL 3.1
kwriteconfig5 --file kwinrc --group Compositing --key GLCore --type bool true
kwriteconfig5 --file kwinrc --group Compositing --key OpenGLIsUnsafe --type bool false

# Enable 2 desktops
kwriteconfig5 --file kwinrc --group Desktops --key Name_2 "Desktop 2"
kwriteconfig5 --file kwinrc --group Desktops --key Number "2"
kwriteconfig5 --file kwinrc --group Desktops --key Rows "1"

# Change window decorations
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft ""
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight "IAX"
kwriteconfig5 --file kwinrc --group org.kde.kdecoration2 --key ShowToolTips --type bool false
kwriteconfig5 --file breezerc --group Common --key OutlineCloseButton --type bool false

# Disable baloo file indexer
kwriteconfig5 --file baloofilerc --group "Basic Settings" --key Indexing-Enabled --type bool false

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
kwriteconfig5 --file kwinrc --group TabBox --key BorderActivate "9"
kwriteconfig5 --file kwinrc --group TabBox --key HighlightWindows --type bool false
kwriteconfig5 --file kwinrc --group TabBox --key LayoutName "thumbnail_grid"

# Disable splash screen
kwriteconfig5 --file ksplashrc --group KSplash --key Engine "none"
kwriteconfig5 --file ksplashrc --group KSplash --key Theme "none"

# Change date time formats
#kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 4 --group Applets --group 21 --group Configuration --group Appearance --key customDateFormat "dd MM yyyy"
#kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 4 --group Applets --group 21 --group Configuration --group Appearance --key dateFormat "custom"
#kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 4 --group Applets --group 21 --group Configuration --group Appearance --key use24hFormat "2"

# Set wallpaper
kwriteconfig5 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "$HOME/Pictures/wallpapers/hans-isaacson-MC5tMO1V-vs-unsplash.jpg"
kwriteconfig5 --file plasmarc --group Wallpapers --key usersWallpapers "$HOME/Pictures/wallpapers/hans-isaacson-MC5tMO1V-vs-unsplash.jpg"
kwriteconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 1 --group Wallpaper --group org.kde.image --group General --key Image "$HOME/Pictures/wallpapers/hans-isaacson-MC5tMO1V-vs-unsplash.jpg"

echo "Your setup is ready. You can reboot now!"
