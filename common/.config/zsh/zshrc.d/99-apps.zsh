#!/usr/bin/env zsh
# Alias for FZF
# Link: https://github.com/junegunn/fzf

#######################################################
# Shell integrations
#######################################################
#
# # replace default mise hook
# add-zsh-hook precmd _mise_hook
safe_source atuin init zsh
safe_source starship init zsh
# embedder

plugins=(
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
)
__init_plugins "${plugins[@]}"

source <(mise activate zsh)
source <(codex completion zsh)
