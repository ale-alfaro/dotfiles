#!/usr/bin/env zsh
#######################################################
# Environment Variables
#######################################################
export BAT_THEME=ansi
export PAGER="bat"
export MANPAGER="nvim +Man!"
# zsh options
export HISTFILE="$XDG_DATA_HOME/zsh/history"
export HISTSIZE=25001 # Maximum events for internal history
export SAVEHIST=25001 # Maximum events in history file
export KEYTIMEOUT=5

export FZF_FILE_EXPLORER_PREVIEW="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

export FZF_COLORS="bg+:#3B4252, \
      bg:#2E3440,\
      spinner:#81A1C1,\
      hl:#616E88,\
      fg:#D8DEE9,\
      header:#616E88,\
      info:#81A1C1,\
      pointer:red,\
      marker:red,\
      fg+:#D8DEE9,\
      prompt:#81A1C1,\
      hl+:red"

export FZF_DEFAULT_OPTS="--height 60% \
--walker-skip .git,node_modules,target \
--border sharp \
--layout reverse \
--color '$FZF_COLORS' \
--prompt '∷ ' \
--pointer ▶ \
--marker ⇒"

export FZF_CTRL_T_OPTS="
      $FZF_DEFAULT_OPTS
      --preview '$FZF_FILE_EXPLORER_PREVIEW'
      "
export FZF_ALT_C_OPTS="
    --walker-skip .git,node_modules,target
    --preview 'eza -lh --group-directories-first --icons=auto {}'
    --height=80%
    --bind 'ctrl-/:change-preview-window(down|hidden|)'
    --header 'CTRL-/: Toggle preview window position'
"
if [[ "$OSTYPE" == "darwin"* ]]; then
  export BROWSER=arc
  export SDKROOT="$(xcrun --show-sdk-path)"
else
  export BROWSER=zen-browser
  # SSH agent started by systemd automatically. Only need to set the socketp
  if [[ -z "${SSH_CONNECTION}" ]]; then
    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
  fi
fi

export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/ripgreprc"
export OBSIDIAN_HOME="$HOME/Documents/Obsidian"
