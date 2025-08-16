
OS=$(uname -s)
echo ".zprofile for OS: $OS"

#export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export BW_SESSION="g3WsizXmr7aEYVQ9U7CYAy5936aKyyARbCQQwndqNHNdbKH2/v5pzGe7LE3tRNFOQWgiDfJqyYz/kzalitFunA=="

if [[ $OS == "Darwin" ]]; then
    echo "Setting up Homebrew"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "Running UWSM for $USER"
    if uwsm check may-start && uwsm select; then
	    exec uwsm start default
    fi
    # source<(keychain --eval --quiet id_ed25519 id_rsa ~/.ssh/id_ed25519)
fi


