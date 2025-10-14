# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

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
# if [[ $OS == "Linux" ]]; then
#   ZSH_SYSTEM_CLIPBOARD_METHOD="wlc" # wayland clipboard (CLIPBOARD)
#   # ZSH_SYSTEM_CLIPBOARD_METHOD="wlp" # wayland clipboard (PRIMARY)
# fi
zinit light kutsan/zsh-system-clipboard
#
# # Add in snippets
# zinit snippet OMZP::git
# zinit snippet OMZP::sudo
source $ZDOTDIR/functions/stdlib.zsh
