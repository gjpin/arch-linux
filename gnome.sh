#!/usr/bin/bash

# References:
# https://wiki.archlinux.org/title/GNOME
# https://aur.archlinux.org/cgit/aur.git/tree/INSTALL.md?h=firefox-gnome-theme-git
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

################################################
##### Remove unneeded packages and services
################################################

# Disable ABRT service
systemctl mask abrtd.service

# Disable mobile broadband modem management service
systemctl mask ModemManager.service

# Disable PC/SC Smart Card service
systemctl mask pcscd.service

# Disable location lookup service
systemctl mask geoclue.service

# Disable speech dispatcher
sed -i "s|^# DisableAutoSpawn|DisableAutoSpawn|g" /etc/speech-dispatcher/speechd.conf

################################################
##### Flatpak
################################################

# Install applications
flatpak install -y flathub com.github.marhkb.Pods
flatpak install -y flathub com.mattjakeman.ExtensionManager

################################################
##### Gnome Shell extensions
################################################

# Create Gnome shell extensions folder
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions

# Grand Theft Focus
# # https://extensions.gnome.org/extension/5410/grand-theft-focus
curl -sSL https://extensions.gnome.org/extension-data/grand-theft-focuszalckos.github.com.v5.shell-extension.zip -o shell-extension.zip
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions/grand-theft-focus@zalckos.github.com
unzip shell-extension.zip -d /home/${NEW_USER}/.local/share/gnome-shell/extensions/grand-theft-focus@zalckos.github.com
rm -f shell-extension.zip

# Rounded Window Corners
# https://extensions.gnome.org/extension/5237/rounded-window-corners/
curl -sSL https://extensions.gnome.org/extension-data/rounded-window-cornersyilozt.v11.shell-extension.zip -o shell-extension.zip
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions/rounded-window-corners@yilozt
unzip shell-extension.zip -d /home/${NEW_USER}/.local/share/gnome-shell/extensions/rounded-window-corners@yilozt
rm -f shell-extension.zip

# Legacy (GTK3) Theme Scheme Auto Switcher
# https://extensions.gnome.org/extension/4998/legacy-gtk3-theme-scheme-auto-switcher/
curl -sSL https://extensions.gnome.org/extension-data/legacyschemeautoswitcherjoshimukul29.gmail.com.v7.shell-extension.zip -o shell-extension.zip
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions/legacyschemeautoswitcher@joshimukul29.gmail.com
unzip shell-extension.zip -d /home/${NEW_USER}/.local/share/gnome-shell/extensions/legacyschemeautoswitcher@joshimukul29.gmail.com
rm -f shell-extension.zip

################################################
##### Firefox
################################################

# References:
# https://github.com/rafaelmardojai/firefox-gnome-theme

# Install Firefox Gnome theme
sudo -u ${NEW_USER} paru -S --noconfirm firefox-gnome-theme
mkdir -p ${FIREFOX_PROFILE_PATH}/chrome
ln -s /usr/lib/firefox-gnome-theme ${FIREFOX_PROFILE_PATH}/chrome/firefox-gnome-theme
echo '@import "firefox-gnome-theme/userChrome.css"' > ${FIREFOX_PROFILE_PATH}/chrome/userChrome.css
echo '@import "firefox-gnome-theme/userContent.css"' > ${FIREFOX_PROFILE_PATH}/chrome/userContent.css

# Gnome specific configurations
tee -a ${FIREFOX_PROFILE_PATH}/user.js << 'EOF'

// Firefox Gnome theme
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.uidensity", 0);
user_pref("svg.context-properties.content.enabled", true);
user_pref("browser.theme.dark-private-windows", false);
user_pref("gnomeTheme.activeTabContrast", true);
EOF

################################################
##### GTK theme
################################################

# References:
# https://github.com/lassekongo83/adw-gtk3

# Install adw-gtk3 flatpak
flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3
flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3-dark

# Install adw-gtk3
sudo -u ${NEW_USER} paru -S --noconfirm adw-gtk3

################################################
##### Utilities
################################################

# Install gnome-randr
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/apps/gnome-randr.py -o /usr/local/bin/gnome-randr
chmod +x /usr/local/bin/gnome-randr

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
monospace-font-name='NotoSansM Nerd Font Mono 10'

[org/gnome/desktop/wm/preferences]
titlebar-font='NotoSansM Nerd Font Mono Medium 10'

[org/gnome/shell]
disable-user-extensions=false

[org/gnome/shell]
favorite-apps=['org.gnome.Nautilus.desktop', 'firefox.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.TextEditor.desktop', 'code.desktop']

[org/gnome/shell]
enabled-extensions=['grand-theft-focus@zalckos.github.com', 'rounded-window-corners@yilozt', 'legacyschemeautoswitcher@joshimukul29.gmail.com']

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

[org/gnome/desktop/search-provers]
disable-external=true

[org/freedesktop/Tracker3/Miner/Files]
index-single-directories="@as []"
index-recursive-directories="@as []"
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