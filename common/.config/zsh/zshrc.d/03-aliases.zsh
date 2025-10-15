# ---- Editor -----
alias v="n"

n() {
  if [[ "$#" -eq 0 ]]; then nvim; fi
  if [[ "$#" -eq 1 ]]; then
    case "$1" in
      zsh)
        nvim "$ZDOTDIR"
        ;;
      hypr)
        nvim "$XDG_CONFIG_HOME/hypr/hyprland"
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

# Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

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
if [[ "$OSTYPE" == "linux"* ]]; then
  open() {
    xdg-open "$@" >/dev/null 2>&1 &
  }
fi
# ---- Eza (better ls) -----
if has eza; then
  alias lt='eza --tree --level=2 --long --icons --git'
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
