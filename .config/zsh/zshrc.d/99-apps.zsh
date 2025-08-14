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

##### TODO: sed to uncomment copy_command for different OS. For now do it manually
# OS="$(uname -s)"
# if [[ "$OS" == "Linux" ]]; then
#     sed -i '#// copy_command "wl-copy"#copy_command "wl_copy"' $XDG_CONFIG_HOME/zellij/config.kdl
# elif [[ "$OS" == "Darwin" ]]; then
#     sed -i '' '#// copy_command "pbcopy"#copy_command "pb_copy"' $XDG_CONFIG_HOME/zellij/config.kdl
# fi
#

if [[  "$ZELLIJ_AUTO_START" ]]; then
    if [[ "$ZELLIJ_AUTO_ATTACH" == "true" ]]; then
        zellij attach -c
    else
        zellij -l welcome
    fi

    if [[ "$ZELLIJ_AUTO_EXIT" == "true" ]]; then
        exit
    fi
fi
#

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"



