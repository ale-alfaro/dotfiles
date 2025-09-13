#######################################################
# Shell integrations
#######################################################

# ---- Atuin (better shell command history) -----
eval "$(atuin init zsh)"

# ---- Starship (better prompt) -----
export STARSHIP_CONFIG=~/.config/starship/starship.toml
eval "$(starship init zsh)"
# ---- Direnv (.envrc auto-loading) -----
eval "$(direnv hook zsh)"

# ---- zoxide (better cd) -----
if [[ "$CLAUDECODE" != "1" ]]; then
    eval "$(zoxide init --cmd zd zsh)"
fi

# ---- Zellij (better terminal) -----
export ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij"

# Initialize Node Version manager
. /usr/share/nvm/init-nvm.sh
# export PYENV_ROOT="$HOME/.pyenv"
# [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init - zsh)"
