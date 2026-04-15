#!/usr/bin/env zsh
# $ZDOTDIR/.zprofile: Gets loaded for login shells IN MACOS-only
# ------------------------------------------------------------------------------
#
if [[ $- != *i* ]]; then
  echo "Non-interactive shell"
  echo "This file should not be sourced unless you work run an interactive login shell"
  return
fi

source $ZDOTDIR/.zshenv


if [[ ! "$OSTYPE" == "darwin"* && -e "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
