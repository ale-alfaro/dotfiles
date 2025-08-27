#######################################################
# Environment Variables
#######################################################
#

#>>> Added by Toolbox App
export EDITOR=nvim
export VISUAL=nvim
export SUDO_EDITOR=nvim
export FCEDIT=nvim
export TERMINAL=ghostty
export BROWSER=zen-browser # Not sure if this works
export MANPAGER="sh -c 'awk '\''{ gsub(/\x1B\[[0-9;]*m/, \"\", \$0); gsub(/.\x08/, \"\", \$0); print }'\'' | bat -p -lman'"
export PAGER=bat

export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
    --info=default\
    --ansi \
    --layout=reverse \
    --border=rounded \
    --color=border:#27a1b9 \
    --color=fg:#c0caf5 \
    --color=gutter:#16161e \
    --color=header:#ff9e64 \
    --color=hl+:#2ac3de \
    --color=hl:#2ac3de \
    --color=info:#545c7e \
    --color=marker:#ff007c \
    --color=pointer:#ff007c \
    --color=prompt:#2ac3de \
    --color=query:#c0caf5:regular \
    --color=scrollbar:#27a1b9 \
    --color=separator:#ff9e64 \
    --color=spinner:#ff007c \
    "

# SSH agent started by systemd automatically. Only need to set the socket
if [[ -z "${SSH_CONNECTION}" ]]; then
    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi
export PICO_HOME=$HOME/.pico-sdk
export PICO_SDK_PATH=$PICO_HOME/sdk
export PICO_EXAMPLES_PATH=$PICO_HOME/examples
export PICO_OPENOCD_PATH=$PICO_HOME/openocd
# export PICO_PLAYGROUND_PATH=$PICO_HOME/pico-playground
