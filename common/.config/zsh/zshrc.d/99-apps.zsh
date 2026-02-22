#!/usr/bin/env zsh
# Alias for FZF
# Link: https://github.com/junegunn/fzf

#######################################################
# Shell integrations
#######################################################
safe_source atuin init zsh
safe_source starship init zsh
plugins=(
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
)
__init_plugins "${plugins[@]}"

source <(codex completion zsh)
