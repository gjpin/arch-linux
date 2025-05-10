#!/usr/bin/bash

################################################
##### Sunshine (native - prebuilt)
################################################

# References:
# https://github.com/LizardByte/Sunshine
# https://docs.lizardbyte.dev/projects/sunshine/en/latest/
# https://docs.lizardbyte.dev/projects/sunshine/en/latest/about/advanced_usage.html#port

# Install sunshine
sudo -u ${NEW_USER} paru -S --noconfirm sunshine-beta-bin

# Enable sunshine service
chown -R ${NEW_USER}:${NEW_USER} /home/${NEW_USER}
sudo -u ${NEW_USER} systemctl --user enable sunshine

# Import sunshine configurations
mkdir -p /home/${NEW_USER}/.config/sunshine

curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sunshine/sunshine.conf -o /home/${NEW_USER}/.config/sunshine/sunshine.conf

if [ ${DESKTOP_ENVIRONMENT} = "gnome" ]; then
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sunshine/apps-gnome.json -o /home/${NEW_USER}/.config/sunshine/apps.json
elif [ ${DESKTOP_ENVIRONMENT} = "plasma" ]; then
    curl https://raw.githubusercontent.com/gjpin/arch-linux/main/configs/sunshine/apps-plasma.json -o /home/${NEW_USER}/.config/sunshine/apps.json
fi

# Enable KMS display capture
setcap cap_sys_admin+p /usr/bin/sunshine

# Allow Sunshine through firewall
firewall-offline-cmd --zone=home --add-port=47984/tcp
firewall-offline-cmd --zone=home --add-port=47989/tcp
firewall-offline-cmd --zone=home --add-port=48010/tcp
firewall-offline-cmd --zone=home --add-port=47998/udp
firewall-offline-cmd --zone=home --add-port=47999/udp
firewall-offline-cmd --zone=home --add-port=48000/udp

# Sunshine pacman hook
tee /etc/pacman.d/hooks/95-sunshine.hook << 'EOF'
[Trigger]
Type = Package
Operation = Upgrade
Target = sunshine-beta-bin

[Action]
Description = Re-enabling Sunshine's KMS display capture
When = PostTransaction
Exec = /usr/bin/setcap cap_sys_admin+p /usr/bin/sunshine
EOF