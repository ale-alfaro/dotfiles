# ------------------------------------------------------------------------------
# .zshenv - PATH extensions
# ------------------------------------------------------------------------------
# PATH is extended here in ~/.zprofile instead of ~/.zshenv (the more "correct"
# place) because sometimes /etc/zprofile exports PATH, overriding modifications
# made in ~/.zshenv. ~/.zprofile runs after /etc/zprofile. This ensures user
# PATH additions are available in all login shells.

typeset -U path PATH
path=($HOME/.local/bin $path)
export PATH

#######################################################
# Environment Variables
#######################################################
export BAT_THEME=ansi
export PAGER="bat"
export MANPAGER="nvim +Man!"
# zsh options
export HISTFILE="$XDG_DATA_HOME/zsh/history"
export HISTSIZE=25001 # Maximum events for internal history
export SAVEHIST=25001 # Maximum events in history file
export KEYTIMEOUT=5

