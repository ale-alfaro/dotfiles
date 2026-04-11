## For zsh configuration related needs go to https://thevaluable.dev/zsh-install-configure-mouseless/

if [[ -n ${NRFUTIL_TOOLCHAIN_MANAGER_PROMPT_PREFIX} ]]; then
  echo "Running nrfutil!"
  return
fi

for file in $ZDOTDIR/zshrc.d/*.zsh; do
  source "$file"
done

export PATH="$PATH:$ZDOTDIR/funcs"
# funcs=( ${(f@)"$(print -r $ZDOTDIR/funcs/*(#q:t))"} )
# print "Loading functions $funcs"
# autoload "${funcs[@]}"
# Ghostty shell integration for Bash. This should be at the top of your bashrc!
if [ -n "${GHOSTTY_RESOURCES_DIR}" ]; then
  source "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration"
fi
if [[ $- != *i* ]]; then
  eval "(/home/alealfaro/.local/bin/mise activate zsh --shims)"
  echo "Non interactive mode"
  return
fi
eval "$(/home/alealfaro/.local/bin/mise activate zsh)" # added by https://mise.run/zsh

# typeset -i _mise_updated

# replace default mise hook
# function _mise_hook {
#   local diff=${__MISE_DIFF}
#   source <(command mise hook-env -s zsh)
#   [[ ${diff} == ${__MISE_DIFF} ]]
#   _mise_updated=$?
# }
#
# _PROMPT="${PROMPT}" # or _PROMPT=${PROMPT} to keep the default
#
# function _prompt {
#   if ((${_mise_updated})); then
#     PROMPT='%F{blue}${_PROMPT}%f'
#   else
#     PROMPT='%(?.%F{green}${_PROMPT}%f.%F{red}${_PROMPT}%f)'
#   fi
# }
#
# add-zsh-hook precmd _prompt
# ---- Eza (better ls) -----
if has eza; then
  alias lt='eza --tree --level=3 --long --icons --git'
  alias lta='lt -a'
  alias ls="eza --icons=always --oneline --no-git --all"
fi

zd() {
  if [ $# -eq 0 ]; then
    builtin cd ~ && return
  elif [ -d "$1" ]; then
    builtin cd "$1"
  else
    zi "$1"
  fi
}
if has zoxide; then
  safe_source zoxide init zsh
  alias cd='zd'
fi
JUST_HOME="${XDG_CONFIG_HOME}/just"
export JUST_HOME
user_justfiles="${JUST_HOME}/.user"
if [[ -d "$user_justfiles" ]]; then
  for file in $user_justfiles/*.just; do
    for recipe in $(just --justfile $file --summary); do
      alias $recipe="just --justfile $file --working-directory . $recipe"
    done
  done
fi
safe_source atuin init zsh
safe_source starship init zsh
plugins=(
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-autosuggestions
)
__init_plugins "${plugins[@]}"

source <(codex completion zsh)
source <(ast-grep completions)
if [[ ! -z ${ACLI_ENABLED:-} ]]; then
  source <(acli completion zsh)
  source $ZDOTDIR/helpers/acli.zsh
fi
source <(gh completion -s zsh)
source <(sg completions)
