#!/usr/bin/env zsh
# $ZDOTDIR/.zprofile: Gets loaded for login shells IN MACOS-only
# ------------------------------------------------------------------------------
#

if [[ "$OSTYPE" == "darwin"* ]]; then
  [[ -e "/opt/homebrew/bin/brew" ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
  typeset -U path PATH
  export PATH
fi

# if [[ -z "${SSH_CONNECTION}" ]]; then
#   export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
# fi

# eval "$(SHELL=/bin/zsh keychain --eval --quick --systemd --ssh-allow-forwarded id_ed25519_yubikey)"
path=($HOME/.local/share/mise/shims $HOME/.local/bin $HOME/dotfiles/common/bin $HOME/dotfiles/linux/bin $path)
