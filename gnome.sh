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
    evince \
    file-roller \
    gnome-backgrounds \
    gnome-calculator \
    gnome-calendar \
    gnome-color-manager \
    gnome-console \
    gnome-control-center \
    gnome-disk-utility \
    gnome-font-viewer \
    gnome-keyring \
    gnome-logs \
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
    loupe \
    nautilus \
    snapshot \
    sushi \
    xdg-desktop-portal-gnome \
    xdg-user-dirs-gtk

# Additional Gnome/GTK packages
pacman -S --noconfirm \
    gitg \
    xdg-desktop-portal-gtk \
    webp-pixbuf-loader

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

# Configure  Gnome's default file associations (based on shared-mime-info-gnome)
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/gnome/gnome-mimeapps.list -o /usr/share/applications/gnome-mimeapps.list

################################################
##### Disable unneeded packages and services
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
flatpak install -y flathub com.mattjakeman.ExtensionManager
flatpak install -y flathub com.github.marhkb.Pods
flatpak install -y flathub com.github.tchx84.Flatseal
flatpak install -y flathub io.bassi.Amberol

################################################
##### Gnome Shell extensions
################################################

# Create Gnome shell extensions folder
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions

# Grand Theft Focus
# https://extensions.gnome.org/extension/5410/grand-theft-focus
curl -sSL https://extensions.gnome.org/extension-data/grand-theft-focuszalckos.github.com.v6.shell-extension.zip -o shell-extension.zip
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions/grand-theft-focus@zalckos.github.com
unzip shell-extension.zip -d /home/${NEW_USER}/.local/share/gnome-shell/extensions/grand-theft-focus@zalckos.github.com
rm -f shell-extension.zip

# Legacy (GTK3) Theme Scheme Auto Switcher
# https://extensions.gnome.org/extension/4998/legacy-gtk3-theme-scheme-auto-switcher/
curl -sSL https://extensions.gnome.org/extension-data/legacyschemeautoswitcherjoshimukul29.gmail.com.v8.shell-extension.zip -o shell-extension.zip
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions/legacyschemeautoswitcher@joshimukul29.gmail.com
unzip shell-extension.zip -d /home/${NEW_USER}/.local/share/gnome-shell/extensions/legacyschemeautoswitcher@joshimukul29.gmail.com
rm -f shell-extension.zip

# Tiling Shell
# https://extensions.gnome.org/extension/7065/tiling-shell/
curl -sSL https://extensions.gnome.org/extension-data/tilingshellferrarodomenico.com.v18.shell-extension.zip -o shell-extension.zip
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions/tilingshell@ferrarodomenico.com
unzip shell-extension.zip -d /home/${NEW_USER}/.local/share/gnome-shell/extensions/tilingshell@ferrarodomenico.com
rm -f shell-extension.zip

################################################
##### Firefox
################################################

# References:
# https://github.com/rafaelmardojai/firefox-gnome-theme

# Install Firefox Gnome theme
sudo -u ${NEW_USER} paru -S --noconfirm firefox-gnome-theme
# mkdir -p ${FIREFOX_PROFILE_PATH}/chrome
# ln -s /usr/lib/firefox-gnome-theme ${FIREFOX_PROFILE_PATH}/chrome/firefox-gnome-theme
# echo '@import "firefox-gnome-theme/userChrome.css"' > ${FIREFOX_PROFILE_PATH}/chrome/userChrome.css
# echo '@import "firefox-gnome-theme/userContent.css"' > ${FIREFOX_PROFILE_PATH}/chrome/userContent.css

# Gnome specific configurations
# tee -a ${FIREFOX_PROFILE_PATH}/user.js << 'EOF'

# // Firefox Gnome theme
# user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
# user_pref("browser.uidensity", 0);
# user_pref("svg.context-properties.content.enabled", true);
# user_pref("browser.theme.dark-private-windows", false);
# user_pref("widget.gtk.rounded-bottom-corners.enabled", true);
# user_pref("gnomeTheme.activeTabContrast", true);
# EOF

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
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/gnome/01-custom -o /etc/dconf/db/local.d/01-custom

# Laptop specific Gnome configurations
if cat /sys/class/dmi/id/chassis_type | grep 10 > /dev/null; then
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/gnome/01-laptop -o /etc/dconf/db/local.d/01-laptop
fi

# Update Gnome system databases
dconf update