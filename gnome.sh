#!/bin/bash

# References:
# https://wiki.archlinux.org/title/GNOME
# https://aur.archlinux.org/cgit/aur.git/tree/INSTALL.md?h=firefox-gnome-theme-git
# https://github.com/rafaelmardojai/firefox-gnome-theme/blob/master/configuration/user.js
# https://github.com/lassekongo83/adw-gtk3
# https://wiki.archlinux.org/title/GDM
# https://help.gnome.org/admin/system-admin-guide/stable/dconf-custom-defaults.html.en
# https://wiki.archlinux.org/title/mpv#Hardware_video_acceleration
# https://archlinux.org/groups/x86_64/gnome/

################################################
##### Gnome
################################################

# Install Gnome core applications
# https://archlinux.org/groups/x86_64/gnome/
pacman -S --noconfirm \
    baobab \
	eog \
    evince \
    file-roller \
    gnome-backgrounds \
    gnome-calculator \
    gnome-calendar \
    gnome-color-manager \
    gnome-control-center \
    gnome-disk-utility \
    gnome-font-viewer \
    gnome-keyring \
    gnome-logs \
    gnome-photos \
    gnome-session \
    gnome-settings-daemon \
    gnome-shell \
    gnome-shell-extensions \
    gnome-system-monitor \
    gnome-text-editor \
    grilo-plugins \
    gvfs \
    gvfs-mtp \
    gvfs-nfs \
    nautilus \
    sushi \
    xdg-desktop-portal-gnome \
    xdg-user-dirs-gtk

# Additional Gnome/GTK packages
pacman -S --noconfirm \
    gitg \
    gnome-terminal \
    xdg-desktop-portal-gtk

# Install and enable GDM
pacman -S --noconfirm gdm
systemctl enable gdm.service

# Install and configure MPV / Celluloid
pacman -S --noconfirm \
    mpv \
    celluloid

mkdir -p /home/${NEW_USER}/.config/mpv

cp /usr/share/doc/mpv/mplayer-input.conf /home/${NEW_USER}/.config/mpv/input.conf

tee /home/${NEW_USER}/.config/mpv/mpv.conf << EOF
profile=gpu-hq
scale=ewa_lanczossharp
cscale=ewa_lanczossharp
video-sync=display-resample
interpolation
tscale=oversample
hwdec=auto
EOF

# Enable support for WEBP images in eog
pacman -S --noconfirm webp-pixbuf-loader

# Install Gnome's default file associations
sudo -u ${NEW_USER} paru -S --noconfirm shared-mime-info-gnome

# Install Flatpaks
flatpak install -y flathub com.belmoussaoui.Authenticator
flatpak install -y flathub com.github.marhkb.Pods

################################################
##### Gnome Shell extensions
################################################

# Create Gnome shell extensions folder
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions

# AppIndicator and KStatusNotifierItem Support
# https://extensions.gnome.org/extension/615/appindicator-support/
pacman -S --noconfirm libappindicator-gtk3
curl -sSL https://extensions.gnome.org/extension-data/appindicatorsupportrgcjonas.gmail.com.v49.shell-extension.zip -o shell-extension.zip
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions/appindicatorsupportrgcjonas.gmail.com
unzip shell-extension.zip -d /home/${NEW_USER}/.local/share/gnome-shell/extensions/appindicatorsupportrgcjonas.gmail.com
rm -f shell-extension.zip

# GSConnect
# https://extensions.gnome.org/extension/1319/gsconnect/
pacman -S --noconfirm openssl
curl -sSL https://extensions.gnome.org/extension-data/gsconnectandyholmes.github.io.v54.shell-extension.zip -o shell-extension.zip
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions/gsconnect@andyholmes.github.io
unzip shell-extension.zip -d /home/${NEW_USER}/.local/share/gnome-shell/extensions/gsconnect@andyholmes.github.io
rm -f shell-extension.zip

# Dark Variant
# https://extensions.gnome.org/extension/4488/dark-variant/
pacman -S --noconfirm xorg-xprop
curl -sSL https://extensions.gnome.org/extension-data/dark-varianthardpixel.eu.v8.shell-extension.zip -o shell-extension.zip
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions/dark-variant@hardpixel.eu
unzip shell-extension.zip -d /home/${NEW_USER}/.local/share/gnome-shell/extensions/dark-variant@hardpixel.eu
rm -f shell-extension.zip

# Rounded Window Corners
# https://extensions.gnome.org/extension/5237/rounded-window-corners/
curl -sSL https://extensions.gnome.org/extension-data/rounded-window-cornersyilozt.v10.shell-extension.zip -o shell-extension.zip
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions/rounded-window-corners@yilozt
unzip shell-extension.zip -d /home/${NEW_USER}/.local/share/gnome-shell/extensions/rounded-window-corners@yilozt
rm -f shell-extension.zip

# Legacy (GTK3) Theme Scheme Auto Switcher
# https://extensions.gnome.org/extension/4998/legacy-gtk3-theme-scheme-auto-switcher/
curl -sSL https://extensions.gnome.org/extension-data/legacyschemeautoswitcherjoshimukul29.gmail.com.v4.shell-extension.zip -o shell-extension.zip
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions/legacyschemeautoswitcher@joshimukul29.gmail.com
unzip shell-extension.zip -d /home/${NEW_USER}/.local/share/gnome-shell/extensions/legacyschemeautoswitcher@joshimukul29.gmail.com
rm -f shell-extension.zip

################################################
##### Better Qt / GTK integration
################################################

# References:
# https://wiki.archlinux.org/title/Uniform_look_for_Qt_and_GTK_applications
# https://github.com/GabePoel/KvLibadwaita
# https://github.com/tsujan/Kvantum/blob/master/Kvantum/doc/Theme-Config

# Improve integration of QT applications
pacman -S --noconfirm qgnomeplatform-qt5 qgnomeplatform-qt6 adwaita-qt5 adwaita-qt6

tee -a /etc/environment << EOF

# Qt
QT_QPA_PLATFORM=wayland
QT_QPA_PLATFORMTHEME=gnome
QT_STYLE_OVERRIDE=adwaita
XCURSOR_THEME=Adwaita
XCURSOR_SIZE=24
EOF

# Install Flatpak runtimes
flatpak install -y flathub org.kde.WaylandDecoration.QGnomePlatform-decoration/x86_64/6.5
flatpak install -y flathub org.kde.WaylandDecoration.QGnomePlatform-decoration/x86_64/5.15-22.08
flatpak install -y flathub org.kde.WaylandDecoration.QGnomePlatform-decoration/x86_64/5.15-21.08
flatpak install -y flathub org.kde.WaylandDecoration.QGnomePlatform-decoration/x86_64/5.15

flatpak install -y flathub org.kde.PlatformTheme.QGnomePlatform/x86_64/6.5
flatpak install -y flathub org.kde.PlatformTheme.QGnomePlatform/x86_64/5.15-22.08
flatpak install -y flathub org.kde.PlatformTheme.QGnomePlatform/x86_64/5.15-21.08
flatpak install -y flathub org.kde.PlatformTheme.QGnomePlatform/x86_64/5.15

################################################
##### Theming
################################################

# Install adw-gtk3 flatpak
sudo flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3
sudo flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3-dark

# Download and install latest adw-gtk3 release
URL=$(curl -s https://api.github.com/repos/lassekongo83/adw-gtk3/releases/latest | awk -F\" '/browser_download_url.*.tar.xz/{print $(NF-1)}')
curl -sSL ${URL} -o adw-gtk3.tar.xz
tar -xf adw-gtk3.tar.xz -C /home/${NEW_USER}/.local/share/themes/
rm -f adw-gtk3.tar.xz

# GTK theme updater
tee /home/${NEW_USER}/.local/bin/update-gtk-theme << 'EOF'
#!/usr/bin/bash

URL=$(curl -s https://api.github.com/repos/lassekongo83/adw-gtk3/releases/latest | awk -F\" '/browser_download_url.*.tar.xz/{print $(NF-1)}')
curl -sSL ${URL} -O
rm -rf ${HOME}/.local/share/themes/adw-gtk3*
tar -xf adw-*.tar.xz -C ${HOME}/.local/share/themes/
rm -f adw-*.tar.xz
EOF

chmod +x /home/${NEW_USER}/.local/bin/update-gtk-theme

sed -i "/flatpak update -y/a \n    # Update GTK theme\n    update-gtk-theme" /home/${NEW_USER}/.zshrc.local

# Install VSCode's Adwaita theme
sudo -u ${NEW_USER} xvfb-run code --install-extension piousdeer.adwaita-theme
sed -i '/{/a "workbench.colorTheme": "Adwaita Dark & default syntax highlighting",' "/home/${NEW_USER}/.config/Code/User/settings.json"

################################################
##### Firefox theming
################################################

# References:
# https://github.com/rafaelmardojai/firefox-gnome-theme

# Set Firefox profile path
FIREFOX_PROFILE_PATH=$(realpath /home/${NEW_USER}/.mozilla/firefox/*.default-release)

# Install Firefox Gnome theme
mkdir -p ${FIREFOX_PROFILE_PATH}/chrome
git clone https://github.com/rafaelmardojai/firefox-gnome-theme.git ${FIREFOX_PROFILE_PATH}/chrome/firefox-gnome-theme
echo "@import \"firefox-gnome-theme/userChrome.css\"" > ${FIREFOX_PROFILE_PATH}/chrome/userChrome.css
echo "@import \"firefox-gnome-theme/userContent.css\"" > ${FIREFOX_PROFILE_PATH}/chrome/userContent.css
tee -a ${FIREFOX_PROFILE_PATH}/user.js << EOF

// Enable customChrome.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Set UI density to normal
user_pref("browser.uidensity", 0);

// Enable SVG context-propertes
user_pref("svg.context-properties.content.enabled", true);

// Add more contrast to the active tab
user_pref("gnomeTheme.activeTabContrast", true);
EOF

# Firefox theme updater
tee /home/${NEW_USER}/.local/bin/update-firefox-theme << 'EOF'
#!/usr/bin/bash

# Update Firefox theme
FIREFOX_PROFILE_PATH=$(realpath /home/${NEW_USER}/.mozilla/firefox/*.default-release)
rm -rf ${FIREFOX_PROFILE_PATH}/chrome/firefox-gnome-theme
git clone https://github.com/rafaelmardojai/firefox-gnome-theme.git ${FIREFOX_PROFILE_PATH}/chrome/firefox-gnome-theme
EOF

chmod +x /home/${NEW_USER}/.local/bin/update-firefox-theme

sed -i "/flatpak update -y/a\    # Update Firefox theme\n    update-firefox-theme" /home/${NEW_USER}/.zshrc.local

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
default-zoom-level='small-plus'

[org/gnome/desktop/interface]
font-name='Noto Sans 10'
document-font-name='Noto Sans 10'
monospace-font-name='Noto Sans Mono 10'

[org/gnome/desktop/wm/preferences]
titlebar-font='Noto Sans Bold 10'

[org/gnome/shell]
disable-user-extensions=false

[org/gnome/shell]
favorite-apps=['org.gnome.Nautilus.desktop', 'firefox.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.TextEditor.desktop', 'code.desktop']

[org/gnome/shell]
enabled-extensions=['appindicatorsupport@rgcjonas.gmail.com', 'dark-variant@hardpixel.eu', 'gsconnect@andyholmes.github.io', 'rounded-window-corners@yilozt', 'legacyschemeautoswitcher@joshimukul29.gmail.com']

[org/gnome/shell/extensions/dark-variant]
applications=['code.desktop', 'code-oss.desktop', 'visual-studio-code.desktop', 'rest.insomnia.Insomnia.desktop', 'io.podman_desktop.PodmanDesktop.desktop', 'com.spotify.Client.desktop', 'org.gimp.GIMP.desktop', 'com.heroicgameslauncher.hgl.desktop', 'md.obsidian.Obsidian.desktop', 'obsidian.desktop', 'godot.desktop', 'org.godotengine.Godot.desktop', 'org.blender.Blender.desktop' ,'blender.desktop', 'com.discordapp.Discord.desktop']

[org/gnome/terminal/legacy]
theme-variant='dark'

[org/gnome/terminal/legacy/keybindings]
next-tab='<Primary>Tab'

[org/gnome/settings-daemon/plugins/media-keys]
custom-keybindings=['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/']

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0]
binding='<Super>Return'
command='gnome-terminal'
name='Gnome Terminal'

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1]
binding='<Super>E'
command='nautilus'
name='Nautilus'

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2]
binding='<Shift><Control>Escape'
command='gnome-system-monitor'
name='Gnome System Monitor'

[org/gnome/desktop/app-folders]
folder-children=['Office', 'Dev', 'Media', 'System', 'Gaming', 'Emulators']

[org/gnome/desktop/app-folders/folders/Office]
name='Office'
apps=['com.github.flxzt.rnote.desktop', 'org.gnome.Evince.desktop', 'org.gnome.Calculator.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Calendar.desktop', 'org.gnome.clocks.desktop', 'md.obsidian.Obsidian.desktop', 'org.libreoffice.LibreOffice.base.desktop', 'org.libreoffice.LibreOffice.calc.desktop', 'org.libreoffice.LibreOffice.draw.desktop', 'org.libreoffice.LibreOffice.impress.desktop', 'org.libreoffice.LibreOffice.math.desktop', 'org.libreoffice.LibreOffice.writer.desktop', 'org.libreoffice.LibreOffice.desktop']

[org/gnome/desktop/app-folders/folders/Dev]
name='Dev'
apps=['code.desktop', 'rest.insomnia.Insomnia.desktop', 'com.github.marhkb.Pods.desktop', 'org.gaphor.Gaphor.desktop', 'org.gnome.gitg.desktop', 'org.gnome.Boxes.desktop']

[org/gnome/desktop/app-folders/folders/Media]
name='Media'
apps=['io.github.celluloid_player.Celluloid.desktop', 'io.github.seadve.Kooha.desktop', 'com.spotify.Client.desktop', 'org.blender.Blender.desktop', 'org.gimp.GIMP.desktop', 'org.gnome.eog.desktop']

[org/gnome/desktop/app-folders/folders/System]
name='System'
apps=['org.gnome.baobab.desktop', 'firewall-config.desktop', 'com.mattjakeman.ExtensionManager.desktop', 'org.gnome.Settings.desktop', 'gnome-system-monitor.desktop', 'org.gnome.Characters.desktop', 'org.gnome.DiskUtility.desktop', 'org.gnome.font-viewer.desktop', 'org.gnome.Logs.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'kvantummanager.desktop']

[org/gnome/desktop/app-folders/folders/Gaming]
name='Gaming'
apps=['com.valvesoftware.Steam.desktop', 'com.heroicgameslauncher.hgl.desktop', 'net.lutris.Lutris.desktop']

[org/gnome/desktop/app-folders/folders/Emulators]
name='Emulators'
apps=['org.duckstation.DuckStation.desktop', 'net.pcsx2.PCSX2.desktop', 'org.ppsspp.PPSSPP.desktop', 'org.DolphinEmu.dolphin-emu.desktop', 'org.yuzu_emu.yuzu.desktop', 'org.citra_emu.citra.desktop', 'org.flycast.Flycast.desktop', 'app.xemu.xemu.desktop', 'com.snes9x.Snes9x.desktop', 'net.kuribo64.melonDS.desktop', 'net.rpcs3.RPCS3.desktop']

[org/gnome/shell]
app-picker-layout=[{'Dev': <{'position': <0>}>, 'Emulators': <{'position': <1>}>, 'Gaming': <{'position': <2>}>, 'Media': <{'position': <3>}>, 'Office': <{'position': <4>}>}]

[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/gnome/blobs-l.svg'
picture-uri-dark='file:///usr/share/backgrounds/gnome/blobs-d.svg'
primary-color='#241f31'

[org/gnome/desktop/screensaver]
picture-uri='file:///usr/share/backgrounds/gnome/blobs-l.svg'
primary-color='#241f31'

[org/gnome/shell]
disable-extension-version-validation=true

[org/gnome/desktop/interface]
font-antialiasing='rgba'
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