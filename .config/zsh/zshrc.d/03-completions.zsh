source <(jj util completion zsh)
source <(zellij setup --generate-completion zsh)
[[ -r "${HOME}/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh" ]] && . "${HOME}/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh"
# --- Completion generator setup ---
MY_COMPLETIONS_DIR=$ZDOTDIR/completions
GENCOMPL_FPATH=$MY_COMPLETIONS_DIR/src

zstyle :plugin:zsh-completion-generator programs bat
fpath=($ZDOTDIR/completions/src $fpath)
source $ZDOTDIR/completions/zsh-completion-generator/zsh-completion-generator.plugin.zsh

# --- Initialize completion system ---
autoload -Uz compinit
compinit -i

# --- Replay intercepted compdefs from plugins ---
zinit cdreplay -q

# --- Completion styles ---
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

