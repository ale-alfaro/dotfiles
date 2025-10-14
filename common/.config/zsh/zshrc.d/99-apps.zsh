#######################################################
# Shell integrations
#######################################################
## fzf
# ------------------------------------------------------------------------------
if has fzf; then
  source <(fzf --zsh)

  export FZF_CTRL_R_OPTS="
  --color header:italic
  --height=80%
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --header 'CTRL-Y: Copy command into clipboard, CTRL-/: Toggle line wrapping, CTRL-R: Toggle sorting by relevance'
  "

  export FZF_CTRL_T_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'bat -n --color=always {}'
  --height=80%
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
  --header 'CTRL-/: Toggle preview window position'
  "

  export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'tree -C {}'
  --height=80%
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
  --header 'CTRL-/: Toggle preview window position'
  "
else
  echo ERROR: Could not fzf shell integration.
fi

# --- Completion from CLI tools ---
if has jj; then
  eval "$(jj util completion zsh)"
fi
if has bw; then
  eval "$(bw completion --shell zsh)"
fi

# ---- Atuin (better shell command history) -----
eval "$(atuin init zsh)"

# ---- Starship (better prompt) -----
export STARSHIP_CONFIG=~/.config/starship/starship.toml
eval "$(starship init zsh)"
# ---- Direnv (.envrc auto-loading) -----
eval "$(direnv hook zsh)"

# ---- zoxide (better cd) -----
if has zoxide; then
  eval "$(zoxide init zsh --cmd zd)"
else
  echo ERROR: Could not load zoxide shell integration.
fi

# ---- Wezterm (terminal emulator) ---
if [[ $TERM_PROGRAM == "WezTerm" ]]; then
  echo "Enabling wezterm shell integration"
  . $ZDOTDIR/shell_integrations/wezterm.sh

elif [[ $TERM_PROGRAM == "ghostty" ]]; then
  if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
    echo "Enabling ghostty shell integration"
    # source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
  fi
fi
# if has nvm; then

# Initialize Node Version manager
if [[ "$OSTYPE" == "darwin"* ]]; then

  # export NVM_DIR="${XDG_CONFIG_HOME}/.nvm"
  export NVM_DIR="$HOME/.nvm"
  [ -s "$(brew --prefix nvm)/nvm.sh" ] && \. "$(brew --prefix nvm)/nvm.sh"                                       # This loads nvm
  [ -s "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix nvm)/etc/bash_completion.d/nvm" # This loads nvm bash_completion
  # [ -s /opt/homebrew/opt/nvm/nvm.sh ] && \. /opt/homebrew/opt/nvm/nvm.sh                                       # This loads nvm
  # [ -s /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm ] && \. /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm # This loads nvm bash_completion
  #Set OBSIDIAN_HOME to iCloud directory in MacOS
  export OBSIDIAN_HOME="/Users/alealfaro/Documents/Obsidian"
else
  # . /usr/share/nvm/init-nvm.sh
  export NVM_DIR="$XDG_CONFIG_HOME/nvm"
  source "$ZDOTDIR/shell_integrations/zsh-nvm.zsh"
  export OBSIDIAN_HOME="/home/alealfaro/Documents/Obsidian"
fi
# fi

if has uv; then
  eval "$(uv generate-shell-completion zsh)"
fi

if has prek; then
  eval "$(COMPLETE=zsh prek completion)"
fi
# python_clis=("pytest" "ruff" "pylint" "mypy")

# for cli in "${python_clis[@]}"; do
#   eval "$(register-python-argcomplete "$cli")"
# done
