#######################################################
# Environment Variables
#######################################################
#
export XDG_CONFIG_HOME="$HOME/.config"
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

#>>> Added by Toolbox App
export PATH="$PATH:/usr/local/bin"
export EDITOR=nvim
export VISUAL=nvim
export SUDO_EDITOR=nvim
export FCEDIT=nvim
export TERMINAL=wezterm
export BROWSER=/Applications/Arc.app # Not sure if this works
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
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
