# get KDE packages

# https://download.kde.org/stable/plasma/

```
packages=$(curl -s https://download.kde.org/stable/plasma/6.3.4/ | grep -o -P '(?<=<a href=")(.*)(?=-6.3.4.tar.xz.sig"><img)')
```

# packages to remove from Plasma Desktop:

# https://community.kde.org/Distributions/Packaging_Recommendations#Plasma_packages

```
echo "${packages}" | sed -e '/aura-browser\|plank-player\|plasma-bigscreen\|plasma-mobile\|plasma-nano\|plasma-remotecontrollers\|plasma-sdk\|breeze-grub\|breeze-plymouth\|discover\|krdp\|plasma-dialer\|plasma-welcome\|plymouth-kcm\|spacebar\|plasma-tests/d'
```

# Plasma packages

# filtered from above

bluedevil
breeze
breeze-gtk
drkonqi
flatpak-kcm
kactivitymanagerd
kde-cli-tools
kde-gtk-config
kdecoration
kdeplasma-addons
kgamma
kglobalacceld
kinfocenter
kmenuedit
kpipewire
kscreen
kscreenlocker
ksshaskpass
ksystemstats
kwallet-pam
kwayland
kwayland-integration
kwin
kwrited
layer-shell-qt
libkscreen
libksysguard
libplasma
milou
ocean-sound-theme
oxygen
oxygen-sounds
plasma-activities
plasma-activities-stats
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
plasma-workspace
plasma-workspace-wallpapers
plasma5support
polkit-kde-agent-1
powerdevil
print-manager
qqc2-breeze-style
sddm-kcm
spectacle
systemsettings
wacomtablet
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
kimageformats
kio-admin
kio-extras
kio-fuse
kio-gdrive # skip
kwalletmanager
libappindicator-gtk3
phonon-vlc # phonon-qt6-vlc
qt-imageformats
xwaylandvideobridge

# 3rd-party packages

# https://community.kde.org/Distributions/Packaging_Recommendations#3rd-party_packages

icoutils
iio-sensor-proxy
noto-sans # noto-fonts. installed globally
noto-color-emoji # noto-fonts-emoji. installed globally
maliit-keyboard # skip
power-profiles-daemon # installed globally
switcheroo-control
xdg-desktop-portal-gtk
xsettingsd
orca # skip
systemd-coredumpd # cannot find in arch packages

# KDE applications

# https://apps.kde.org/

ark # archiving tool
dolphin # file manager
filelight # disk usage statistics
gwenview # image viewer
kate # text editor
kcalc # calculator
kcolorchooser # color chooser
kfind # find files/folders
kompare # diff/patch frontend
konsole # terminal
kwalletmanager # wallet management tool
okular # document viewer
partitionmanager # partition editor
plasma-systemmonitor # system monitor
spectacle # screenshot capture utility

# firefox (about:config)

widget.use-xdg-desktop-portal.file-picker=1
media.hardwaremediakeys.enabled=false
