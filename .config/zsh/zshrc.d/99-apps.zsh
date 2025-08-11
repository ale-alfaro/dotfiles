#######################################################
# Shell integrations
#######################################################

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)
source $XDG_CONFIG_HOME/fzf/fzf-git.sh

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
# Init pyenv
source ~/.pyenv-init

if [[ -z "$ZELLIJ" ]]; then
    if [[ "$ZELLIJ_AUTO_ATTACH" == "true" ]]; then
        zellij attach -c
    else
        zellij -l welcome
    fi

    if [[ "$ZELLIJ_AUTO_EXIT" == "true" ]]; then
        exit
    fi
fi
