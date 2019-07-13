# Set browser 
if [ -n "$display" ]; then
    export browser=firefox
else
    export browser=links
fi

# Misc
export _java_awt_wm_nonreparenting=1
export _JAVA_AWT_WM_NONREPARENTING=1

# Sourcing NVM
#source /usr/share/nvm/init-nvm.sh

source ~/.zsh-async/async.zsh

export NVM_DIR="$HOME/.nvm"
function load_nvm() {
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
}

# Initialize worker
async_start_worker nvm_worker -n
async_register_callback nvm_worker load_nvm
async_job nvm_worker sleep 0.1