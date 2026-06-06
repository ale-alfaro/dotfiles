#!/usr/bin/env zsh
# $ZDOTDIR/.zprofile: Gets loaded for login shells IN MACOS-only
# ------------------------------------------------------------------------------
#

if [[ "$OSTYPE" == "darwin"* ]]; then
  [[ -e "/opt/homebrew/bin/brew" ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
  typeset -U path PATH
  path=($HOME/.local/bin $HOME/dotfiles/common/bin $HOME/dotfiles/linux/bin $path)
  export PATH
fi

# eval "$(SHELL=/bin/zsh keychain --eval --quick --systemd --ssh-allow-forwarded id_ed25519_yubikey)"
typeset -U path PATH
path=($HOME/.local/bin $path)
export PATH
if [[ ! -n "${SSH_CONNECTION}" ]]; then
  source <(mise activate --shims)
fi
