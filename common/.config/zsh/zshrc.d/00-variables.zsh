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

export FZF_CTRL_R_OPTS="
    --color header:italic
    --height=80%
    --bind 'ctrl-y:execute-silent(fc -l {2..} | wl-copy)+abort'
    --header 'CTRL-Y: Copy command into clipboard, CTRL-/: Toggle line wrapping, CTRL-R: Toggle sorting by relevance'
    "

export FZF_CTRL_T_OPTS="
    --walker-skip .git,node_modules,target
    --preview 'bat -n --color=always {}'
    --height=80%
    "

export FZF_ALT_C_OPTS="
    --walker-skip .git,node_modules,target
    --preview 'eza -lh --group-directories-first --icons=auto'
    --height=80%
    --bind 'ctrl-/:change-preview-window(down|hidden|)'
    --header 'CTRL-/: Toggle preview window position'
    "
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
      --info=default\
      --ansi \
      --layout=reverse \
      --border=rounded \
      --color=bg+:#3B4252, \
      --color=bg:#2E3440,\
      --color=spinner:#81A1C1,\
      --color=hl:#616E88,\
      --color=fg:#D8DEE9,\
      --color=header:#616E88,\
      --color=info:#81A1C1,\
      --color=pointer:#81A1C1,\
      --color=marker:#81A1C1,\
      --color=fg+:#D8DEE9,\
      --color=prompt:#81A1C1,\
      --color=hl+:#81A1C1"
export OBSIDIAN_HOME="$HOME/Documents/Obsidian"
export CODEX_HOME="$XDG_CONFIG_HOME/codex"
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"
#Nvim version manager. Vendored bash script to mantain different neovim versions
nvimv use nightly
