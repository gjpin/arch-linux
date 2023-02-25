# Plasma packages
pacman -S --noconfirm \
    bluedevil \
    breeze \
    breeze-gtk \
    drkonqi \
    flatpak-kcm \
    kactivitymanagerd \
    kde-cli-tools \
    kde-gtk-config \
    kdecoration \
    kdeplasma-addons \
    kgamma5 \
    khotkeys \
    kinfocenter \
    kmenuedit \
    kpipewire \
    kscreen \
    kscreenlocker \
    ksshaskpass \
    ksystemstats \
    kwallet-pam \
    kwayland-integration \
    kwin \
    kwrited \
    layer-shell-qt \
    libkscreen \
    libksysguard \
    milou \
    plasma-browser-integration \
    plasma-desktop \
    plasma-disks \
    plasma-firewall \
    plasma-integration \
    plasma-nm \
    plasma-pa \
    plasma-systemmonitor \
    plasma-thunderbolt \
    plasma-vault \
    plasma-workspace \
    plasma-workspace-wallpapers \
    polkit-kde-agent \
    powerdevil \
    sddm-kcm \
    systemsettings \
    xdg-desktop-portal-kde

# Non-Plasma packages (add-ons, extensions, ...)
pacman -S --noconfirm \
    baloo-widgets \
    dolphin-plugins \
    ffmpegthumbs \
    kdeconnect \
    kdegraphics-thumbnailers \
    kdenetwork-filesharing \
    kio-extras \
    kio-fuse \
    libappindicator-gtk3 \
    phonon-qt5-vlc

# 3rd-party packages
pacman -S --noconfirm \
    iio-sensor-proxy \
    noto-fonts \
    noto-fonts-emoji \
    power-profiles-daemon \
    xdg-desktop-portal-gtk \
    xsettingsd

# KDE applications
pacman -S --noconfirm \
    ark \
    dolphin \
    gwenview \
    kate \
    kcalc \
    kcolorchooser \
    konsole \
    kwalletmanager \
    okular \
    partitionmanager \
    plasma-systemmonitor \
    spectacle

# Extra Plasma packages
pacman -S --noconfirm \
    plasma-wayland-session \
    sshfs
    
# Install VLC
pacman -S --noconfirm vlc

# Install and enable SDDM
pacman -S --noconfirm sddm sddm-kcm
systemctl enable sddm.service

# Run Qt applications with the Wayland plugin
pacman -S --noconfirm \
    qt5-wayland \
    qt6-wayland

tee -a /etc/environment << EOF

# Qt
QT_QPA_PLATFORM="wayland;xcb"
EOF

# Use the KDE Wallet to store ssh key passphrases
# https://wiki.archlinux.org/title/KDE_Wallet#Using_the_KDE_Wallet_to_store_ssh_key_passphrases
tee /home/${NEW_USER}/.config/autostart/ssh-add.desktop << EOF
[Desktop Entry]
Exec=ssh-add -q
Name=ssh-add
Type=Application
EOF

tee /home/${NEW_USER}/.config/environment.d/ssh_askpass.conf << EOF
SSH_ASKPASS='/usr/bin/ksshaskpass'
SSH_ASKPASS_REQUIRE=prefer
EOF

# Enable power profiles daemon
systemctl enable power-profiles-daemon.service

# Enable bluetooth
systemctl enable bluetooth.service

# Extra fonts
pacman -S --noconfirm \
    noto-fonts-cjk \
    noto-fonts-extra \
    ttf-liberation \
    otf-cascadia-code \
    ttf-sourcecodepro-nerd