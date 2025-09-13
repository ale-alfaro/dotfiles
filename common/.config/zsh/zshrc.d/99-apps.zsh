#######################################################
# Shell integrations
#######################################################

# ---- Atuin (better shell command history) -----
eval "$(atuin init zsh)"

# ----- Bat (better cat) -----

export BAT_THEME="Visual Studio Dark+"

# ---- Eza (better ls) -----
alias la="eza --icons=always --all --tree --no-git"
alias ls="eza --icons=always --all --oneline --no-git"

# ---- Starship (better prompt) -----
export STARSHIP_CONFIG=~/.config/starship/starship.toml
eval "$(starship init zsh)"
# ---- Direnv (.envrc auto-loading) -----
eval "$(direnv hook zsh)"

# ---- zoxide (better cd) -----
if [[ "$CLAUDECODE" != "1" ]]; then
    eval "$(zoxide init --cmd zd zsh)"
fi

# export PYENV_ROOT="$HOME/.pyenv"
# [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init - zsh)"
