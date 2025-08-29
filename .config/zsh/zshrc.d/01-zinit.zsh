# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

#######################################################
# ZSH Basic Options
#######################################################

setopt autocd              # change directory just by typing its name
setopt correct             # auto correct mistakes
setopt interactivecomments # allow comments in interactive mode
setopt magicequalsubst     # enable filename expansion for arguments of the form ‘anything=expression’
setopt nonomatch           # hide error message if there is no match for the pattern
setopt notify              # report the status of background jobs immediately
setopt numericglobsort     # sort filenames numerically when it makes sense
setopt promptsubst         # enable command substitution in prompt

# Disable the cursor style feature
function zvm_config() {
    ZVM_CURSOR_STYLE_ENABLED=false
    # ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
    # ZVM_VI_INSERT_ESCAPE_BINDKEY=jk

    ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BEAM
    ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BLOCK
    ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_BLINKING_UNDERLINE
}
############# Using TURBO MODE #############
# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit ice lucid wait'0'
zinit light joshskidmore/zsh-fzf-history-search
zinit light jeffreytse/zsh-vi-mode

#Set option for clipboard zsh plugin
# ZSH_SYSTEM_CLIPBOARD_METHOD="wlc" # wayland clipboard (CLIPBOARD)
ZSH_SYSTEM_CLIPBOARD_METHOD="wlp" # wayland clipboard (PRIMARY)
zinit light kutsan/zsh-system-clipboard

# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
# zinit snippet OMZP::tmuxinator
zinit snippet OMZP::docker
zinit snippet OMZP::command-not-found

