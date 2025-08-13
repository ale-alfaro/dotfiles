#!/bin/bash

export GOROOT="/usr/local/go"
if [ -d "$GOROOT" ]; then
    mkdir -p "$GOROOT"
fi

echo "export GOROOT=$GOROOT
      export GOPATH=$HOME/.go
      export PATH=$PATH:$GOPATH/bin" >> ~/.zshenv

yay -S --noconfirm --needed \
  wget curl unzip inetutils impala \
  fd eza fzf ripgrep zoxide bat jq xmlstarlet \
  wl-clipboard fastfetch btop \
  man tldr less whois plocate bash-completion \
  atuin jujutsu zellij starship thefuck direnv stow tldr man-pages



# sudo mkdir -p "../.config/fzf"
# sudo curl -sL https://raw.githubusercontent.com/junegunn/fzf-git.sh/main/fzf-git.sh -o "../.config/fzf/fzf-git.sh"
