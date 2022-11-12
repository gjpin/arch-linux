#!/bin/bash

# References:
# https://wiki.archlinux.org/title/GNOME
# https://aur.archlinux.org/cgit/aur.git/tree/INSTALL.md?h=firefox-gnome-theme-git
# https://github.com/rafaelmardojai/firefox-gnome-theme/blob/master/configuration/user.js
# https://github.com/lassekongo83/adw-gtk3
# https://wiki.archlinux.org/title/Uniform_look_for_Qt_and_GTK_applications#Adwaita
# https://wiki.archlinux.org/title/GDM
# https://help.gnome.org/admin/system-admin-guide/stable/dconf-custom-defaults.html.en
# https://wiki.archlinux.org/title/mpv#Hardware_video_acceleration

################################################
##### Gnome
################################################

# Install Gnome
pacman -S --noconfirm \
    gnome-shell \
    gnome-control-center \
    nautilus \
    gnome-backgrounds \
    gnome-calculator \
    gnome-disk-utility \
    gnome-keyring \
	eog \
    evince \
    file-roller \
    gnome-system-monitor \
    gnome-shell-extensions \
    xdg-user-dirs-gtk \
    celluloid \
    kooha \
    gnome-console \
    gnome-text-editor \
    xdg-desktop-portal-gnome \
    libappindicator-gtk3

# Install and enable GDM
pacman -S --noconfirm gdm
systemctl enable gdm.service

# Enable bluetooth
systemctl enable bluetooth.service

# Improve Nextcloud integration with Nautilus
pacman -S --noconfirm python-nautilus

# Enable support for WEBP images in eog
pacman -S --noconfirm webp-pixbuf-loader

# Install Authenticator
flatpak install -y flathub com.belmoussaoui.Authenticator

# Install Gnome shell extensions
sudo -u ${NEW_USER} paru -S --noconfirm gnome-shell-extension-dark-variant
pacman -S --noconfirm gnome-shell-extension-appindicator

# Import mpv's configuration
mkdir -p /home/${NEW_USER}/.config/mpv
tee /home/${NEW_USER}/.config/mpv/mpv.conf << EOF
gpu-context=wayland
gpu-api=vulkan
hwdec=vaapi
vo=gpu
EOF

################################################
##### Theming
################################################

# Install VSCode's Adwaita theme
sudo -u ${NEW_USER} xvfb-run code --install-extension piousdeer.adwaita-theme
sed -i '/{/a "workbench.colorTheme": "Adwaita Dark & default syntax highlighting",' "/home/${NEW_USER}/.config/Code/User/settings.json"

# Improve integration of QT applications
pacman -S --noconfirm qgnomeplatform-qt5 qgnomeplatform-qt6

# Install adw-gtk3 theme
sudo -u ${NEW_USER} paru -S --noconfirm adw-gtk3

flatpak install -y flathub \
    org.gtk.Gtk3theme.adw-gtk3 \
    org.gtk.Gtk3theme.adw-gtk3-dark

################################################
##### Firefox configurations
################################################

# Install Firefox Gnome theme
sudo -u ${NEW_USER} paru -S --noconfirm \
    firefox-gnome-theme-git

for FIREFOX_PROFILE_PATH in /home/${NEW_USER}/.mozilla/firefox/*.default*
do
# Configure Firefox Gnome theme
mkdir -p ${FIREFOX_PROFILE_PATH}/chrome
ln -s /usr/lib/firefox-gnome-theme ${FIREFOX_PROFILE_PATH}/chrome/firefox-gnome-theme
echo "@import \"firefox-gnome-theme/userChrome.css\"" > ${FIREFOX_PROFILE_PATH}/chrome/userChrome.css
tee -a ${FIREFOX_PROFILE_PATH}/user.js << EOF

// Enable customChrome.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Set UI density to normal
user_pref("browser.uidensity", 0);

// Enable SVG context-propertes
user_pref("svg.context-properties.content.enabled", true);
EOF
done

################################################
##### Gnome configurations
################################################

# Create user profile
mkdir -p /etc/dconf/profile
tee /etc/dconf/profile/user << EOF
user-db:user
system-db:local
EOF

# Import Gnome configurations
mkdir -p /etc/dconf/db/local.d
tee /etc/dconf/db/local.d/01-custom << EOF
[org/gnome/desktop/interface]
gtk-theme='adw-gtk3'
color-scheme='default'

[org/gnome/desktop/wm/keybindings]
close=['<Shift><Super>q']
switch-applications=@as []
switch-applications-backward=@as []
switch-windows=['<Alt>Tab']
switch-windows-backward=['<Shift><Alt>Tab']
switch-to-workspace-1=['<Super>1']
switch-to-workspace-2=['<Super>2']
switch-to-workspace-3=['<Super>3']
switch-to-workspace-4=['<Super>4']
move-to-workspace-1=['<Shift><Super>exclam']
move-to-workspace-2=['<Shift><Super>at']
move-to-workspace-3=['<Shift><Super>numbersign']
move-to-workspace-4=['<Shift><Super>dollar']

[org/gnome/shell/keybindings]
show-screenshot-ui=['<Shift><Super>s']
switch-to-application-1=@as []
switch-to-application-2=@as []
switch-to-application-3=@as []
switch-to-application-4=@as []

[org/gnome/desktop/sound]
allow-volume-above-100-percent=true

[org/gnome/desktop/calendar]
show-weekdate=true

[org/gtk/settings/file-chooser]
sort-directories-first=true

[org/gnome/nautilus/icon-view]
default-zoom-level='standard'

[org/gnome/desktop/interface]
font-name='Noto Sans 10'
document-font-name='Noto Sans 10'
monospace-font-name='Noto Sans Mono 10'

[org/gnome/desktop/wm/preferences]
titlebar-font='Noto Sans Bold 10'

[org/gnome/shell]
disable-user-extensions=false

[org/gnome/shell]
enabled-extensions=['appindicatorsupport@rgcjonas.gmail.com', 'dark-variant@hardpixel.eu']

[org/gnome/shell/extensions/dark-variant]
applications=['code-oss.desktop', 'visual-studio-code.desktop', 'rest.insomnia.Insomnia.desktop', 'io.podman_desktop.PodmanDesktop.desktop', 'com.spotify.Client.desktop', 'gimp.desktop', 'com.heroicgameslauncher.hgl.desktop', 'obsidian.desktop']

[org/gnome/terminal/legacy]
theme-variant='dark'

[org/gnome/terminal/legacy/keybindings]
next-tab='<Primary>Tab'

[org/gnome/settings-daemon/plugins/media-keys]
custom-keybindings=['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/']

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0]
binding='<Super>Return'
command='kgx'
name='Gnome Console'

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1]
binding='<Super>E'
command='nautilus'
name='Nautilus'

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2]
binding='<Shift><Control>Escape'
command='gnome-system-monitor'
name='Gnome System Monitor'
EOF

# Laptop specific Gnome configurations
if cat /sys/class/dmi/id/chassis_type | grep 10 > /dev/null; then
tee /etc/dconf/db/local.d/01-laptop << EOF
[org/gnome/desktop/peripherals/touchpad]
tap-to-click=true
disable-while-typing=false

[org/gnome/desktop/interface]
show-battery-percentage=true
EOF
fi

# Update Gnome system databases
dconf update