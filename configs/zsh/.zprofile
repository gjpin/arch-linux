# Path to .zshrc directory
export ZSHRCD=$HOME/.zshrc.d

source $ZSHRCD/environ.zsh
source $ZSHRCD/wayland.zsh

if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
  XKB_DEFAULT_LAYOUT=us exec sway
fi