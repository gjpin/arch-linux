# Load theme
source /usr/share/zsh-theme-powerlevel9k/powerlevel9k.zsh-theme

# Bind keys for navigation
bindkey ";5C" forward-word
bindkey ";5D" backward-word

# Customize prompt
prompt_context() {}

# History support
HISTSIZE=5000               #How many lines of history to keep in memory
HISTFILE=~/.zsh_history     #Where to save history to disk
SAVEHIST=5000               #Number of history entries to save to disk
#HISTDUP=erase               #Erase duplicates in the history file
setopt    appendhistory     #Append history to the history file (no overwriting)
setopt    sharehistory      #Share history across terminals
setopt incappendhistory #Immediately append to the history file, not just when a term is killed