#!/usr/bin/bash

################################################
##### AppArmor
################################################

# References:
# https://wiki.archlinux.org/title/AppArmor
# https://wiki.archlinux.org/title/Audit_framework
# https://github.com/roddhjav/apparmor.d

# Install AppArmor
pacman -S --noconfirm apparmor

# Enable AppArmor service
systemctl enable --now apparmor.service

# Enable AppArmor as default security model
sed -i "s|=system|& lsm=landlock,lockdown,yama,integrity,apparmor,bpf|" /boot/loader/entries/arch.conf
sed -i "s|=system|& lsm=landlock,lockdown,yama,integrity,apparmor,bpf|" /boot/loader/entries/arch-lts.conf

# Enable caching AppArmor profiles
sed -i "s|^#write-cache|write-cache|g" /etc/apparmor/parser.conf
sed -i "s|^#Optimize=compress-fast|Optimize=compress-fast|g" /etc/apparmor/parser.conf

# Install and enable Audit Framework
pacman -S --noconfirm audit

systemctl enable auditd.service

# Allow user to read audit logs and get desktop notification on DENIED actions
groupadd -r audit

gpasswd -a ${NEW_USER} audit

sed -i "s|^log_group.*|log_group = audit|g" /etc/audit/auditd.conf

pacman -S --noconfirm python-notify2 python-psutil

mkdir -p /home/${NEW_USER}/.config/autostart

tee /home/${NEW_USER}/.config/autostart/apparmor-notify.desktop << EOF
[Desktop Entry]
Type=Application
Name=AppArmor Notify
Comment=Receive on screen notifications of AppArmor denials
TryExec=aa-notify
Exec=aa-notify -p -s 1 -w 60 -f /var/log/audit/audit.log
StartupNotify=false
NoDisplay=true
EOF

# Install additional AppArmor profiles
sudo -u ${NEW_USER} paru -S --noconfirm apparmor.d-git

################################################
##### homed
################################################

# https://wiki.archlinux.org/title/Systemd-homed
# https://www.freedesktop.org/software/systemd/man/latest/homectl.html

# Enable systemd-homed service
systemctl enable --now systemd-homed.service

# Create user record
# https://systemd.io/USER_RECORD/
tee /root/user_record << EOF
{
    "userName" : "${NEW_USER}",
    "enforcePasswordPolicy" : false,
    "secret" : {
        "password" : [
            "${NEW_USER_PASSWORD}"
        ]
    },
    "privileged" : {
        "hashedPassword" : [
            "$(echo "${NEW_USER_PASSWORD}" | mkpasswd --method=SHA-512 --stdin)"
        ]
    },
    "shell" : "/usr/bin/zsh",
    "storage": "luks",
    "memberOf" : [
        "${NEW_USER}",
        "wheel"
    ]
}
EOF

# Create user with provided user record
homectl create --identity=/root/user_record

# Remove user record
rm -f /root/user_record

# Add user to libvirt group
homectl update ${NEW_USER} -G libvirt

################################################
##### 32-bit packages + native steam/heroic
################################################

# Enable multilib repository
tee -a /etc/pacman.conf << EOF
[multilib]
Include = /etc/pacman.d/mirrorlist
EOF

# Install 32-bit packages
if lspci | grep "VGA" | grep "Intel" > /dev/null; then
    pacman -S --noconfirm lib32-vulkan-intel
elif lspci | grep "VGA" | grep "AMD" > /dev/null; then
    pacman -S --noconfirm lib32-vulkan-radeon
fi

pacman -S --noconfirm lib32-mesa

# Install Gamemode
pacman -S --noconfirm gamemode lib32-gamemode

# Install Gamescope
pacman -S --noconfirm gamescope

# Install MangoHud
pacman -S --noconfirm mangohud lib32-mangohud

# Configure MangoHud
# https://wiki.archlinux.org/title/MangoHud
mkdir -p /home/${NEW_USER}/.config/MangoHud

tee /home/${NEW_USER}/.config/MangoHud/MangoHud.conf << EOF
legacy_layout=0
horizontal
gpu_stats
cpu_stats
ram
fps
frametime=0
hud_no_margin
table_columns=14
frame_timing=1
engine_version
vulkan_driver
EOF

# Install Steam
pacman -S --noconfirm steam
pacman -Rs --noconfirm lib32-amdvlk

# Steam controllers udev rules
curl -sSL https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-input.rules -o /etc/udev/rules.d/60-steam-input.rules
udevadm control --reload-rules

# Install Heroic Games Launcher
sudo -u ${NEW_USER} paru -S --noconfirm heroic-games-launcher-bin

################################################
##### Firefox (native)
################################################

# References:
# https://wiki.archlinux.org/title/Firefox
# https://github.com/pyllyukko/user.js/blob/master/user.js

# Install Firefox
pacman -S --noconfirm firefox

# Set Firefox as default browser and handler for http/s
sudo -u ${NEW_USER} xdg-settings set default-web-browser firefox.desktop
sudo -u ${NEW_USER} xdg-mime default firefox.desktop x-scheme-handler/http
sudo -u ${NEW_USER} xdg-mime default firefox.desktop x-scheme-handler/https

# Run Firefox natively under Wayland
tee -a /home/${NEW_USER}/.zshenv << EOF

# Firefox
export MOZ_ENABLE_WAYLAND=1
EOF

# Temporarily open firefox to create profile folder
sudo -u ${NEW_USER} timeout 5 firefox --headless

# Set Firefox profile path
export FIREFOX_PROFILE_PATH=$(find /home/${NEW_USER}/.mozilla/firefox -type d -name "*.default-release")

# Import extensions
mkdir -p ${FIREFOX_PROFILE_PATH}/extensions
curl https://addons.mozilla.org/firefox/downloads/file/4003969/ublock_origin-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/uBlock0@raymondhill.net.xpi
curl https://addons.mozilla.org/firefox/downloads/file/4018008/bitwarden_password_manager-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/{446900e4-71c2-419f-a6a7-df9c091e268b}.xpi
curl https://addons.mozilla.org/firefox/downloads/file/3998783/floccus-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/floccus@handmadeideas.org.xpi
curl https://addons.mozilla.org/firefox/downloads/file/3932862/multi_account_containers-latest.xpi -o ${FIREFOX_PROFILE_PATH}/extensions/@testpilot-containers.xpi

# Import Firefox configs
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/firefox/user.js -o ${FIREFOX_PROFILE_PATH}/user.js

################################################
##### OpenSnitch
################################################

# Install OpenSnitch
pacman -S --noconfirm opensnitch

# Enable OpenSnitch
systemctl enable opensnitchd.service

# Autostart OpenSnitch UI
ln -s /usr/share/applications/opensnitch_ui.desktop /home/${NEW_USER}/.config/autostart/opensnitch_ui.desktop

# Import configs
mkdir -p /etc/opensnitchd
curl -O --output-dir /etc/opensnitchd https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/opensnitch/default-config.json

# Import rules
mkdir -p /etc/opensnitchd/rules

RULES=('bitwarden' 'chromium' 'curl' 'discord' 'dockerd' 'firefox' 'flatpak' 'fwupdmgr' 'git-remote-http' 'insomnia' 'networkmanager' 'obsidian' 'pacman' 'paru' 'plasmashell' 'ssh' 'syncthing' 'systemd-timesyncd' 'visual-studio-code' 'wireguard')
for RULE in "${RULES[@]}"
do
    curl -O --output-dir /etc/opensnitchd/rules https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/opensnitch/rules/${RULE}.json
done

################################################
##### Gnome Shell Extensions
################################################

# AppIndicator and KStatusNotifierItem Support
# https://extensions.gnome.org/extension/615/appindicator-support/
pacman -S --noconfirm libappindicator-gtk3
curl -sSL https://extensions.gnome.org/extension-data/appindicatorsupportrgcjonas.gmail.com.v56.shell-extension.zip -o shell-extension.zip
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions/appindicatorsupportrgcjonas.gmail.com
unzip shell-extension.zip -d /home/${NEW_USER}/.local/share/gnome-shell/extensions/appindicatorsupportrgcjonas.gmail.com
rm -f shell-extension.zip

# GSConnect
# https://extensions.gnome.org/extension/1319/gsconnect/
pacman -S --noconfirm openssl
curl -sSL https://extensions.gnome.org/extension-data/gsconnectandyholmes.github.io.v55.shell-extension.zip -o shell-extension.zip
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions/gsconnect@andyholmes.github.io
unzip shell-extension.zip -d /home/${NEW_USER}/.local/share/gnome-shell/extensions/gsconnect@andyholmes.github.io
rm -f shell-extension.zip

# Legacy (GTK3) Theme Scheme Auto Switcher
# https://extensions.gnome.org/extension/4998/legacy-gtk3-theme-scheme-auto-switcher/
curl -sSL https://extensions.gnome.org/extension-data/legacyschemeautoswitcherjoshimukul29.gmail.com.v7.shell-extension.zip -o shell-extension.zip
mkdir -p /home/${NEW_USER}/.local/share/gnome-shell/extensions/legacyschemeautoswitcher@joshimukul29.gmail.com
unzip shell-extension.zip -d /home/${NEW_USER}/.local/share/gnome-shell/extensions/legacyschemeautoswitcher@joshimukul29.gmail.com
rm -f shell-extension.zip

################################################
##### Wayland configurations
################################################

# References:
# https://wiki.archlinux.org/title/Wayland#Electron
# https://wiki.archlinux.org/title/wayland#XWayland

# Run Electron applications natively under Wayland
tee /home/${NEW_USER}/.config/electron-flags.conf << EOF
--enable-features=WaylandWindowDecorations
--ozone-platform-hint=auto
EOF

# Run VSCode under Wayland
ln -s /home/${NEW_USER}/.config/electron-flags.conf /home/${NEW_USER}/.config/code-flags.conf

################################################
##### Podman
################################################

# References:
# https://wiki.archlinux.org/title/Podman
# https://wiki.archlinux.org/title/Buildah
# https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md

# Install Podman and dependencies
pacman -S --noconfirm podman slirp4netns netavark aardvark-dns

# Install Podman Compose
pacman -S --noconfirm podman-compose podman-dnsname

# Install Buildah and dependencies
pacman -S --noconfirm buildah fuse-overlayfs

# Enable kernel.unprivileged_userns_clone
echo 'kernel.unprivileged_userns_clone=1' > /etc/sysctl.d/99-unprivileged-userns-clone.conf

# Set subuid and subgid
usermod --add-subuids 100000-165535 --add-subgids 100000-165535 ${NEW_USER}

# Enable unprivileged ping
echo 'net.ipv4.ping_group_range=0 165535' > /etc/sysctl.d/99-unprivileged-ping.conf

# Create docker/podman alias
tee /home/${NEW_USER}/.zshrc.d/podman << EOF
alias docker=podman
EOF

# Re-enable unqualified search registries
tee -a /etc/containers/registries.conf.d/00-unqualified-search-registries.conf << EOF
unqualified-search-registries = ["docker.io"]
EOF

tee -a /etc/containers/registries.conf.d/01-registries.conf << EOF
[[registry]]
location = "docker.io"
EOF

# Install Podman desktop
sudo -u ${NEW_USER} paru -S --noconfirm podman-desktop-bin

################################################
##### Gnome - Qt theming
################################################

# https://github.com/GabePoel/KvLibadwaita
# https://github.com/tsujan/Kvantum/blob/master/Kvantum/doc/Theme-Config

# Qt
pacman -S --noconfirm kvantum
sudo -u ${NEW_USER} paru -S --noconfirm kvantum-theme-libadwaita-git
mkdir -p /home/${NEW_USER}/Kvantum
echo 'theme=KvLibadwaita' >> /home/${NEW_USER}/Kvantum/kvantum.kvconfig
tee -a /etc/environment << EOF

# Qt
QT_QPA_PLATFORM=wayland
QT_STYLE_OVERRIDE=kvantum
XCURSOR_THEME=Adwaita
XCURSOR_SIZE=24
EOF

################################################
##### Hashicorp tools
################################################

# Install HashiCorp tools and vscode extensions
pacman -S --noconfirm terraform packer
sudo -u ${NEW_USER} xvfb-run code --install-extension HashiCorp.terraform
sudo -u ${NEW_USER} xvfb-run code --install-extension HashiCorp.HCL

################################################
##### Other apps
################################################

# Install Open Lens
flatpak install -y flathub dev.k8slens.OpenLens
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/dev.k8slens.OpenLens -o /home/${NEW_USER}/.local/share/flatpak/overrides/dev.k8slens.OpenLens

# Install Obsidian
flatpak install -y flathub md.obsidian.Obsidian
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/flatpak/md.obsidian.Obsidian -o /home/${NEW_USER}/.local/share/flatpak/overrides/md.obsidian.Obsidian