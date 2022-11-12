#!/bin/bash

# References:
# https://wiki.archlinux.org/title/sway
# https://codeberg.org/dnkl/foot
# https://github.com/Alexays/Waybar
# https://github.com/fairyglade/ly
# https://github.com/swaywm/sway/wiki/Useful-add-ons-for-sway

################################################
##### Sway
################################################

# Install sway and related applications
pacman -S --noconfirm \
    sway \
    polkit \
    xdg-desktop-portal-wlr \
    swaylock \
    bemenu \
    swayidle \
    swaybg \
    wl-clipboard \
    grim \
    playerctl \
    xorg-xrandr \
    light \
    mako

sudo -u ${NEW_USER} paru -S --noconfirm \
    grimshot

# Enable XDG's desktop portal WLR user service
sudo -u ${NEW_USER} systemctl --user enable xdg-desktop-portal-wlr.service

# Create directories
mkdir -p /home/${NEW_USER}/Pictures/{wallpapers,screenshots}

# Install Ly (login manager)
sudo -u ${NEW_USER} paru -S --noconfirm ly-git
systemctl enable ly.service

# Import sway configurations
mkdir -p /home/${NEW_USER}/.config/sway
tee /home/${NEW_USER}/.config/sway/config << 'EOF'
##### Variables
# Modifier
set $mod Mod4

# Navigation
set $left h
set $down j
set $up k
set $right l

# Terminal
set $term foot

# Application launcher
set $menu dmenu_path | BEMENU_BACKEND=wayland bemenu-run -H 30 --fn "Sauce Code Pro Nerd Font 10" --tb "#1e1e1e" --tf "#d4d4d4" --fb "#1e1e1e" --ff "#d4d4d4" --nb "#1e1e1e" --nf "#d4d4d4" --hb "#1e1e1e" --hf "#d4d4d4" --sb "#1e1e1e" --sf "#d4d4d4" --scb "#1e1e1e" --scf "#d4d4d4" | xargs swaymsg exec --

# Wallpaper
set $wallpaper /usr/share/backgrounds/sway/Sway_Wallpaper_Blue_2048x1536.png

# Lock
set $lock swaylock -f -i $wallpaper

### Output configuration
# Wallpaper
output * bg $wallpaper fill

# You can get the names of your outputs by running: swaymsg -t get_outputs
#output HDMI-A-1 resolution 1920x1080 position 1920,0

### Idle configuration
exec swayidle -w \
         timeout 300 $lock \
         timeout 300 'swaymsg "output * dpms off"' \
            resume 'swaymsg "output * dpms on"' \
         before-sleep $lock

### Input configuration
# You can get the names of your inputs by running: swaymsg -t get_inputs
   input "1739:30385:CUST0001:00_06CB:76B1_Touchpad" {
       dwt disabled
       tap enabled
       natural_scroll enabled
       middle_emulation enabled
   }

### Key bindings
# Basics
    bindsym $mod+Return exec $term

    bindsym $mod+Shift+q kill

    bindsym $mod+Tab exec $menu

    floating_modifier $mod normal

    bindsym $mod+Shift+c reload

    bindsym $mod+Shift+e exec swaynag -t warning -m 'Do you really want to exit sway?' -B 'Yes, exit sway' 'swaymsg exit'

# Moving around:
    bindsym $mod+$left focus left
    bindsym $mod+$down focus down
    bindsym $mod+$up focus up
    bindsym $mod+$right focus right

    bindsym $mod+Left focus left
    bindsym $mod+Down focus down
    bindsym $mod+Up focus up
    bindsym $mod+Right focus right

    bindsym $mod+Shift+$left move left
    bindsym $mod+Shift+$down move down
    bindsym $mod+Shift+$up move up
    bindsym $mod+Shift+$right move right

    bindsym $mod+Shift+Left move left
    bindsym $mod+Shift+Down move down
    bindsym $mod+Shift+Up move up
    bindsym $mod+Shift+Right move right

# Workspaces
    bindsym $mod+1 workspace number 1
    bindsym $mod+2 workspace number 2
    bindsym $mod+3 workspace number 3
    bindsym $mod+4 workspace number 4
    bindsym $mod+5 workspace number 5
    bindsym $mod+6 workspace number 6
    bindsym $mod+7 workspace number 7
    bindsym $mod+8 workspace number 8
    bindsym $mod+9 workspace number 9
    bindsym $mod+0 workspace number 10

    bindsym $mod+Shift+1 move container to workspace number 1
    bindsym $mod+Shift+2 move container to workspace number 2
    bindsym $mod+Shift+3 move container to workspace number 3
    bindsym $mod+Shift+4 move container to workspace number 4
    bindsym $mod+Shift+5 move container to workspace number 5
    bindsym $mod+Shift+6 move container to workspace number 6
    bindsym $mod+Shift+7 move container to workspace number 7
    bindsym $mod+Shift+8 move container to workspace number 8
    bindsym $mod+Shift+9 move container to workspace number 9
    bindsym $mod+Shift+0 move container to workspace number 10

# Layout
    bindsym $mod+b splith
    bindsym $mod+v splitv

    bindsym $mod+s layout stacking
    bindsym $mod+w layout tabbed
    bindsym $mod+e layout toggle split

    bindsym $mod+f fullscreen

    bindsym $mod+Shift+space floating toggle

    bindsym $mod+space focus mode_toggle

    bindsym $mod+a focus parent

# Scratchpad
    bindsym $mod+Shift+minus move scratchpad
    bindsym $mod+minus scratchpad show

# Resizing containers
mode "resize" {
    bindsym $left resize shrink width 10px
    bindsym $down resize grow height 10px
    bindsym $up resize shrink height 10px
    bindsym $right resize grow width 10px

    bindsym Left resize shrink width 10px
    bindsym Down resize grow height 10px
    bindsym Up resize shrink height 10px
    bindsym Right resize grow width 10px

    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+r mode "resize"

# Screenshots
bindsym $mod+Shift+s exec grimshot save area ~/Pictures/screenshots/$(date +'screenshot_%Y%m%d_%H%M%S.png')

# Lock screen
bindsym $mod+Control+l exec $lock

### FN keys
# Volume
bindsym --locked XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle
bindsym --locked XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym --locked XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym --locked XF86AudioMicMute exec pactl set-source-mute @DEFAULT_SOURCE@ toggle

# Media
bindsym --locked XF86AudioPlay exec playerctl play-pause
bindsym XF86AudioNext exec playerctl next
bindsym XF86AudioPrev exec playerctl previous

# Brightness
bindsym --locked XF86MonBrightnessUp exec light -A 5
bindsym --locked XF86MonBrightnessDown exec light -U 5

### Power
# Suspend to ram on laptop lid close 
# bindswitch --locked lid:on exec $lock && sudo zzz -z

# Suspend to ram on power off button 
# bindswitch --locked lid:on exec $lock && sudo zzz -z

### Outro
# Borders and gaps
default_border pixel 2
default_floating_border pixel 2
gaps inner 0
client.focused #545454 #545454 #545454 #545454

# Start waybar
bar swaybar_command waybar

# Start mako (notifications daemon)
exec mako

# Force xapps on primary display
exec xrandr --output XWAYLAND0 --primary

include /etc/sway/config.d/*
EOF

################################################
##### foot (terminal)
################################################

# Install foot
pacman -S --noconfirm foot

# Import foot configurations
mkdir -p /home/${NEW_USER}/.config/foot
tee /home/${NEW_USER}/.config/foot/foot.ini << 'EOF'
font=Sauce Code Pro Nerd Font:size=10
# dpi-aware=no

[scrollback]
lines=10000

[url]
launch=xdg-open ${url}
osc8-underline=url-mode
protocols=http, https, ftp, ftps, file, gemini, gopher
uri-characters=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.,~:;/?#@!$&%*+="'()[]

[mouse]
hide-when-typing=no

# cursor/colors source:
# https://github.com/Mofiqul/vscode.nvim/blob/main/extra/alacritty/alacritty.yml
[cursor]
color=d4d4d4 d4d4d4

[colors]
alpha=1.00
background=1e1e1e
foreground=d4d4d4
regular0=1e1e1e  # black
regular1=f44747  # red
regular2=608b4e  # green
regular3=dcdcaa  # yellow
regular4=569cd6  # blue
regular5=c678dd  # magenta
regular6=56b6c2  # cyan
regular7=d4d4d4  # white
bright0=545454   # bright black
bright1=f44747   # bright red
bright2=608b4e   # bright green
bright3=dcdcaa   # bright yellow
bright4=569cd6   # bright blue
bright5=c678dd   # bright magenta
bright6=56b6c2   # bright cyan
bright7=d4d4d4   # bright white

[key-bindings]
scrollback-up-page=Shift+Page_Up
scrollback-down-page=Shift+Page_Down
clipboard-copy=Control+Shift+c XF86Copy
clipboard-paste=Control+Shift+v XF86Paste
search-start=Control+Shift+r
font-increase=Control+plus Control+equal Control+KP_Add
font-decrease=Control+minus Control+KP_Subtract

[search-bindings]
cancel=Control+g Control+c Escape
commit=Return
find-prev=Control+r
find-next=Control+s

[mouse-bindings]
primary-paste=BTN_MIDDLE
select-begin=BTN_LEFT
select-begin-block=Control+BTN_LEFT
select-word=BTN_LEFT-2
select-row=BTN_LEFT-3
EOF

################################################
##### waybar
################################################

# Install waybar
pacman -S --noconfirm waybar

# Import waybar configurations
mkdir -p /home/${NEW_USER}/.config/waybar
tee /home/${NEW_USER}/.config/waybar/config << 'EOF'
{
    "layer": "bottom",
    "position": "top",
    "height": 30,
    "spacing": 4,
    "modules-left": ["sway/workspaces", "sway/mode"],
    "modules-center": ["sway/window"],
    "modules-right": ["tray", "idle_inhibitor", "sway/language", "pulseaudio", "backlight", "network", "battery", "custom/clock"],
    "idle_inhibitor": {
        "format": "{icon}",
        "format-icons": {
            "activated": "",
            "deactivated": ""
        }
    },
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-bluetooth": "{volume}% {icon}",
        "format-muted": "婢",
        "format-icons": {
            "headphone": "",
            "headset": "",
            "phone": "",
            "portable": "",
            "car": "",
            "default": ["奔", "墳"]
        },
        "scroll-step": 1,
        "on-click": "pavucontrol"
    },
    "custom/clock": {
        "interval": 60,
        "exec": "date +'%d %b %H:%M'"
    },
    "backlight": {
        "format": "{percent}% {icon}",
        "format-icons": ["滛", "盛"]
    },
    "battery": {
        "format": "{capacity}% {icon}",
        "format-time": "{H} h {M} min",
        "format-charging": "{capacity}% ",
        "format-plugged": "{capacity}% ",
        "format-alt": "{time} {icon}",
        "format-icons": ["", "", "", "", ""]
    },
    "network": {
        "format-wifi": "{essid} ({signalStrength}%) 直",
        "format-ethernet": "{ipaddr}/{cidr} ",
        "tooltip-format": "{ifname} via {gwaddr} ﯱ",
        "format-linked": "{ifname} (No IP) ",
        "format-disconnected": "Disconnected ",
        "format-alt": "{ifname}: {ipaddr}/{cidr}",
        "on-click": "nmtui"
    }
}
EOF

tee /home/${NEW_USER}/.config/waybar/style.css << 'EOF'
* {
    font-family: Sauce Code Pro Nerd Font;
    font-size: 13px;
    color: #d4d4d4;
}

window#waybar {
    background-color: #1e1e1e;
    border-bottom: 3px solid rgba(84, 84, 84, 0.4);
    transition-property: background-color;
    transition-duration: .5s;
}

window#waybar.hidden {
    opacity: 0.2;
}

#workspaces button {
    padding: 0 5px;
    background-color: transparent;
    /* Use box-shadow instead of border so the text isn't offset */
    box-shadow: inset 0 -3px transparent;
    /* Avoid rounded borders under each workspace name */
    border: none;
    border-radius: 0;
}

/* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
#workspaces button:hover {
    background: rgba(0, 0, 0, 0.2);
    box-shadow: inset 0 -3px #ffffff;
}

#workspaces button.focused {
    background-color: #64727D;
    box-shadow: inset 0 -3px #ffffff;
}

#workspaces button.urgent {
    background-color: #eb4d4b;
}

#custom-clock,
#battery,
#backlight,
#network,
#pulseaudio,
#tray,
#idle_inhibitor {
    padding: 0 5px;
    margin: 0 5px;
}

#window,
#workspaces {
    margin: 0 4px;
}

/* If workspaces is the leftmost module, omit left margin */
.modules-left > widget:first-child > #workspaces {
    margin-left: 0;
}

/* If workspaces is the rightmost module, omit right margin */
.modules-right > widget:last-child > #workspaces {
    margin-right: 0;
}

@keyframes blink {
    to {
        background-color: #ffffff;
    }
}

#battery.critical:not(.charging) {
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: linear;
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
}
EOF

################################################
##### GTK theming
################################################

# Install and configure adw-gtk3 theme
pacman -S --noconfirm adwaita-icon-theme

sudo -u ${NEW_USER} paru -S --noconfirm adw-gtk3

flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3
flatpak install -y flathub org.gtk.Gtk3theme.adw-gtk3-dark

mkdir -p /home/${NEW_USER}/.config/{gtk-3.0,gtk-4.0}

tee /home/${NEW_USER}/.config/gtk-3.0/gtk.css << EOF
/* Remove rounded corners */
.titlebar,
.titlebar .background,
decoration,
window,
window.background
{
    border-radius: 0;
}

/* Remove csd shadows */
decoration, decoration:backdrop
{
    box-shadow: none;
}
EOF

tee /home/${NEW_USER}/.config/gtk-3.0/settings.ini << EOF
[Settings]
gtk-icon-theme-name=Adwaita
gtk-theme-name=adw-gtk3
EOF

tee /home/${NEW_USER}/.config/gtk-4.0/gtk.css << EOF
/* Remove rounded corners */
.titlebar,
.titlebar .background,
decoration,
window,
window.background
{
    border-radius: 0;
}

/* Remove csd shadows */
decoration, decoration:backdrop
{
    box-shadow: none;
}
EOF

################################################
##### XFCE applications
################################################

# References:
# https://wiki.archlinux.org/title/thunar

# Install thunar and dependencies
pacman -S --noconfirm \ 
    thunar \
    gvfs \
    thunar-archive-plugin file-roller \
    tumbler

# Install image viewer
pacman -S --noconfirm ristretto

# Install text editor
pacman -S --noconfirm mousepad

# Configure XFCE default applications
mkdir -p /home/${NEW_USER}/.config/xfce4
tee /home/${NEW_USER}/.config/xfce4/helpers.rc << EOF
WebBrowser=firefox
TerminalEmulator=foot
FileManager=thunar
EOF