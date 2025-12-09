#######################################################
# Shell integrations
#######################################################

# Quickly go back to a specific parent directory instead of typing cd ../../.. redundantly
# Example usage:
# $ mkdir -p a/b/c/d
# $ cd a/b/c/d
# $ bd b
# $ ls
# c
# $ cd c/d
# $ bd 2
# $ ls
# c

bd_zsh="$shell_integrations/bd.zsh"
if [[ -f "$bd_zsh" ]]; then
  source "$bd_zsh"
fi
# Load syntax-highlighting and auto-suggestion. Don't need to initialize the repo as it was already done when loading zsh-completions
__load_plugin zsh-users/zsh-syntax-highlighting
__load_plugin zsh-users/zsh-autosuggestions
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
  . "$shell_integrations/wezterm.sh"
elif [[ $TERM_PROGRAM == "ghostty" ]]; then
  if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
    echo "Enabling ghostty shell integration"
    source "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration"
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

nvimv use nightly
export npm_config_prefix="$HOME/.local"

## Additional completions. This can be here because they don't add to the fpath and get activated by eval
# --- Completion from CLI tools ---
# if has prek; then
#   eval "$(COMPLETE=zsh prek completion)"
# fi

# --- Optional completions from CLI tools ---
if [[ ! -z "$JJ_COMPLETIONS" ]]; then
  if has jj; then
    eval "$(jj util completion zsh)"
  fi
fi
if [[ ! -z "$BW_CLI_COMPLETIONS" ]]; then
  if has bw; then
    eval "$(bw completion --shell zsh)"
  fi
fi

if has codex; then
  eval "$(codex completion zsh)"
  export CODEX_HOME="${XDG_CONFIG_HOME}/codex"
fi

if has gemini; then
  export GEMINI_CLI_SYSTEM_SETTINGS_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/gemini/settings.json"
fi
