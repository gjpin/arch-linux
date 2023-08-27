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
##### Docker
################################################

# References:
# https://wiki.archlinux.org/title/docker

# Install Docker
pacman -S --noconfirm docker docker-compose

# Enable Docker service
systemctl enable docker.service

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