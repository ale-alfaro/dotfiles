echo ".zshrc start"
if [[ -o login ]]; then
  echo "Welcome $USER zsh"
else
  echo "Not a login shell"
  source "$ZDOTDIR/.zprofile"
fi
for file in $ZDOTDIR/zshrc.d/*.zsh; do
  source "$file"
done
