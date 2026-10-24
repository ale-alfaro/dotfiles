#!/usr/bin/env zsh
# $ZDOTDIR/.zprofile: Gets loaded for login shells IN MACOS-only
# ------------------------------------------------------------------------------
export BAT_THEME=ansi
export MANPAGER="nvim +Man!"
# zsh options
export HISTFILE="$XDG_DATA_HOME/zsh/history"
export HISTSIZE=25001 # Maximum events for internal history
export SAVEHIST=25001 # Maximum events in history file
export KEYTIMEOUT=5

# shellcheck shell=bash

# This file runs once at login.

# shellcheck disable=SC1091
# . "${XDG_CONFIG_HOME:-"${HOME}/.config"}/zsh/.xdg.local"



# Configure GPG.

# Configure zsh-vi-mode.
export ZVM_NORMAL_MODE_CURSOR="${ZVM_CURSOR_BLOCK:-}"
export ZVM_INSERT_MODE_CURSOR="${ZVM_CURSOR_BEAM:-}"

# Load local settings if they exist.
# shellcheck disable=SC1091
if [ -f "${XDG_CONFIG_HOME}/zsh/.zprofile.local" ]; then . "${XDG_CONFIG_HOME}/zsh/.zprofile.local"; fi

