# ------------------------------------------------------------------------------
# .zshenv - PATH extensions
# ------------------------------------------------------------------------------
# PATH is extended here in ~/.zprofile instead of ~/.zshenv (the more "correct"
# place) because sometimes /etc/zprofile exports PATH, overriding modifications
# made in ~/.zshenv. ~/.zprofile runs after /etc/zprofile. This ensures user
# PATH additions are available in all login shells.
typeset -U path PATH
path=($HOME/.local/bin $path)
export PATH

if [[ $- != *i* ]]; then
  source <(mise activate zsh --shims)
fi
