#!/usr/bin/env zsh

# +--------+
# | Pacman |
# +--------+

# TODO can improve that with a bind to switch to what was installed
fpac() {
  pacman -Slq | fzf --multi --reverse --preview 'pacman -Si {1}' | xargs -ro sudo pacman -S
}

fyay() {
  yay -Slq | fzf --multi --reverse --preview 'yay -Si {1}' | xargs -ro yay -S
}
