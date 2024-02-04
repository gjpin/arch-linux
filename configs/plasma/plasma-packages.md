# get KDE packages

# https://download.kde.org/stable/plasma/

# packages=$(curl -s https://download.kde.org/stable/plasma/5.27.10/ | grep -o -P '(?<=<a href=")(.*)(?=-5.27.10.tar.xz.sig"><img)')

# packages to remove from Plasma Desktop:

# https://community.kde.org/Distributions/Packaging_Recommendations#Plasma_packages

# echo "${packages}" | sed -e '/aura-browser\|plank-player\|plasma-bigscreen\|plasma-mobile\|plasma-nano\|plasma-remotecontrollers\|plasma-sdk\|plasma-tests/d'

# Plasma packages

# filtered from above

bluedevil
breeze
breeze-grub # skip
breeze-gtk
breeze-plymouth # skip
discover # skip
drkonqi
flatpak-kcm
kactivitymanagerd
kde-cli-tools
kde-gtk-config
kdecoration
kdeplasma-addons
kgamma5
khotkeys
kinfocenter
kmenuedit
kpipewire
kscreen
kscreenlocker
ksshaskpass
ksystemstats
kwallet-pam
kwayland-integration
kwin
kwrited
layer-shell-qt
libkscreen
libksysguard
milou
oxygen # skip
oxygen-sounds # skip
plasma-browser-integration
plasma-desktop
plasma-disks
plasma-firewall
plasma-integration
plasma-nm
plasma-pa
plasma-systemmonitor
plasma-thunderbolt
plasma-vault
plasma-welcome # skip
plasma-workspace
plasma-workspace-wallpapers
plymouth-kcm # skip
polkit-kde-agent-1 # polkit-kde-agent
powerdevil
sddm-kcm
systemsettings
xdg-desktop-portal-kde

# Non-Plasma packages

# https://community.kde.org/Distributions/Packaging_Recommendations#Non-Plasma_packages

baloo-widgets
dolphin-plugins
ffmpegthumbs
kde-inotify-survey
kdeconnect-kde # kdeconnect
kdegraphics-thumbnailers
kdenetwork-filesharing
kdepim-addons # skip
kio-admin
kio-extras
kio-fuse
kio-gdrive # skip
libappindicator-gtk3
phonon-vlc # phonon-qt5-vlc
print-manager # skip

# 3rd-party packages

# https://community.kde.org/Distributions/Packaging_Recommendations#3rd-party_packages

iio-sensor-proxy
noto-sans # noto-fonts
noto-color-emoji # noto-fonts-emoji
maliit-keyboard # skip
power-profiles-daemon
xdg-desktop-portal-gtk
xsettingsd

# KDE applications

# https://apps.kde.org/

konsole # terminal
okular # document viewer
dolphin # file manager
ark # archiving tool
kate # text editor
spectacle # screenshot capture utility
plasma-systemmonitor # system monitor
gwenview # image viewer
kcalc # calculator
kwalletmanager # wallet management tool
kcolorchooser # color chooser
partitionmanager # partition editor

# firefox (about:config)

widget.use-xdg-desktop-portal.file-picker=1
media.hardwaremediakeys.enabled=false
