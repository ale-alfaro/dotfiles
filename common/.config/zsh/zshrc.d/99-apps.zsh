#######################################################
# Shell integrations
#######################################################
## fzf
# ------------------------------------------------------------------------------
if type fzf &>/dev/null; then
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
eval "$(jj util completion zsh)"
if [[ -x "$(command -v bw)" ]]; then
  eval "$(bw completion --shell zsh)"
fi
[[ -r "${HOME}/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh" ]] && . "${HOME}/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh"

# ---- Atuin (better shell command history) -----
eval "$(atuin init zsh)"

# ---- Starship (better prompt) -----
export STARSHIP_CONFIG=~/.config/starship/starship.toml
eval "$(starship init zsh)"
# ---- Direnv (.envrc auto-loading) -----
eval "$(direnv hook zsh)"

# ---- zoxide (better cd) -----
if type zoxide &>/dev/null; then
  eval "$(zoxide init zsh --cmd zd)"
else
  echo ERROR: Could not load zoxide shell integration.
fi

# ---- Zellij ----- NOT IN USE
# export ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij"
# eval "$(zellij setup --generate-completion zsh)"
#
# ---- Wezterm (terminal emulator) ---
. $ZDOTDIR/shell_integrations/wezterm.sh

# Initialize Node Version manager
if [[ "$OSTYPE" == "darwin"* ]]; then
  export NVM_DIR=/Users/alealfaro/.nvm
  [ -s /opt/homebrew/opt/nvm/nvm.sh ] && \. /opt/homebrew/opt/nvm/nvm.sh                                       # This loads nvm
  [ -s /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm ] && \. /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm # This loads nvm bash_completion
else
  . /usr/share/nvm/init-nvm.sh
fi

eval "$(uv generate-shell-completion zsh)"

# python_clis=("pytest" "ruff" "pylint" "mypy")

# for cli in "${python_clis[@]}"; do
#   eval "$(register-python-argcomplete "$cli")"
# done
