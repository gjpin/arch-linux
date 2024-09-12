#!/usr/bin/bash

read -p "Gaming (yes / no): " GAMING
export GAMING

################################################
##### Installation
################################################

# References
# https://wiki.archlinux.org/title/Flatpak
# https://github.com/containers/bubblewrap/issues/324

# Install Flatpak and applications
sudo pacman -S --noconfirm flatpak xdg-desktop-portal-gtk
systemctl --user enable --now xdg-desktop-portal.service

# Add Flathub repositories
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak update

# Import global Flatpak overrides
mkdir -p ${HOME}/.local/share/flatpak/overrides
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/global -o ${HOME}/.local/share/flatpak/overrides/global

################################################
##### Applications / Runtimes
################################################

# Install Flatpak runtimes
sudo flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full//23.08
sudo flatpak install -y flathub org.freedesktop.Platform.GStreamer.gstreamer-vaapi//23.08
sudo flatpak install -y flathub org.freedesktop.Platform.GL.default//23.08-extra
sudo flatpak install -y flathub org.freedesktop.Platform.GL32.default//23.08-extra
sudo flatpak install -y flathub org.freedesktop.Sdk//23.08

if lspci | grep VGA | grep "Intel" > /dev/null; then
  sudo flatpak install -y flathub org.freedesktop.Platform.VAAPI.Intel//23.08
fi

# Install applications (Gnome only)
if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
    sudo flatpak install -y flathub com.mattjakeman.ExtensionManager
    sudo flatpak install -y flathub com.github.tchx84.Flatseal
    sudo flatpak install -y flathub io.bassi.Amberol

    # Install Gaphor
    sudo flatpak install -y flathub org.gaphor.Gaphor
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/org.gaphor.Gaphor -o ${HOME}/.local/share/flatpak/overrides/org.gaphor.Gaphor

    # Install Rnote
    sudo flatpak install -y flathub com.github.flxzt.rnote
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.github.flxzt.rnote -o ${HOME}/.local/share/flatpak/overrides/com.github.flxzt.rnote
fi

# Install applications (KDE Plasma only)
if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
    # Install Okular
    sudo flatpak install -y flathub org.kde.okular
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/org.kde.okular -o ${HOME}/.local/share/flatpak/overrides/org.kde.okular
    xdg-mime default org.kde.okular.desktop application/pdf
fi

# Install applications
sudo flatpak install -y flathub com.bitwarden.desktop
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.bitwarden.desktop -o ${HOME}/.local/share/flatpak/overrides/com.bitwarden.desktop

sudo flatpak install -y flathub com.belmoussaoui.Authenticator
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.belmoussaoui.Authenticator -o ${HOME}/.local/share/flatpak/overrides/com.belmoussaoui.Authenticator

sudo flatpak install -y flathub org.keepassxc.KeePassXC
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/org.keepassxc.KeePassXC -o ${HOME}/.local/share/flatpak/overrides/org.keepassxc.KeePassXC

sudo flatpak install -y flathub com.spotify.Client
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.spotify.Client -o ${HOME}/.local/share/flatpak/overrides/com.spotify.Client

sudo flatpak install -y flathub org.gimp.GIMP
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/org.gimp.GIMP -o ${HOME}/.local/share/flatpak/overrides/org.gimp.GIMP

sudo flatpak install -y flathub org.blender.Blender
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/org.blender.Blender -o ${HOME}/.local/share/flatpak/overrides/org.blender.Blender

sudo flatpak install -y flathub com.brave.Browser
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.brave.Browser -o ${HOME}/.local/share/flatpak/overrides/com.brave.Browser

sudo flatpak install -y flathub md.obsidian.Obsidian
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/md.obsidian.Obsidian -o ${HOME}/.local/share/flatpak/overrides/md.obsidian.Obsidian

sudo flatpak install -y flathub com.usebruno.Bruno
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.usebruno.Bruno -o ${HOME}/.local/share/flatpak/overrides/com.usebruno.Bruno

sudo flatpak install -y flathub io.kinvolk.Headlamp
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/io.kinvolk.Headlamp -o ${HOME}/.local/share/flatpak/overrides/io.kinvolk.Headlamp

sudo flatpak install -y flathub org.libreoffice.LibreOffice
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/org.libreoffice.LibreOffice -o ${HOME}/.local/share/flatpak/overrides/org.libreoffice.LibreOffice

################################################
##### Firefox
################################################

# References:
# https://github.com/rafaelmardojai/firefox-gnome-theme

# Install Firefox
sudo flatpak install -y flathub org.mozilla.firefox

# Set Firefox as default browser and handler for http/s
xdg-settings set default-web-browser org.mozilla.firefox.desktop
xdg-mime default org.mozilla.firefox.desktop x-scheme-handler/http
xdg-mime default org.mozilla.firefox.desktop x-scheme-handler/https

# Temporarily open firefox to create profile
timeout 5 flatpak run org.mozilla.firefox --headless

# Set Firefox profile path
export FIREFOX_PROFILE_PATH=$(find ${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox -type d -name "*.default-release")

# Import extensions
mkdir -p ${FIREFOX_PROFILE_PATH}/extensions
curl https://addons.mozilla.org/firefox/downloads/file/4003969/ublock_origin-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/uBlock0@raymondhill.net.xpi
curl https://addons.mozilla.org/firefox/downloads/file/4018008/bitwarden_password_manager-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/{446900e4-71c2-419f-a6a7-df9c091e268b}.xpi
curl https://addons.mozilla.org/firefox/downloads/file/3998783/floccus-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/floccus@handmadeideas.org.xpi
curl https://addons.mozilla.org/firefox/downloads/file/3932862/multi_account_containers-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/@testpilot-containers.xpi

# Import Firefox configs
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/firefox/user.js -o ${FIREFOX_PROFILE_PATH}/user.js

# Desktop environment specific configurations
if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
    # Install Firefox Gnome theme
    paru -S --noconfirm firefox-gnome-theme

    # Firefox Gnome theme integration
    mkdir -p ${FIREFOX_PROFILE_PATH}/chrome
    ln -s /usr/lib/firefox-gnome-theme ${FIREFOX_PROFILE_PATH}/chrome/firefox-gnome-theme
    echo '@import "firefox-gnome-theme/userChrome.css"' > ${FIREFOX_PROFILE_PATH}/chrome/userChrome.css
    echo '@import "firefox-gnome-theme/userContent.css"' > ${FIREFOX_PROFILE_PATH}/chrome/userContent.css
    curl -sSL https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/firefox/gnome.js >> ${FIREFOX_PROFILE_PATH}/user.js
elif [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
    # Better KDE Plasma integration
    curl -sSL https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/firefox/plasma.js >> ${FIREFOX_PROFILE_PATH}/user.js
fi

################################################
##### GTK theming
################################################

# Install GTK themes
if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
    sudo flatpak install -y org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark
elif [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
    sudo flatpak install -y flathub org.gtk.Gtk3theme.Breeze org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark
fi

################################################
##### Gaming utilities
################################################

# References:
# https://wiki.archlinux.org/title/MangoHud

if [ ${GAMING} = "yes" ]; then
    # Install MangoHud
    sudo flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud//23.08

    # Install Gamescope
    sudo flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.gamescope//23.08
fi

################################################
##### Steam
################################################

if [ ${GAMING} = "yes" ]; then
    if [ ! -e "/usr/bin/steam" ]; then
        # Install Steam
        sudo flatpak install -y flathub com.valvesoftware.Steam

        # Import Steam Flatpak overrides
        curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.valvesoftware.Steam -o ${HOME}/.local/share/flatpak/overrides/com.valvesoftware.Steam

        # Steam controllers udev rules
        sudo curl -sSL https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-input.rules -o /etc/udev/rules.d/60-steam-input.rules
        sudo curl -sSL https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-vr.rules -o /etc/udev/rules.d/60-steam-vr.rules

        # Configure MangoHud for Steam
        mkdir -p ${HOME}/.var/app/com.valvesoftware.Steam/config/MangoHud
        curl -sSL https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/mangohud/MangoHud.conf -o ${HOME}/.var/app/com.valvesoftware.Steam/config/MangoHud/MangoHud.conf
    fi
fi

################################################
##### Heroic Games Launcher
################################################

if [ ${GAMING} = "yes" ]; then
    # Install Heroic Games Launcher
    sudo flatpak install -y flathub com.heroicgameslauncher.hgl

    # Create directory for Heroic games
    mkdir -p ${HOME}/Games/Heroic/{Epic,GOG}

    # Create directory for Heroic Prefixes
    mkdir -p ${HOME}/Games/Heroic/Prefixes/{Epic,GOG}

    # Import Flatpak overrides
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.heroicgameslauncher.hgl -o ${HOME}/.local/share/flatpak/overrides/com.heroicgameslauncher.hgl

    # Configure MangoHud for Heroic
    mkdir -p ${HOME}/.var/app/com.heroicgameslauncher.hgl/config/MangoHud
    curl -sSL https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/mangohud/MangoHud.conf -o ${HOME}/.var/app/com.heroicgameslauncher.hgl/config/MangoHud/MangoHud.conf
fi

################################################
##### ALVR
################################################

# References:
# https://github.com/alvr-org/ALVR/wiki/Installing-ALVR-and-using-SteamVR-on-Linux-through-Flatpak

if [ ${GAMING} = "yes" ]; then
    if [ ! -e "/usr/bin/alvr_dashboard" ]; then
        # Install dependencies
        sudo flatpak install -y flathub org.freedesktop.Sdk.Extension.llvm16//23.08
        sudo flatpak install -y flathub org.freedesktop.Sdk.Extension.rust-stable//23.0

        # Download ALVR flatpak
        curl https://github.com/alvr-org/ALVR/releases/latest/download/com.valvesoftware.Steam.Utility.alvr.flatpak -L -O

        # Install ALVR
        sudo flatpak install -y --bundle com.valvesoftware.Steam.Utility.alvr.flatpak

        # Remove ALVR flatpak
        rm -f com.valvesoftware.Steam.Utility.alvr.flatpak

        # Create ALVR shortcut
        curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/alvr/alvr-flatpak.desktop -o ${HOME}/.local/share/applications/alvr.desktop

        # Create ALVR dashboard alias
        echo 'alias alvr="flatpak run --command=alvr_dashboard com.valvesoftware.Steam"' | tee ${HOME}/.zshrc.d/alvr
    fi
fi