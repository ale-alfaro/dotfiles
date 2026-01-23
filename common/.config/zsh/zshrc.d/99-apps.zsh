# Alias for FZF
# Link: https://github.com/junegunn/fzf
#######################################################
# App/TUI Environment Variables and Completions
#######################################################
if [[ "$OSTYPE" == "darwin"* ]]; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$(brew --prefix nvm)/nvm.sh" ] && \. "$(brew --prefix nvm)/nvm.sh"                                       # This loads nvm
  [ -s "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix nvm)/etc/bash_completion.d/nvm" # This loads nvm bash_completion
else
  export NVM_DIR="$XDG_CONFIG_HOME/nvm"
  [[ -r "$ZDOTDIR/plugins/zsh-nvm.zsh" ]] && source "$ZDOTDIR/plugins/zsh-nvm.zsh"
fi
[[ ! -f "$HOME/.npmrc" ]] && npm set prefix="$HOME/.local"

# if has gemini && test -z "${GEMINI_CLI_SYSTEM_SETTINGS_PATH}"; then
#   export GEMINI_CLI_SYSTEM_SETTINGS_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/gemini/settings.json"
# fi

if has codex && test -z "${CODEX_HOME}"; then
  eval "$(codex completion zsh)"
fi
# --- Optional completions from CLI tools ---
if [[ ! -z "$JJ_COMPLETIONS" ]]; then
  if has jj; then
    eval "$(jj util completion zsh)"
  fi
fi
[[ ! -z "$BW_CLI_COMPLETIONS" ]] && has bw && eval "$(bw completion --shell zsh)"
has nrfutil && [[ -r "${HOME}/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh" ]] && . "${HOME}/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh"

#######################################################
# Shell integrations
#######################################################
# ---- Atuin (better shell command history) -----
safe_source atuin init zsh

# ---- Starship (better prompt) -----
safe_source starship init zsh
# ---- Direnv (.envrc auto-loading) -----
safe_source direnv hook zsh

plugins=(
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
)
__init_plugins "${plugins[@]}"
