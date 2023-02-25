# get KDE packages
# https://download.kde.org/stable/plasma/
# packages=$(curl -s https://download.kde.org/stable/plasma/5.27.1/ | grep -o -P '(?<=<a href=")(.*)(?=-5.27.1.tar.xz.sig"><img)')

# packages to remove from Plasma Desktop:
# https://community.kde.org/Distributions/Packaging_Recommendations#Plasma_packages
# echo "${packages}" | sed -e '/aura-browser\|plank-player\|plasma-bigscreen\|plasma-mobile\|plasma-nano\|plasma-remotecontrollers\|plasma-sdk\|plasma-tests\|qqc2-breeze-style/d'

# Plasma packages
# filtered from above
bluedevil
breeze
breeze-grub # nah
breeze-gtk
breeze-plymouth # nah
discover # nah
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
oxygen # nah
oxygen-sounds # nah
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
plasma-welcome # nah
plasma-workspace
plasma-workspace-wallpapers
plymouth-kcm # nah
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
kde-inotify-survey # available on AUR
kdeconnect-kde # kdeconnect
kdegraphics-thumbnailers
kdenetwork-filesharing
kdepim-addons # nah
kio-admin # available on AUR
kio-extras
kio-fuse
kio-gdrive # nah
libappindicator-gtk3
phonon-vlc # phonon-qt5-vlc
print-manager # nah

# 3rd-party packages
# https://community.kde.org/Distributions/Packaging_Recommendations#3rd-party_packages
iio-sensor-proxy
noto-sans # noto-fonts
noto-color-emoji # noto-fonts-emoji
maliit-keyboard # nah
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