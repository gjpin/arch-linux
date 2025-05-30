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
# https://wiki.archlinux.org/title/GNOME/Keyring

pacman -S --noconfirm \
    baobab \
    papers \
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
    decibels \
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
    ptyxis \
    nautilus \
    snapshot \
    sushi \
    xdg-desktop-portal-gnome \
    xdg-user-dirs-gtk

# Additional Gnome/GTK packages
pacman -S --noconfirm \
    xdg-desktop-portal-gtk \
    webp-pixbuf-loader \
    seahorse \
    gitg

# Install and enable GDM
pacman -S --noconfirm gdm
systemctl enable gdm.service

# Enable SSH wrapper
sudo -u ${NEW_USER} systemctl --user enable gcr-ssh-agent.socket

# Configure Gnome's default file associations (based on shared-mime-info-gnome)
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/gnome/gnome-mimeapps.list -o /usr/share/applications/gnome-mimeapps.list

# Enable VRR
sudo -u ${NEW_USER} gsettings set org.gnome.mutter experimental-features "['variable-refresh-rate']"

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
##### Gnome Shell extensions
################################################

# Create Gnome shell extensions folder
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions

# Grand Theft Focus
# https://extensions.gnome.org/extension/5410/grand-theft-focus
curl -sSL https://extensions.gnome.org/extension-data/grand-theft-focuszalckos.github.com.v8.shell-extension.zip -o shell-extension.zip
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions/grand-theft-focus@zalckos.github.com
unzip shell-extension.zip -d /home/${NEW_USER}/.local/share/gnome-shell/extensions/grand-theft-focus@zalckos.github.com
rm -f shell-extension.zip

# Legacy (GTK3) Theme Scheme Auto Switcher
# https://extensions.gnome.org/extension/4998/legacy-gtk3-theme-scheme-auto-switcher/
curl -sSL https://extensions.gnome.org/extension-data/legacyschemeautoswitcherjoshimukul29.gmail.com.v10.shell-extension.zip -o shell-extension.zip
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions/legacyschemeautoswitcher@joshimukul29.gmail.com
unzip shell-extension.zip -d /home/${NEW_USER}/.local/share/gnome-shell/extensions/legacyschemeautoswitcher@joshimukul29.gmail.com
rm -f shell-extension.zip

# AppIndicator and KStatusNotifierItem Support
# https://extensions.gnome.org/extension/615/appindicator-support/
# https://src.fedoraproject.org/rpms/gnome-shell-extension-appindicator/blob/rawhide/f/gnome-shell-extension-appindicator.spec
pacman -S --noconfirm \
    libappindicator-gtk3 \
    gnome-shell-extension-appindicator

################################################
##### Themes and icons
################################################

# References:
# https://github.com/lassekongo83/adw-gtk3
# https://github.com/somepaulo/MoreWaita

# Install adw-gtk3
pacman -S --noconfirm adw-gtk-theme

# Install MoreWaita icon theme
sudo -u ${NEW_USER} paru -S --noconfirm morewaita-icon-theme

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

################################################
##### Autologin
################################################

# References:
# https://wiki.archlinux.org/title/GDM#Automatic_login

# Enable autologin
if [ ${AUTOLOGIN} = "yes" ]; then
tee /etc/gdm/custom.conf << EOF
# Enable automatic login for user
[daemon]
AutomaticLogin=${NEW_USER}
AutomaticLoginEnable=True
EOF
fi