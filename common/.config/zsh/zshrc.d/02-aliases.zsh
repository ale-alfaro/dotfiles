#!/usr/bin/env zsh


compress(){
  tar -czf "${1%/}.tar.gz" "${1%/}"
}

alias decompress="tar -xzf"
# ---- Editor -----
alias v="n"
# Array to quoted list of strings
a2q () {
    print ${(j:, :)${(Pqq)1}[@]}
}
n() {
  if [[ "$#" -eq 0 ]]; then nvim; fi
  if [[ "$#" -eq 1 ]]; then
    case "$1" in
      nvim | zsh | direnv | hypr | wezterm)
        nvim "$XDG_CONFIG_HOME/$1"
        ;;
      sdk-ncs)
        nvim "$HOME/ncs"
        ;;
      *)
        if [[ -d "$1" ]]; then
          zd "$1" && nvim .
        else
          nvim "$1"
        fi
        ;;
    esac
  else
    nvim "$@"
  fi
}

# Navigate back to directories easily using the zsh directory stack feature
alias d='dirs -v'
for index ({1..9}) alias "$index"="cd +${index}"; unset index

# ---- Eza (better ls) -----
# -------------------------------------------
# 5. Suffix Aliases - Open Files by Extension
# -------------------------------------------
# Just type the filename to open it with the associated program
alias -s json=jless
alias -s md=bat
alias -s txt=bat
alias -s log=bat
# alias -s py='$EDITOR'
alias -s c='$EDITOR'
alias -s h='$EDITOR'
alias -s hpp='$EDITOR'
alias -s cpp='$EDITOR'
alias -s html=open  # macOS: open in default browser

# -------------------------------------------
# 6. Global Aliases - Use Anywhere in Commands
# -------------------------------------------
# Redirect stderr to /dev/null
alias -g NE='2>/dev/null'

# Redirect stdout to /dev/null
alias -g NO='>/dev/null'

# Redirect both stdout and stderr to /dev/null
alias -g NUL='>/dev/null 2>&1'

# Pipe to jq
alias -g J='| jq'

if [[ "$OSTYPE" == "linux"* ]]; then
  open() {
    xdg-open "$@" >/dev/null 2>&1 &
  }
  alias -g C='| wlcopy'
elif [[ "$OSTYPE" == "macos"* ]]; then
  alias -g C='| pbcopy'
fi
# Copy output to clipboard (macOS)

# Copy output to clipboard (Linux with xclip)
# alias -g C='| xclip -selection clipboard'

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
alias zcp='zmv -C'  # Copy with patterns
alias zln='zmv -L'  # Link with patterns
