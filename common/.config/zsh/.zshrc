## For zsh configuration related needs go to https://thevaluable.dev/zsh-install-configure-mouseless/

if [[ -n ${NRFUTIL_TOOLCHAIN_MANAGER_PROMPT_PREFIX} ]]; then
  echo "Running nrfutil!"
  return
fi

if [[ $- != *i* ]]; then
  # export CODEX_HOME="$XDG_CONFIG_HOME/codex"
  source <(mise activate zsh --shims)
  return
fi
for file in $ZDOTDIR/zshrc.d/*.zsh; do
  source "$file"
done
