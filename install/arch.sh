# Determine the platform
OS=$(uname -s)

if [ "$OS" != "Linux" ]; then

    echo "This script is only for Linux"
    exit 1

fi

export GOROOT="/usr/local/go"
if [ -d "$GOROOT" ]; then
    mkdir -p "$GOROOT"
fi
export GOPATH="$HOME/.go"
export PATH="$PATH:$GOPATH/bin"


sudo pacman -Sy atuin jujutsu zellij zoxide fzf ripgrep fd bat eza starship thefuck direnv stow tldr man-pages

# Install fzf
sudo mkdir -p "../.config/fzf"
sudo curl -sL https://raw.githubusercontent.com/junegunn/fzf-git.sh/main/fzf-git.sh -o "../.config/fzf/fzf-git.sh"

# Install the dependencies
sudo pacman -S --noconfirm --needed \
    base-devel \
    go \
    go-tools \
    llvm \
    cmake \
    ninja \
    curl \
    wget \
    jq \
    python \
    python \
    python-pip \
    python-virtualenv \
    pyenv


sudo go install github.com/go-delve/delve/cmd/dlv@latest
