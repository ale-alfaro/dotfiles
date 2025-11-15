#######################################################
# Shell integrations
#######################################################
#
# Other nice plugins
plugins=(
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
)
__init_plugins "${plugins[@]}"
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
    source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
  fi
else
  echo "Unsupported TERM_PROGRAM=$TERM_PROGRAM"
fi
export OBSIDIAN_HOME="${HOME}/Documents/Obsidian"

# Initialize Node Version manager
if [[ "$OSTYPE" == "darwin"* ]]; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$(brew --prefix nvm)/nvm.sh" ] && \. "$(brew --prefix nvm)/nvm.sh"                                       # This loads nvm
  [ -s "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix nvm)/etc/bash_completion.d/nvm" # This loads nvm bash_completion
else
  export NVM_DIR="$XDG_CONFIG_HOME/nvm"
  source "$ZDOTDIR/shell_integrations/zsh-nvm.zsh"
fi
use_nvim "v0.12"

# --- Completion from CLI tools ---
if has uv; then
  eval "$(uv generate-shell-completion zsh)"
fi

if has prek; then
  eval "$(COMPLETE=zsh prek completion)"
fi

# --- Optional completions from CLI tools ---
if [[ -z "$JJ_COMPLETIONS" ]]; then
  if has jj; then
    eval "$(jj util completion zsh)"
  fi
fi
if [[ -z "$BW_CLI_COMPLETIONS" ]]; then
  if has bw; then
    eval "$(bw completion --shell zsh)"
  fi
fi
