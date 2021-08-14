#!/bin/bash

echo "Downloading and running base script"
wget https://raw.githubusercontent.com/gjpin/arch-linux/master/2_base.sh
chmod +x 2_base.sh
sh ./2_base.sh

echo "Downloading wallpaper"
mkdir -p ~/Pictures/wallpapers
wget -P ~/Pictures/wallpapers/ https://raw.githubusercontent.com/gjpin/arch-linux/master/images/wallpapers/Viktor_Forgacs.jpg

echo "Installing i3, dependencies and additional packages"
sudo pacman -S --noconfirm xorg xorg-xinit i3-gaps i3lock xorg-xbacklight feh maim rofi pulseaudio network-manager-applet xss-lock arandr pavucontrol brightnessctl #picom

echo "Installing picom-git"
paru -S --noconfirm picom-git

echo "Installing polybar"
paru -S --noconfirm polybar

echo "Configuring i3"
mkdir -p ~/.config/i3/
wget -P ~/.config/i3/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/i3/config

echo "Configuring picom"
mkdir -p ~/.config/picom
wget -P ~/.config/picom/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/picom/picom.conf

echo "Configuring polybar"
mkdir -p ~/.config/polybar/
wget -P ~/.config/polybar/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/polybar/config

echo "Ricing rofi"
mkdir -p ~/.config/rofi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/config.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/base16-one-light.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/base16-onedark.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/gruvbox-common.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/gruvbox-dark-hard.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/gruvbox-dark-soft.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/gruvbox-dark.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/gruvbox-light-hard.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/gruvbox-light-soft.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/gruvbox-light.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/ayu-light.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/ayu-dark.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/ayu-mirage.rasi
wget -P ~/.config/rofi/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/rofi/ayu-light-blue.rasi

echo "Enabling X server autostart"
sudo tee -a /etc/profile << EOF
if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
 exec startx
fi
EOF

echo "Configuring xinit"
wget -P ~/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/.xinitrc

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

echo "Installing and ricing Alacritty terminal"
sudo pacman -S --noconfirm alacritty
mkdir -p ~/.config/alacritty/
wget -P ~/.config/alacritty/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/alacritty/alacritty.yml

echo "Installing Gnome apps (file manager, pdf viewer, image viewer)"
sudo pacman -S --noconfirm nautilus filemanager-actions file-roller evince eog gedit gnome-calculator

echo "Changing GTK and icons themes"
sudo pacman -S --noconfirm lxappearance

mkdir -p ~/.themes
wget -P ~/.themes https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/themes-icons/Orchis-light.tar.xz
tar -xf ~/.themes/Orchis-light.tar.xz -C ~/.themes
rm -f ~/.themes/Orchis-light.tar.xz

mkdir -p ~/.local/share/icons/
wget -P ~/.local/share/icons/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/themes-icons/01-Tela.tar.xz
tar -xf ~/.local/share/icons/01-Tela.tar.xz -C ~/.local/share/icons/
rm -f ~/.local/share/icons/01-Tela.tar.xz

wget -P ~/.config/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/gtk/.gtkrc-2.0

mkdir -p ~/.config/gtk-3.0/
wget -P ~/.config/gtk-3.0/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/gtk/gtk-3.0/settings.ini

mkdir -p ~/.icons/default/
wget -P ~/.icons/default/ https://raw.githubusercontent.com/gjpin/arch-linux/master/dotfiles/gtk/index.theme

echo "Setting some default applications"
xdg-mime default eog.desktop image/jpeg
xdg-mime default eog.desktop image/jpg
xdg-mime default eog.desktop image/png
xdg-settings set default-web-browser firefox.desktop
xdg-mime default nautilus.desktop inode/directory

echo "Creating screenshots folder"
mkdir -p ~/Pictures/screenshots

# Source: https://aswinmohan.me/posts/better-fonts-on-linux/
echo "Improving font rendering"
sudo touch /etc/fonts/local.conf
sudo tee -a /etc/fonts/local.conf << EOF
<?xml version='1.0'?>
<!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
<fontconfig>

<match target="font">
  <edit name="autohint" mode="assign">
    <bool>true</bool>
  </edit>
  <edit name="hinting" mode="assign">
    <bool>true</bool>
  </edit>
  <edit mode="assign" name="hintstyle">
    <const>hintslight</const>
  </edit>
  <edit mode="assign" name="lcdfilter">
   <const>lcddefault</const>
 </edit>
</match>


<!-- Default sans-serif font -->
 <match target="pattern">
   <test qual="any" name="family"><string>-apple-system</string></test>
   <!--<test qual="any" name="lang"><string>ja</string></test>-->
   <edit name="family" mode="prepend" binding="same"><string>Roboto</string>  </edit>
 </match>

 <match target="pattern">
   <test qual="any" name="family"><string>Helvetica Neue</string></test>
   <!--<test qual="any" name="lang"><string>ja</string></test>-->
   <edit name="family" mode="prepend" binding="same"><string>Roboto</string>  </edit>
 </match>

 <match target="pattern">
   <test qual="any" name="family"><string>Helvetica</string></test>
   <!--<test qual="any" name="lang"><string>ja</string></test>-->
   <edit name="family" mode="prepend" binding="same"><string>Roboto</string>  </edit>
 </match>

 <match target="pattern">
   <test qual="any" name="family"><string>arial</string></test>
   <!--<test qual="any" name="lang"><string>ja</string></test>-->
   <edit name="family" mode="prepend" binding="same"><string>Roboto</string>  </edit>
 </match>

 <match target="pattern">
   <test qual="any" name="family"><string>sans-serif</string></test>
   <!--<test qual="any" name="lang"><string>ja</string></test>-->
   <edit name="family" mode="prepend" binding="same"><string>Roboto</string>  </edit>
 </match>
 
<!-- Default serif fonts -->
 <match target="pattern">
   <test qual="any" name="family"><string>serif</string></test>
   <edit name="family" mode="prepend" binding="same"><string>Noto Serif</string>  </edit>
   <edit name="family" mode="prepend" binding="same"><string>Noto Color Emoji</string>  </edit>
   <edit name="family" mode="append" binding="same"><string>IPAPMincho</string>  </edit>
   <edit name="family" mode="append" binding="same"><string>HanaMinA</string>  </edit>
   <edit name="family" mode="prepend" binding="same"><string>Roboto</string>  </edit>
 </match>

<!-- Default monospace fonts -->
 <match target="pattern">
   <test qual="any" name="family"><string>SFMono-Regular</string></test>
   <edit name="family" mode="prepend" binding="same"><string>Roboto Mono</string></edit>
   <edit name="family" mode="prepend" binding="same"><string>Space Mono</string></edit>
   <edit name="family" mode="append" binding="same"><string>Inconsolatazi4</string></edit>
   <edit name="family" mode="append" binding="same"><string>IPAGothic</string></edit>
 </match>

 <match target="pattern">
   <test qual="any" name="family"><string>Menlo</string></test>
   <edit name="family" mode="prepend" binding="same"><string>Roboto Mono</string></edit>
   <edit name="family" mode="prepend" binding="same"><string>Space Mono</string></edit>
   <edit name="family" mode="append" binding="same"><string>Inconsolatazi4</string></edit>
   <edit name="family" mode="append" binding="same"><string>IPAGothic</string></edit>
 </match>

 <match target="pattern">
   <test qual="any" name="family"><string>monospace</string></test>
   <edit name="family" mode="prepend" binding="same"><string>Roboto Mono</string></edit>
   <edit name="family" mode="prepend" binding="same"><string>Space Mono</string></edit>
   <edit name="family" mode="append" binding="same"><string>Inconsolatazi4</string></edit>
   <edit name="family" mode="append" binding="same"><string>IPAGothic</string></edit>
 </match>

<!-- Fallback fonts preference order -->
 <alias>
  <family>sans-serif</family>
  <prefer>
   <family>Noto Sans</family>
   <family>Noto Color Emoji</family>
   <family>Noto Emoji</family>
   <family>Open Sans</family>
   <family>Droid Sans</family>
   <family>Ubuntu</family>
   <family>Roboto</family>
   <family>NotoSansCJK</family>
   <family>Source Han Sans JP</family>
   <family>IPAPGothic</family>
   <family>VL PGothic</family>
   <family>Koruri</family>
  </prefer>
 </alias>
 <alias>
  <family>serif</family>
  <prefer>
   <family>Noto Serif</family>
   <family>Noto Color Emoji</family>
   <family>Noto Emoji</family>
   <family>Droid Serif</family>
   <family>Roboto Slab</family>
   <family>IPAPMincho</family>
  </prefer>
 </alias>
 <alias>
  <family>monospace</family>
  <prefer>
   <family>Noto Sans Mono</family>
   <family>Noto Color Emoji</family>
   <family>Noto Emoji</family>
   <family>Inconsolatazi4</family>
   <family>Ubuntu Mono</family>
   <family>Droid Sans Mono</family>
   <family>Roboto Mono</family>
   <family>IPAGothic</family>
  </prefer>
 </alias>

</fontconfig>
EOF

echo "Improving touchpad configuration"
echo "Confirm device ID "
sudo mkdir -p /etc/X11/xorg.conf.d/
sudo touch /etc/X11/xorg.conf.d/30-touchpad.conf
/etc/X11/xorg.conf.d/30-touchpad.conf << END
Section "InputClass"
    Identifier "CUST0001:00 06CB:76B1 Touchpad"
    Driver "libinput"
    Option "NaturalScrolling" "true"
    Option "Tapping" "on"
EndSection
END

if [[ $(cat /sys/class/dmi/id/chassis_type) -eq 10 ]]
then
echo "Enabling suspend and hibernate hotkeys"
sudo sed -i 's/#HandlePowerKey=poweroff/HandlePowerKey=hibernate/g' /etc/systemd/logind.conf
sudo sed -i 's/#HandleLidSwitch=suspend/HandleLidSwitch=suspend/g' /etc/systemd/logind.conf

echo "Blacklisting bluetooth modules"
sudo touch /etc/modprobe.d/nobt.conf
sudo tee -a /etc/modprobe.d/nobt.conf << END
blacklist btusb
blacklist bluetooth
END
fi

echo "Adding Firefox theme"
git clone https://github.com/muckSponge/MaterialFox.git
mv ~/MaterialFox/chrome ~/.var/app/org.mozilla.firefox/.mozilla/firefox/*-release
rm -rf ~/MaterialFox
echo "You still need to set toolkit.legacyUserProfileCustomizations.stylesheets to true"
echo "You still need to set svg.context-properties.content.enabled to true"
echo "You still need to install this theme: https://addons.mozilla.org/en-US/firefox/addon/materialfox-light/"
