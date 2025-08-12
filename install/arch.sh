# Determine the platform
OS=$(uname -s)

if [ "$OS" != "Linux" ]; then


    echo "This script is only for Linux"
    exit 1

fi

# Install the dependencies
sudo pacman -S --noconfirm --needed \
    base-devel \
    git \
    jj \
    go \
    go-tools \
    make \
    python \
    python-pip \
    python-virtualenv \

