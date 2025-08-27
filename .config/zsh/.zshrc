echo "Welcome to my zsh config"
# Using zinit as plugin manager. Look at examples at:
#https://github.com/zdharma-continuum/zinit-configs/tree/master
for file in ${XDG_CONFIG_HOME:-$HOME/.config}/zsh/zshrc.d/*.zsh; do
  source "$file"
done

export PATH="$HOME/dotfiles/bin:$PATH"