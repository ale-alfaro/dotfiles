#!/usr/bin/env zsh

# ---- zsh-compatible Direnv stdlib helpers + other utilities for zsh scripts -----
[[ -r "$ZDOTDIR/helpers/stdlib.zsh" ]] && source "$ZDOTDIR/helpers/stdlib.zsh"
# Plugin Helper
[[ -r "$ZDOTDIR/helpers/plugin_helper.zsh" ]] && source "$ZDOTDIR/helpers/plugin_helper.zsh"

# source <(mise activate zsh)

compress() {
    tar -czf "${1%/}.tar.gz" "${1%/}"
}

alias decompress="tar -xzf"
# ---- Editor -----
alias v="n"
# Array to quoted list of strings
n() {
    if [[ "$#" -eq 0 ]]; then nvim; fi
    if [[ "$#" -eq 1 ]]; then
        case "$1" in
            nvim | zsh | mise | hypr | wezterm | hypr)
                nvim "$XDG_CONFIG_HOME/$1"
                ;;
            *)
                if [[ ! -d "$1" && ! -f "$1" ]]; then
                    zi "$1" && nvim .
                else
                    nvim "$1"
                fi
                ;;
        esac
    else
        nvim "$@"
    fi
}
ssh_agent_start() {
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519_yubikey
}
alias sshstart="ssh_agent_start"
#######################################################
# CLI Aliases
#######################################################
# Alias For bat
# Link: https://github.com/sharkdp/bat
alias wman='wikiman'
# has batman && alias man='batman'
# Alias for lazygit
# Link: https://github.com/jesseduffield/lazygit
alias lg='lazygit'
# -------------------------------------------
# 5. Suffix Aliases - Open Files by Extension
# -------------------------------------------
# Just type the filename to open it with the associated program
alias -s json=jqp
alias -s md=bat
alias -s txt=bat
alias -s log=bat
# alias -s py='$EDITOR'
alias -s c='$EDITOR'
alias -s h='$EDITOR'
alias -s hpp='$EDITOR'
alias -s cpp='$EDITOR'
# alias -s Kconfig='$EDITOR'
# alias -s py='$EDITOR'
alias -s conf='$EDITOR'
alias -s dts='$EDITOR'
alias -s html=open # macOS: open in default browser

# -------------------------------------------
# 6. Global Aliases - Use Anywhere in Commands
# -------------------------------------------
# Redirect stderr to /dev/null
alias -g NE='2>/dev/null'

# Redirect stdout to /dev/null
alias -g NO='>/dev/null'

alias -g FZF='| fzf'

# Redirect both stdout and stderr to /dev/null
alias -g NUL='>/dev/null 2>&1'

# Pipe to jq
alias -g J='| jqp'

if [[ "$OSTYPE" == "linux"* ]]; then
    open() {
        xdg-open "$@" >/dev/null 2>&1 &
    }
    alias -g C='| wlcopy'
elif [[ "$OSTYPE" == "macos"* ]]; then
    alias -g C='| pbcopy'
fi

# -------------------------------------------
# 7. zmv - Advanced Batch Rename/Move
# -------------------------------------------
# Enable zmv
autoload -Uz zmv

# Usage examples:
# zmv '(*).log' '$1.txt'           # Rename .log to .txt
# zmv -w '*.log' '*.txt'           # Same thing, simpler syntax
# zmv -n '(*).log' '$1.txt'        # Dry run (preview changes)
# zmv -i '(*).log' '$1.txt'        # Interactive mode (confirm each)

# Helpful aliases for zmv
alias mmv='noglob zmv -W'
alias zcp='zmv -C' # Copy with patterns
alias zln='zmv -L' # Link with patterns

# Navigate back to directories easily using the zsh directory stack feature
alias d='dirs -v'
for index in {1..9}; do alias "$index"="builtin cd +${index}"; done
