#!/bin/zsh
#######################################################
# Environment Variables
#######################################################
# Set up default editor
# ------------------------------------------------------------------------------
#
export VISUAL="$EDITOR"
export SUDO_EDITOR="$EDITOR"
export FCEDIT="$EDITOR"
export NVIM_HOME="$HOME/.local/nvim"
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

PRE_MAN_CMD="sh -c 'awk '\''{ gsub(/\x1B\[[0-9;]*m/, \"\", \$0); gsub(/.\x08/, \"\", \$0); print }'\''"

# export MANPAGER="sh -c 'awk '\''{ gsub(/\x1B\[[0-9;]*m/, \"\", \$0); gsub(/.\x08/, \"\", \$0); print }'\'' | bat -p -lman'"
# export MANPAGER="bat -p -lman --strip-ansi=always"
export MANPAGER="nvim +Man!"
export PAGER='bat'
