## For zsh configuration related needs go to https://thevaluable.dev/zsh-install-configure-mouseless/

if [[ -n ${NRFUTIL_TOOLCHAIN_MANAGER_PROMPT_PREFIX} ]]; then
    echo "Running nrfutil!"
    return
fi

for file in $ZDOTDIR/zshrc.d/*.zsh; do
    source "$file"
done

if [[ $- != *i* ]]; then
    source <(mise activate zsh --shims)
    echo "Non interactive mode"
    return
fi
eval "$(/home/alealfaro/.local/bin/mise activate zsh)" # added by https://mise.run/zsh

# ---- Eza (better ls) -----
if has eza; then
    alias lt='eza --tree --level=3 --long --icons --git'
    alias lta='lt -a'
    alias ls="eza --icons=always --oneline --no-git --all"
fi

zd() {
    if [ $# -eq 0 ]; then
        builtin cd ~ && return
    elif [ -d "$1" ]; then
        builtin cd "$1"
    else
        zi "$1"
    fi
}
if has zoxide; then
    safe_source zoxide init zsh
    alias cd='zd'
fi
JUST_HOME="${XDG_CONFIG_HOME}/just"
export JUST_HOME
user_justfiles="${JUST_HOME}/.user"
if [[ -d "$user_justfiles" ]]; then
    for file in $user_justfiles/*.just; do
        for recipe in $(just --justfile $file --summary); do
            alias $recipe="just --justfile $file --working-directory . $recipe"
        done
    done
fi
safe_source atuin init zsh
safe_source starship init zsh
plugins=(
    zsh-users/zsh-syntax-highlighting
    zsh-users/zsh-autosuggestions
)
__init_plugins "${plugins[@]}"

source <(codex completion zsh)
source <(ast-grep completions)
