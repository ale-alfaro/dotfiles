echo "Welcome to my zsh config"

for file in ${XDG_CONFIG_HOME:-$HOME/.config}/zsh/zshrc.d/*.zsh; do
  source "$file"
done
