# ---- Editor -----
alias v="n"

n() {
  if [[ "$#" -eq 0 ]]; then nvim .; fi
  if [[ "$#" -eq 1 ]]; then
    if [[ -d "$1" ]]; then
      zd "$1"
    else
      nvim "$1"
    fi
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
open() {
  xdg-open "$@" >/dev/null 2>&1 &
}
# ---- Eza (better ls) -----
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'
alias ls="eza --icons=always --oneline --no-git"
# Alias For bat
# Link: https://github.com/sharkdp/bat
if [[ -x "$(command -v bat)" ]]; then
  alias cat='bat'
fi
if [[ -x "$(command -v batman)" ]]; then
  alias man='batman'
fi
# Alias for zellij
# Link: https://github.com/jesseduffield/lazygit
# alias zellij='zellij -l welcome'
if [[ -x "$(command -v zesh)" ]]; then
  alias zeshij='zesh cn $(zesh list | fzf)'
fi
# Alias for lazygit
# Link: https://github.com/jesseduffield/lazygit
alias lg='lazygit'

# Alias for FZF
# Link: https://github.com/junegunn/fzf
if [[ -x "$(command -v fzf)" ]]; then
  alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
fi
#Make sure to have the API key before running gemini-cli
# alias gemini='source ~/dotfiles/.envrc && gemini'
