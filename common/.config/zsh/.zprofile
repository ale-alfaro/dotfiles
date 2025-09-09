OS=$(uname -s)
echo ".zprofile for OS: $OS"

if [[ $OS == "Darwin" ]]; then
    echo "Setting up Homebrew"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "Running UWSM for $USER"
    if uwsm check may-start && uwsm select; then
	    exec uwsm start default
    fi
fi
