#!/bin/bash

echo "Downloading and running base script"
wget https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/2_base.sh
chmod +x 2_base.sh
sh ./2_base.sh

echo "Installing sway and additional packages"
sudo pacman -S --noconfirm sway swaylock swayidle waybar rofi light pulseaudio pavucontrol slurp grim

echo "Ricing sway"
mkdir -p ~/.config/sway
wget -P ~/.config/sway/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/sway/config

echo "Ricing waybar"
mkdir -p ~/.config/waybar
wget -P ~/.config/waybar/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/waybar/config
wget -P ~/.config/waybar/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/waybar/style.css

echo "Ricing rofi"
mkdir -p ~/.config/rofi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/rofi/base16-one-light.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/rofi/base16-onedark.rasi

echo "Enabling sway autostart"
touch ~/.bash_profile
tee -a ~/.bash_profile << EOF
# If running from tty1 start sway
if [ "$(tty)" = "/dev/tty1" ]; then
    _JAVA_AWT_WM_NONREPARENTING=1 sway
fi
EOF

echo "Ricing vim"
mkdir -p ~/.vim
wget -P ~/.vim https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/vim/vimrc
mkdir -p ~/.vim/colors
wget -P ~/.vim/colors https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/vim/base16-one-light.vim
wget -P ~/.vim/colors https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/vim/base16-onedark.vim

echo "Installing and ricing Alacritty terminal"
sudo pacman -S --noconfirm alacritty
mkdir -p ~/.config/alacritty/
wget -P ~/.config/alacritty/ https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/dotfiles/alacritty/alacritty.yml

echo "Installing thunar with auto-mount and archives creation/deflation support"
sudo pacman -S --noconfirm thunar gvfs thunar-volman thunar-archive-plugin ark file-roller xarchiver

echo "Installing PDF viewer"
sudo pacman -S --noconfirm xreader

echo "Downloading themes (Kali Linux theme without the dragon)"
# Kali themes source: https://gitlab.com/kalilinux/packages/kali-themes/-/tree/kali/master/share/themes
mkdir -p ~/.themes
wget -P ~/.themes https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/themes/kali-themes.tar.gz
tar -xzf ~/.themes/kali-themes.tar.gz -C ~/.themes
rm -f ~/.themes/kali-themes.tar.gz

echo "Downloading icon themes (Kali Linux icons)"
# Kali themes source: https://gitlab.com/kalilinux/packages/kali-themes/-/tree/kali/master/share/icons
mkdir -p ~/.icons
wget -P ~/.icons https://raw.githubusercontent.com/exah-io/minimal-arch-linux/master/icons/kali-icons.tar.gz
tar -xzf ~/.icons/kali-icons.tar.gz -C ~/.icons
rm -f ~/.icons/kali-icons.tar.gz

echo "Setting GTK theme, font and icons"
FONT="Cantarell Regular 10"
GTK_THEME="Kali-Light"
GTK_ICON_THEME="Flat-Remix-Blue-Dark"
GTK_SCHEMA="org.gnome.desktop.interface"
gsettings set $GTK_SCHEMA gtk-theme "$GTK_THEME"
gsettings set $GTK_SCHEMA icon-theme "$GTK_ICON_THEME"
gsettings set $GTK_SCHEMA font-name "$FONT"
gsettings set $GTK_SCHEMA document-font-name "$FONT"

echo "Enabling suspend and hibernate hotkeys"
sudo sed -i 's/#HandlePowerKey=poweroff/HandlePowerKey=hibernate/g' /etc/systemd/logind.conf
sudo sed -i 's/#HandleLidSwitch=suspend/HandleLidSwitch=suspend/g' /etc/systemd/logind.conf

echo "Blacklisting bluetooth modules"
sudo touch /etc/modprobe.d/nobt.conf
sudo tee -a /etc/modprobe.d/nobt.conf << END
blacklist btusb
blacklist bluetooth
END

echo "Enabling autologin"
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
sudo touch /etc/systemd/system/getty@tty1.service.d/override.conf
sudo tee -a /etc/systemd/system/getty@tty1.service.d/override.conf << END
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --skip-login --nonewline --noissue --autologin $USER --noclear %I $TERM
END

echo "Removing last login message"
touch ~/.hushlogin

echo "Installing xwayland"
sudo pacman -S --noconfirm xorg-server-xwayland

echo "Installing Thunderbird Flatpak with Wayland support"
flatpak --user --assumeyes install flathub org.mozilla.Thunderbird
flatpak override --user --env=MOZ_ENABLE_WAYLAND=1 org.mozilla.Thunderbird

echo "Setting automatic updates for Flatpak apps"
mkdir -p ~/.config/systemd/user/
touch ~/.config/systemd/user/flatpak-update.timer
tee -a ~/.config/systemd/user/flatpak-update.timer << EOF
[Unit]
Description=Flatpak update

[Timer]
OnCalendar=7:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

touch ~/.config/systemd/user/flatpak-update.service
tee -a ~/.config/systemd/user/flatpak-update.service << EOF
[Unit]
Description=Flatpak update

[Service]
Type=oneshot
ExecStart=/usr/bin/flatpak update -y
EOF

systemctl --user enable flatpak-update.timer
systemctl --user start flatpak-update.timer
