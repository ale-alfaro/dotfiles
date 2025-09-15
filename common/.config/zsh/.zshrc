if [[ -o login ]]; then
  echo "Welcome $USER zsh"
else
  echo "Not a login shell. Paths for ~/.local, rust, go and justfile wont be appended"
fi
for file in ${XDG_CONFIG_HOME:-$HOME/.config}/zsh/zshrc.d/*.zsh; do
  source "$file"
done
