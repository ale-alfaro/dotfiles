## For zsh configuration related needs go to https://thevaluable.dev/zsh-install-configure-mouseless/

if [[ $- != *i* ]]; then
  echo "Non interactive mode"
  return
fi

for file in $ZDOTDIR/zshrc.d/*.zsh; do
  source "$file"
done

# Ghostty shell integration for Bash. This should be at the top of your bashrc!
# Some zsh plugins
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
bd_zsh="$ZDOTDIR/plugins/bd.zsh"
[[ -f "$bd_zsh" ]] && source "$bd_zsh"
# Some other stuff I might remove
safe_source mise activate zsh
safe_source atuin init zsh
safe_source starship init zsh
# source <(codex completion zsh)
# source <(ast-grep completions)
# if [[ ! -z ${ACLI_ENABLED:-} ]]; then
#   source <(acli completion zsh)
#   source $ZDOTDIR/helpers/acli.zsh
# fi
# source <(mise completion zsh)
# source <(gh completion -s zsh)
# source <(sg completions)
# source <(hk completion zsh)
