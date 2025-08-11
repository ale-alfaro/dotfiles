#######################################################
# Shell integrations
#######################################################

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# ---- Atuin (better shell command history) -----
eval "$(atuin init zsh)"

# ---- JJ (Git alternative) -----
source <(jj util completion zsh)

# ----- Bat (better cat) -----

export BAT_THEME="Visual Studio Dark+"

# ---- Eza (better ls) -----
alias la="eza --icons=always --all --tree --no-git"
alias ls="eza --icons=always --all --oneline --no-git"

# ---- Starship (better prompt) -----
export STARSHIP_CONFIG=~/.config/starship/starship.toml
eval "$(starship init zsh)"
# ---- TheFuck -----

# thefuck alias
eval $(thefuck --alias)
eval $(thefuck --alias fk)


# ---- Direnv (.envrc auto-loading) -----
eval "$(direnv hook zsh)"


# ---- zoxide (better cd) -----
if [[ "$CLAUDECODE" != "1" ]]; then
    eval "$(zoxide init --cmd cd zsh)"
fi

# ---- Zellij (better terminal) -----
export ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij"
eval "$(zellij setup --generate-completion zsh)"

if [ "$TERM_PROGRAM" != "vscode" ]; then
    eval "$(zellij setup --generate-auto-start zsh)"
fi


[[ -r "${HOME}/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh" ]] && . "${HOME}/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh"
# ---- Navi (CLI cheatsheets) ----- Not using, instead use atuin scripts to save commands
# eval "$(navi widget zsh)"
# export NAVI_CONFIG="$HOME/.config/navi/config.yaml"
# export NAVI_PATH="$HOME/.config/navi/cheats"
# Init pyenv
source ~/.pyenv-init

reload-completions() {
  autoload -Uz compinit; compinit -i
  (( $+functions[_jj] )) && unfunction _jj
  (( $+functions[_zellij] )) && unfunction _zellij
  (( $+functions[_nrfutil] )) && unfunction _nrfutil
  command -v jj      >/dev/null && source <(jj util completion zsh)
  command -v zellij  >/dev/null && source <(zellij setup --generate-completion zsh)
  if command -v nrfutil >/dev/null; then
    if nrfutil completion zsh --help >/dev/null 2>&1; then
      source <(nrfutil completion zsh)
    elif [[ -r ~/.config/zsh/completions/_nrfutil ]]; then
      source ~/.config/zsh/completions/_nrfutil
    fi
  fi
}
