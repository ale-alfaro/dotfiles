## For zsh configuration related needs go to https://thevaluable.dev/zsh-install-configure-mouseless/

if [[ $- != *i* ]]; then
  echo "Non interactive mode"
  return
fi
source $ZDOTDIR/helpers/stdlib.zsh

if [[ -f "$HOME/.local/state/dots/toggles/ssh-agent" ]]; then
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519_yubikey
  if [[ -z "${SSH_CONNECTION:-}" ]]; then
    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
  fi
fi

autoload fsesh dots-toggle
for file in $ZDOTDIR/zshrc.d/*.zsh; do
  source "$file"
done
# SSH agent started by systemd automatically. Only need to set the socketp
# Ghostty shell integration for Bash. This should be at the top of your bashrc!
# Some zsh plugins
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[[ -f $ZDOTDIR/plugins/bd.zsh ]] && source $ZDOTDIR/plugins/bd.zsh
# dots-toggle-check mise_activate
## The hook below is to check the date updated by pacman to
# rehash the completions after a certain time
zshcache_time="$(date +%s%N)"

autoload -Uz add-zsh-hook

rehash_precmd() {
  if [[ -e /var/cache/zsh/pacman ]]; then
    local paccache_time="$(date -r /var/cache/zsh/pacman +%s%N)"
    if ((zshcache_time < paccache_time)); then
      rehash
      zshcache_time="$paccache_time"
    fi
  fi
}

add-zsh-hook -Uz precmd rehash_precmd

if [[ $- == *i* ]] && [[ ${TERM:-} != "dumb" ]]; then
  eval "$(starship init zsh)"
fi

if [[ -z "${NO_MISE_ACTIVATE:-}" ]]; then
  source <(mise activate zsh)
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
safe_source zoxide init zsh
alias cd='zd'

# ---- Editor -----
autoload fvim
alias v="fvim"

# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
# [[ ! -r '/home/alealfaro/.opam/opam-init/init.zsh' ]] || source '/home/alealfaro/.opam/opam-init/init.zsh' > /dev/null 2> /dev/null
# END opam configuration

# Worktrunk for working with git-worktrees
if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi
