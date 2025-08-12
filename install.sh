
#Create .zshenv and set ZDOTDIR
if [ ! -f ~/.zshenv ]; then
    touch ~/.zshenv
    echo "export XDG_CONFIG_HOME=${HOME}/.config" >> ~/.zshenv
    echo "export ZDOTDIR=${XDG_CONFIG_HOME}/zsh" >> ~/.zshenv
fi

bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
# Install zsh-syntax-highlighting
ZINIT_HOME="${XDG_CONFIG_HOME}/zinit/zinit.git"

[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Install Missing Packages
# Atuin (better command history)
sudo pacman -S atuin

# Git
sudo pacman -S git

# JJ (better git)
sudo pacman -S jujutsu

# Go, Python
sudo pacman -S go python

# Install Navi
sudo pacman -S navi

# Install Zellij
sudo pacman -S zellij

OS=$(uname -s)
if [ "$OS" = "Darwin" ]; then
    zellij options --theme-dir "/Users/alealfaro/dotfiles/.config/zellij/themes"
else
    zellij options --theme-dir "/home/alealfaro/dotfiles/.config/zellij/themes"
fi
#Install zoxide (better cd)
sudo pacman -S zoxide

# Install fzf
sudo pacman -S fzf
mkdir -p ".config/fzf"
curl -sL https://raw.githubusercontent.com/junegunn/fzf-git.sh/main/fzf-git.sh -o ".config/fzf/fzf-git.sh"

# Install ripgrep
sudo pacman -S ripgrep

# Install fd
sudo pacman -S fd-find

# Install bat
sudo pacman -S bat

# Install fzf-tab
sudo pacman -S fzf-tab

# Install eza
sudo pacman -S eza

# Install Starship (better prompt)
sudo pacman -S starship

# Install the fuck
sudo pacman -S thefuck

#Install direnv (.envrc auto-loading)
sudo pacman -S direnv

# Install Stow
sudo pacman -S stow

# Stow
stow .
