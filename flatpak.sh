#!/usr/bin/bash

################################################
##### Installation
################################################

# References
# https://wiki.archlinux.org/title/Flatpak
# https://github.com/containers/bubblewrap/issues/324

# Install Flatpak
sudo pacman -S --noconfirm flatpak flatpak-builder xdg-desktop-portal-gtk
systemctl --user enable --now xdg-desktop-portal.service

# Add Flathub repositories
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak update

# Import global Flatpak overrides
mkdir -p ${HOME}/.local/share/flatpak/overrides
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/global -o ${HOME}/.local/share/flatpak/overrides/global

# Add KDE specific global configurations
if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
mkdir -p ${HOME}/.config/xdg-desktop-portal
tee -a ${HOME}/.config/xdg-desktop-portal/portals.conf << 'EOF'
[preferred]
default=kde
org.freedesktop.impl.portal.FileChooser=kde
EOF
fi

################################################
##### Applications / Runtimes
################################################

# Install Flatpak runtimes
flatpak install -y flathub org.freedesktop.Platform.ffmpeg-full//24.08
flatpak install -y flathub org.freedesktop.Platform.GL.default//24.08extra
flatpak install -y flathub org.freedesktop.Platform.GL32.default//24.08extra
flatpak install -y flathub org.freedesktop.Sdk//24.08

if lspci | grep VGA | grep "Intel" > /dev/null; then
  flatpak install -y flathub org.freedesktop.Platform.VAAPI.Intel//24.08
fi

# Install DE specific applications
if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
    # Install Flatseal
    flatpak install -y flathub com.github.tchx84.Flatseal

    # Install Seabird
    flatpak install -y flathub dev.skynomads.Seabird
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/dev.skynomads.Seabird -o ${HOME}/.local/share/flatpak/overrides/dev.skynomads.Seabird
fi

# Install applications
flatpak install -y flathub com.bitwarden.desktop
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.bitwarden.desktop -o ${HOME}/.local/share/flatpak/overrides/com.bitwarden.desktop

flatpak install -y flathub org.keepassxc.KeePassXC
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/org.keepassxc.KeePassXC -o ${HOME}/.local/share/flatpak/overrides/org.keepassxc.KeePassXC

flatpak install -y flathub com.spotify.Client
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.spotify.Client -o ${HOME}/.local/share/flatpak/overrides/com.spotify.Client

flatpak install -y flathub org.gimp.GIMP
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/org.gimp.GIMP -o ${HOME}/.local/share/flatpak/overrides/org.gimp.GIMP

flatpak install -y flathub com.brave.Browser
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.brave.Browser -o ${HOME}/.local/share/flatpak/overrides/com.brave.Browser

flatpak install -y flathub com.discordapp.Discord
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.discordapp.Discord -o ${HOME}/.local/share/flatpak/overrides/com.discordapp.Discord

# Install development applications
flatpak install -y flathub io.podman_desktop.PodmanDesktop
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/io.podman_desktop.PodmanDesktop -o ${HOME}/.local/share/flatpak/overrides/io.podman_desktop.PodmanDesktop

flatpak install -y flathub com.usebruno.Bruno
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.usebruno.Bruno -o ${HOME}/.local/share/flatpak/overrides/com.usebruno.Bruno

flatpak install -y flathub io.kinvolk.Headlamp
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/io.kinvolk.Headlamp -o ${HOME}/.local/share/flatpak/overrides/io.kinvolk.Headlamp

################################################
##### Firefox
################################################

# References:
# https://github.com/rafaelmardojai/firefox-gnome-theme
# Theme is manually installed and not from AUR, since Firefox flatpak cannot access it

# Install Firefox
flatpak install -y flathub org.mozilla.firefox
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/org.mozilla.firefox -o ${HOME}/.local/share/flatpak/overrides/org.mozilla.firefox

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
    # Firefox Gnome theme integration
    mkdir -p ${FIREFOX_PROFILE_PATH}/chrome
    git clone https://github.com/rafaelmardojai/firefox-gnome-theme.git ${FIREFOX_PROFILE_PATH}/chrome/firefox-gnome-theme
    echo '@import "firefox-gnome-theme/userChrome.css"' > ${FIREFOX_PROFILE_PATH}/chrome/userChrome.css
    echo '@import "firefox-gnome-theme/userContent.css"' > ${FIREFOX_PROFILE_PATH}/chrome/userContent.css
    curl -sSL https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/firefox/gnome.js >> ${FIREFOX_PROFILE_PATH}/user.js

    # Firefox theme updater
    sudo tee -a /usr/local/bin/update-all << 'EOF'

################################################
##### Firefox
################################################

# Update Firefox theme
FIREFOX_PROFILE_PATH=$(realpath ${HOME}/.var/app/org.mozilla.firefox/.mozilla/firefox/*.default-release)
git -C ${FIREFOX_PROFILE_PATH}/chrome/firefox-gnome-theme pull
EOF
elif [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
    # Better KDE Plasma integration
    curl -sSL https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/firefox/plasma.js >> ${FIREFOX_PROFILE_PATH}/user.js
fi

################################################
##### GTK theming
################################################

# Install GTK themes
if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
    flatpak install -y org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark
elif [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
    flatpak install -y flathub org.gtk.Gtk3theme.Breeze org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark
fi

################################################
##### Gaming utilities
################################################

# References:
# https://wiki.archlinux.org/title/MangoHud

if [[ -d "${HOME}/.var/app/com.valvesoftware.Steam" || -f "/usr/bin/steam" ]]; then
    # Install MangoHud
    flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.MangoHud//24.08

    # Install Gamescope
    flatpak install -y flathub org.freedesktop.Platform.VulkanLayer.gamescope//24.08

    # Install ProtonUp-Qt
    flatpak install -y flathub net.davidotek.pupgui2
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/net.davidotek.pupgui2 -o ${HOME}/.local/share/flatpak/overrides/net.davidotek.pupgui2

    # Install Protontricks
    flatpak install -y flathub com.github.Matoking.protontricks
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.github.Matoking.protontricks -o ${HOME}/.local/share/flatpak/overrides/com.github.Matoking.protontricks
fi

################################################
##### Steam
################################################

if [[ -d "${HOME}/.var/app/com.valvesoftware.Steam" || -f "/usr/bin/steam" ]]; then
    if [ ! -e "/usr/bin/steam" ]; then
        # Install Steam
        flatpak install -y flathub com.valvesoftware.Steam
        curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.valvesoftware.Steam -o ${HOME}/.local/share/flatpak/overrides/com.valvesoftware.Steam

        # Steam controllers udev rules
        sudo curl -sSL https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-input.rules -o /etc/udev/rules.d/60-steam-input.rules
        sudo curl -sSL https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-vr.rules -o /etc/udev/rules.d/60-steam-vr.rules

        # Configure MangoHud for Steam
        mkdir -p ${HOME}/.var/app/com.valvesoftware.Steam/config/MangoHud
        curl -sSL https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/mangohud/MangoHud.conf -o ${HOME}/.var/app/com.valvesoftware.Steam/config/MangoHud/MangoHud.conf

        if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
            flatpak install -y flathub io.github.Foldex.AdwSteamGtk
            curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/io.github.Foldex.AdwSteamGtk -o ${HOME}/.local/share/flatpak/overrides/io.github.Foldex.AdwSteamGtk
        fi
    fi
fi

################################################
##### Heroic Games Launcher
################################################

if [[ -d "${HOME}/.var/app/com.valvesoftware.Steam" || -f "/usr/bin/steam" ]]; then
    # Install Heroic Games Launcher
    flatpak install -y flathub com.heroicgameslauncher.hgl

    # Create directories for Heroic games and prefixes
    mkdir -p ${HOME}/Games/Heroic/Prefixes

    # Import Flatpak overrides
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.heroicgameslauncher.hgl -o ${HOME}/.local/share/flatpak/overrides/com.heroicgameslauncher.hgl

    # Configure MangoHud for Heroic
    mkdir -p ${HOME}/.var/app/com.heroicgameslauncher.hgl/config/MangoHud
    curl -sSL https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/mangohud/MangoHud.conf -o ${HOME}/.var/app/com.heroicgameslauncher.hgl/config/MangoHud/MangoHud.conf
fi

################################################
##### Bottles
################################################

if [[ -d "${HOME}/.var/app/com.valvesoftware.Steam" || -f "/usr/bin/steam" ]]; then
    # Install Bottles
    flatpak install -y flathub com.usebottles.bottles

    # Create directories for Bottles
    mkdir -p ${HOME}/Games/Bottles

    # Import Flatpak overrides
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/com.usebottles.bottles -o ${HOME}/.local/share/flatpak/overrides/com.usebottles.bottles

    # Configure MangoHud for Bottles
    mkdir -p ${HOME}/.var/app/com.usebottles.bottles/config/MangoHud
    curl -sSL https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/mangohud/MangoHud.conf -o ${HOME}/.var/app/com.usebottles.bottles/config/MangoHud/MangoHud.conf
fi