#!/bin/zsh
#######################################################
# Environment Variables
#######################################################
# Set up default editor
# ------------------------------------------------------------------------------
#
if [[ "$OSTYPE" == "darwin"* ]]; then
  export BROWSER=arc
  export SDKROOT="$(xcrun --show-sdk-path)"
  export NCS_SDK_HOME="/opt/nordic/ncs"
else
  export BROWSER=zen-browser
  # SSH agent started by systemd automatically. Only need to set the socketp
  if [[ -z "${SSH_CONNECTION}" ]]; then
    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
  fi
  export NCS_SDK_HOME="$HOME/ncs"
fi

export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/ripgreprc"
export BAT_THEME=ansi
export MANPAGER="nvim +Man!"
export PAGER='bat'

export OBSIDIAN_HOME="$HOME/Documents/Obsidian"
export CODEX_HOME="$XDG_CONFIG_HOME/codex"
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
#Nvim version manager. Vendored bash script to mantain different neovim versions
nvimv use nightly
