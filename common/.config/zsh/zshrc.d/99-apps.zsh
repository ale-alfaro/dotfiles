#!/usr/bin/env zsh
# Alias for FZF
# Link: https://github.com/junegunn/fzf

#######################################################
# Shell integrations
#######################################################
source <(mise activate zsh)
function mise_parse_env {
  rq -m < <(
    zcat -q < <(
      printf $'\x1f\x8b\x08\x00\x00\x00\x00\x00'
      base64 -d <<<"$1"
    )
  )
}
typeset -i _mise_updated
#
# # replace default mise hook
function _mise_hook {
  local diff=${__MISE_DIFF}
  source <(mise hook-env -s zsh)
  [[ ${diff} != ${__MISE_DIFF} ]] && mise_parse_env "${__MISE_DIFF}"
}

# add-zsh-hook precmd _mise_hook
safe_source atuin init zsh
safe_source starship init zsh
# embedder

plugins=(
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
)
__init_plugins "${plugins[@]}"

source <(codex completion zsh)
