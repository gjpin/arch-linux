#!/usr/bin/bash

################################################
##### Logs
################################################

# Define the log file
LOGFILE="sway.log"

# Start logging all output to the log file
exec > >(tee -a "$LOGFILE") 2>&1

# Log each command before executing it
log_command() {
    echo "\$ $BASH_COMMAND" >> "$LOGFILE"
}
trap log_command DEBUG

################################################
##### Sway
################################################

# Install Sway
# https://wiki.archlinux.org/title/sway
pacman -S --noconfirm \
    sway \
    swaylock \
    swayidle \
    swaybg

# Import Sway configs
# https://github.com/swaywm/sway/wiki#configuration
mkdir -p /home/${NEW_USER}/.config/sway
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sway/appearance -o /home/${NEW_USER}/.config/sway/appearance
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sway/applications -o /home/${NEW_USER}/.config/sway/applications
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sway/bar -o /home/${NEW_USER}/.config/sway/bar
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sway/config -o /home/${NEW_USER}/.config/sway/config
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sway/idle -o /home/${NEW_USER}/.config/sway/idle
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sway/input -o /home/${NEW_USER}/.config/sway/input
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sway/key_bindings -o /home/${NEW_USER}/.config/sway/key_bindings
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sway/output -o /home/${NEW_USER}/.config/sway/output
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sway/startup -o /home/${NEW_USER}/.config/sway/startup
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sway/variables -o /home/${NEW_USER}/.config/sway/variables

################################################
##### Thunar (file manager)
################################################

# References:
# https://wiki.archlinux.org/title/thunar

# Install thunar
pacman -S --noconfirm thunar

# Install Thunar Archive Plugin and achiver
pacman -S --noconfirm \
  thunar-archive-plugin \
  xarchiver

# Install Thunar Volume Manager and GVFS
pacman -S --noconfirm \
  thunar-volman \
  gvfs \
  gvfs-mtp

# Install Tumbler (thumbnails)
pacman -S --noconfirm tumbler ffmpegthumbnailer

# Disable GVFS network mounts
# https://wiki.archlinux.org/title/thunar#Solving_problem_with_slow_cold_start
sed -i "s|^AutoMount=true|AutoMount=false|g" /usr/share/gvfs/mounts/network.mount

################################################
##### Common desktop applications
################################################

# Install ristretto (picture viewer)
pacman -S --noconfirm ristretto

################################################
##### tuigreet (login manager)
################################################

# References:
# https://github.com/apognu/tuigreet

# Install tuigreet
pacman -S --noconfirm greetd-tuigreet

# Enable greetd service
systemctl enable greetd.service

# Import tuigreet configs
# https://git.sr.ht/~kennylevinsen/greetd/tree/master/item/config.toml
# https://github.com/apognu/tuigreet
mkdir -p /etc/greetd
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/greetd-tuigreet/config.toml -o /etc/greetd/config.toml

################################################
##### Foot (terminal)
################################################

# References:
# https://codeberg.org/dnkl/foot#index
# https://wiki.archlinux.org/title/Foot

# Install foot
pacman -S --noconfirm foot

# Import foot configs
mkdir -p /home/${NEW_USER}/.config/foot
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/foot/foot.ini -o /home/${NEW_USER}/.config/foot/foot.ini

################################################
##### Yambar (status bar)
################################################

# References:
# https://codeberg.org/dnkl/yambar
# https://codeberg.org/dnkl/yambar/src/branch/master/examples/configurations

# Install Yambar
sudo -u ${NEW_USER} paru -S --noconfirm yambar

# Import Yambar configs and styles
mkdir -p /home/${NEW_USER}/.config/yambar
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/yambar/config.yaml -o /home/${NEW_USER}/.config/yambar/config.yaml

################################################
##### Fuzzel (application launcher)
################################################

# References:
# https://codeberg.org/dnkl/fuzzel
# https://codeberg.org/dnkl/fuzzel/src/branch/master/doc/fuzzel.ini.5.scd

# Install fuzzel
pacman -S --noconfirm fuzzel

# Import fuzzel configs
mkdir -p /home/${NEW_USER}/.config/fuzzel
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/fuzzel/fuzzel.ini -o /home/${NEW_USER}/.config/fuzzel/fuzzel.ini

################################################
##### Power profile cycle
################################################

# Install 'Power profile cycle'
# https://gitlab.com/lassegs/powerprofilecycle
curl https://raw.githubusercontent.com/gjpin/arch-linux/main/apps/powerprofilecycle.sh -o /usr/local/bin/powerprofilecycle.sh
chmod +x /usr/local/bin/powerprofilecycle.sh

################################################
##### ssh-agent
################################################

# Start ssh-agent with systemd user
# https://wiki.archlinux.org/title/SSH_keys#Start_ssh-agent_with_systemd_user
chown -R ${NEW_USER}:${NEW_USER} /home/${NEW_USER}
sudo -u ${NEW_USER} systemctl --user enable ssh-agent.service

tee /home/${NEW_USER}/.config/environment.d/90-SSH_AUTH_SOCK << 'EOF'
SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent.socket
EOF
