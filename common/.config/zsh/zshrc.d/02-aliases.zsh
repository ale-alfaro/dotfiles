#!/usr/bin/env zsh

compress() {
  tar -czf "${1%/}.tar.gz" "${1%/}"
}

alias decompress="tar -xzf"

alias mx='mise x'
alias mr='mise run'
alias mt='mise tasks'
#######################################################
# CLI Aliases
#######################################################
# Alias For bat
alias lt='eza --tree --level=3 --long --icons --git'
alias lta='lt -a'
alias ls="eza --icons=always --oneline --no-git --all"
# Link: https://github.com/sharkdp/bat
alias wman='wikiman'
# Alias for lazygit
# Link: https://github.com/jesseduffield/lazygit
alias lg='lazygit'
alias lzd='lazydocker'
alias gdb-py='/opt/zephyr-sdk-custom/gnu/arm-zephyr-eabi/bin/arm-zephyr-eabi-gdb-py'
alias jlink-gdbserver='JLinkGDBServer  -if SWD -speed 4000 -port 2331 -silent -singlerun'
alias mx='mise x'
alias mr='mise run'
alias mt='mise tasks'
#include jq modules
alias jq='jq -L~/.config/jq'

# -------------------------------------------
# 5. Suffix Aliases - Open Files by Extension
# -------------------------------------------
# Just type the filename to open it with the associated program
alias -s json=jqp
alias -s md=bat
alias -s txt=bat
alias -s log=bat
alias -s c='$EDITOR'
alias -s h='$EDITOR'
alias -s hpp='$EDITOR'
alias -s cpp='$EDITOR'
alias -s conf='$EDITOR'
alias -s dts='$EDITOR'
alias -s html=xdg-open

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
  alias -g CP='| wl-copy'
elif [[ "$OSTYPE" == "macos"* ]]; then
  alias -g CP='| pb-copy'
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

# Navigate back to directories easily using the zsh directory stack feature
alias d='dirs -v'
for index in {1..9}; do alias "$index"="builtin cd +${index}"; done
# Enable the help command
autoload -Uz run-help
((${+aliases[run - help]})) && unalias run-help
alias help=run-help
