#!/usr/bin/env zsh
# $ZDOTDIR/.zprofile: Gets loaded for login shells IN MACOS-only
# ------------------------------------------------------------------------------
#

if [[ "$OSTYPE" == "darwin"* ]]; then
  [[ -e "/opt/homebrew/bin/brew" ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
  typeset -U path PATH
  path=($HOME/.local/share/mise/shims $HOME/.local/bin $path)
  export PATH
fi
