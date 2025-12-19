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

if [[ "$OSTYPE" == "linux"* ]]; then
  open() {
    xdg-open "$@" >/dev/null 2>&1 &
  }
fi
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
  alias .j='just --justfile ~/.config/just/Justfile --working-directory .'
fi
