## For zsh configuration related needs go to https://thevaluable.dev/zsh-install-configure-mouseless/

# If not running interactively, don't do anything (leave this at the top of this file)
if [[ $- != *i* ]]; then
  export CODEX_HOME="$XDG_CONFIG_HOME/codex"
  source <(mise activate zsh --shims)
  return
fi
for file in $ZDOTDIR/zshrc.d/*.zsh; do
  source "$file"
done
