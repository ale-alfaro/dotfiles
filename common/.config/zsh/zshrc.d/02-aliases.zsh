#!/usr/bin/env zsh

compress() {
  tar -czf "${1%/}.tar.gz" "${1%/}"
}

alias decompress="tar -xzf"
zd() {
  if [ $# -eq 0 ]; then
    builtin cd ~ && return
  elif [ -d "$1" ]; then
    builtin cd "$1"
  else
    zi "$1"
  fi
}
safe_source zoxide init zsh
alias cd='zd'

# ---- Editor -----
fnvim() {
  local gotopath=$(
    zoxide query -l -s |
      fzf -q "$1" \
        --prompt=' Nvim> ' \
        --accept-nth 2 \
        --preview-window '50%,rounded,<50(up,85%,border-bottom)' \
        --preview '[[ -d {2} ]] && eza --tree --color=always {2} | head -200 || bat -n --color=always --line-range :500 {2}'
  )

  nvim "$gotopath"
}

# Array to quoted list of strings
n() {
  if [[ $# -eq 0 ]]; then nvim; fi
  if [[ $# -eq 1 ]]; then
    if [[ ! -d "$1" && ! -f "$1" ]]; then
      fnvim "$1"
    else
      nvim "$1"
    fi
  else
    nvim "$@"
  fi
}
alias v="n"

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
alias minimax='NVIM_APPNAME=nvim-minimax nvim'
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
# Enable the help command
autoload -Uz run-help
((${+aliases[run - help]})) && unalias run-help
alias help=run-help
