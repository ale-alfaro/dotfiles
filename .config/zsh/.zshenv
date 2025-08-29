
echo "Running $ZDOTDIR/.zshenv"

# export XDG_CONFIG_HOME="$HOME/.config"
# export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export GOROOT="/usr/local/go"
export GOPATH="/home/alealfaro/go"
# The incantation `typeset -U path', where the -U stands for unique, tells the shell that it should not add anything to $path if it's there already. To be precise, it keeps only the left-most occurrence, so if you added something at the end it will disappear and if you added something at the beginning, the old one will disappear. Thus the following works nicely in .zshenv:
# Read more at:https://zsh.sourceforge.io/Guide/zshguide02.html#l24 - 2.5.11 Path
typeset -U path PATH
path=(~/.local/bin ~/.cargo/bin $GOROOT/bin $GOPATH/bin $path)
export PATH



