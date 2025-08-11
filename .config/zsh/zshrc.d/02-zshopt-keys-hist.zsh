


#######################################################
# ZSH Keybindings
#######################################################

bindkey -v
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^e' edit-command-line
# bindkey '^[w' kill-regin
# bindkey ' ' magic-space                           # do history expansion on space
# bindkey "^[[A" history-beginning-search-backward  # search history with up key
# bindkey "^[[B" history-beginning-search-forward   # search history with down key

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
