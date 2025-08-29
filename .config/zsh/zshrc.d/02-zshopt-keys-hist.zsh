


#######################################################
# ZSH Keybindings
#######################################################

bindkey -v
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
autoload -z edit-command-line
zle -N edit-command-line
bindkey "^v" edit-command-line
# Use ESC v in Vi mode to edit the command line
bindkey -M vicmd "v" edit-command-line

# Remove some default bindkeys
bindkey -r '^l' # Clear screen
bindkey -r '^h'
#######################################################
# History Configuration
#######################################################

HISTSIZE=10000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups
