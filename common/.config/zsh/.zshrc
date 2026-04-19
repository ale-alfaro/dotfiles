## For zsh configuration related needs go to https://thevaluable.dev/zsh-install-configure-mouseless/

if [[ $- != *i* ]]; then
  echo "Non interactive mode"
  return
fi
source $ZDOTDIR/helpers/stdlib.zsh

for file in $ZDOTDIR/zshrc.d/*.zsh; do
  source "$file"
done

# Ghostty shell integration for Bash. This should be at the top of your bashrc!
# Some zsh plugins
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[[ -f $ZDOTDIR/plugins/bd.zsh ]] && source $ZDOTDIR/plugins/bd.zsh
# Some other stuff I might remove
safe_source mise activate zsh
safe_source atuin init zsh
safe_source starship init zsh

source <(mise completion zsh)
source <(gh completion -s zsh)
source <(hk completion zsh)
#
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

if eza; then
  alias lt='eza --tree --level=3 --long --icons --git'
  alias lta='lt -a'
  alias ls="eza --icons=always --oneline --no-git --all"
fi
