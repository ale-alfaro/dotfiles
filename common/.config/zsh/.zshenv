# ------------------------------------------------------------------------------
# .zshenv - PATH extensions
# ------------------------------------------------------------------------------
# PATH is extended here in ~/.zprofile instead of ~/.zshenv (the more "correct"
# place) because sometimes /etc/zprofile exports PATH, overriding modifications
# made in ~/.zshenv. ~/.zprofile runs after /etc/zprofile. This ensures user
# PATH additions are available in all login shells.

if [[ -z $PATH ]]; then
  typeset -U path PATH
  path=($HOME/.local/bin $HOME/.local/share/mise/shims $path)
  export PATH
else
  export PATH="/home/alealfaro/.local/bin:$PATH"
  export PATH="/home/alealfaro/.local/share/mise/shims:$PATH"
fi
export MISE_SHIMS_ADDED_TO_PATH=1
