# Set browser 
if [ -n "$display" ]; then
    export browser=firefox
else
    export browser=links
fi

# Prepare NVM 
export NVM_DIR=~/.nvm
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# Misc
export _java_awt_wm_nonreparenting=1
export _JAVA_AWT_WM_NONREPARENTING=1
