#!/usr/bin/env zsh

# General Options
# ------------------------------------------------------------------------------
## List jobs in the long format by default.
setopt LONG_LIST_JOBS

## Disable flow control and hence restore the ability to use C-s and C-q
setopt NO_FLOW_CONTROL

#######################################################
# ZSH Basic Options
#######################################################

# setopt autocd              # change directory just by typing its name
# setopt correct             # auto correct mistakes
# setopt interactivecomments # allow comments in interactive mode
setopt magicequalsubst # enable filename expansion for arguments of the form ‘anything=expression’
setopt nonomatch       # hide error message if there is no match for the pattern
setopt notify          # report the status of background jobs immediately
setopt numericglobsort # sort filenames numerically when it makes sense
setopt promptsubst     # enable command substitution in prompt
# Set Up Line Editor
# ------------------------------------------------------------------------------
## Enable vi mode
bindkey -v

## Enable edit-command-line widget for vi mode
autoload -U edit-command-line
zle -N edit-command-line
bindkey -M vicmd '^X^E' edit-command-line
bindkey -M viins '^X^E' edit-command-line
bindkey "^v" edit-command-line
#
# ## Lower mode switching delay to 10ms
KEYTIMEOUT=1

## Bind Meta-. to insert last word of previous command and stay in insert mode
bindkey -M viins "\e." insert-last-word

## Bind C-R to search backwards in all modes
bindkey '^R' history-incremental-search-backward
#
# ## Bind C-S to search forward in all modes
bindkey '^S' history-incremental-search-forward
#
# ## History expansion on space
bindkey ' ' magic-space
#
# ## Bind history navigation to C-P and C-N in all modes
bindkey '^P' up-line-or-history
#
# ## Bind history navigation to C-P and C-N in all modes
bindkey '^N' down-line-or-history

## Bind C-D to forward delete next char
# bindkey '^D' delete-char

## Additionaly set up basic Emacs-style navigation
# bindkey '^A' beginning-of-line
# bindkey '^E' end-of-line
# bindkey '^F' forward-char
# bindkey '^B' backward-char

# Remove some default bindkeys
# bindkey -r '^c'
# bindkey -r '^l' # Clear screen
# bindkey -r '^h'

# bindkey -s '^Z' 'fg\n'
#######################################################
# History Configuration
#######################################################

## Enable globally shared history (same history in every shell)
setopt SHARE_HISTORY

## When writing out the history file, older duplicate commands are omitted
setopt HIST_SAVE_NO_DUPS

## Don't save commands prefixed with at least one space to history
setopt HIST_IGNORE_SPACE

## Don't directly execute commands when using history expansion
setopt HIST_VERIFY

## Max number of history lines in memory
HISTSIZE=25000

# Set up history file
if [[ ! -d "$XDG_DATA_HOME/zsh" ]]; then
  mkdir -p "$XDG_DATA_HOME/zsh"
fi
HISTFILE="$XDG_DATA_HOME/zsh/history"
# HISTFILE=~/.zsh_history
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups
# Set Up Plugins
# ------------------------------------------------------------------------------
source $ZDOTDIR/functions/stdlib.zsh
source $ZDOTDIR/shell_integrations/plugin_helper.zsh
plugins=(
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-completions
  Aloxaf/fzf-tab
)
__init_plugins "${plugins[@]}"
