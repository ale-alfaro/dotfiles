#!/usr/bin/env zsh

# ---- zsh-compatible Direnv stdlib helpers + other utilities for zsh scripts -----
source "$ZDOTDIR/functions/stdlib.zsh"

compress(){
  tar -czf "${1%/}.tar.gz" "${1%/}"
}

alias decompress="tar -xzf"
shell_integrations="$ZDOTDIR/shell_integrations"
# Plugin Helper
# ------------------------------------------------------------------------------
source "$shell_integrations/plugin_helper.zsh"
# ---- Editor -----
alias v="n"

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
if has eza; then
  alias lt='eza --tree --level=3 --long --icons --git'
  alias lta='lt -a'
  alias ls="eza --icons=always --oneline --no-git --all"
fi
# Alias For bat
# Link: https://github.com/sharkdp/bat
if has bat; then
  alias cat='bat'
fi
if has batman; then
  alias man='batman'
fi
# Alias for lazygit
# Link: https://github.com/jesseduffield/lazygit
if has lazygit; then
  alias lg='lazygit'
fi
# Alias for FZF
# Link: https://github.com/junegunn/fzf
if has fzf; then
  alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
  vf(){
    fd --type file |
      fzf --prompt 'Files> ' \
          --header 'ALT-D: Switch between Files/Directories' \
          --bind 'alt-d:transform:[[ ! $FZF_PROMPT =~ Files ]] &&
                  echo "change-prompt(Files> )+reload(fd --type file)" ||
                  echo "change-prompt(Directories> )+reload(fd --type directory)"' \
          --preview '[[ $FZF_PROMPT =~ Files ]] && bat --color=always {} || tree -C {}' \
          --bind 'enter:become(nvim {})'
  }
fi
if has zoxide; then
  zv(){ 
    zoxide query -l $1 |  fzf --bind 'enter:become(nvim {})'
  }
  alias cd="zd"
  zd() {
    if [ $# -eq 0 ]; then
      builtin cd ~ && return
    elif [ -d "$1" ]; then
      builtin cd "$1"
    else
      z "$@" && printf "\U000F17A9 " && pwd || echo "Error: Directory not found"
    fi
  }
fi
# Alias for just (command runner)
if has just; then
  alias j='just'
  if [[ ! -z "${JUST_HOME}" ]]; then
    # alias .j='just --justfile ~/.config/just/Justfile --working-directory .'
    alias .j='just -g'
    user_justfiles="${JUST_HOME}/.user"
    if [[ -d "$user_justfiles" ]]; then
      for file in $user_justfiles/*.just; do
        for recipe in $(just --justfile $file --summary); do
            alias $recipe="just --justfile $file --working-directory . $recipe"
        done
      done
    fi
  fi
fi


# -------------------------------------------
# 5. Suffix Aliases - Open Files by Extension
# -------------------------------------------
# Just type the filename to open it with the associated program
alias -s json=jless
alias -s md=bat
alias -s txt=bat
alias -s log=bat
alias -s py='$EDITOR'
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
