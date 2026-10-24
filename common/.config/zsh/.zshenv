#!/usr/bin/env zsh

####################################
# EXPORT ENVIRONMENT VARIABLE ONLY #
####################################

# XDG
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state
export XDG_CACHE_HOME=$HOME/.cache

# Default programs to run are in $XDG_CONFIG_HOME/uwsm/default
export ZDOTDIR=$HOME/.config/zsh

