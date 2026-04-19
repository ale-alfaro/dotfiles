#!/usr/bin/env zsh
# $ZDOTDIR/.zprofile: Gets loaded for login shells IN MACOS-only
# ------------------------------------------------------------------------------
#

if [[ -z $MISE_SHIMS_ADDED_TO_PATH ]]; then
  export PATH="/home/alealfaro/.local/bin:$PATH"
  export PATH="/home/alealfaro/.local/share/mise/shims:$PATH"
fi

if [[ ! "$OSTYPE" == "darwin"* && -e "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
