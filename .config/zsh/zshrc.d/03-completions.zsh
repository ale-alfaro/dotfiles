source <(jj util completion zsh)
source <(zellij setup --generate-completion zsh)
[[ -r "${HOME}/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh" ]] && . "${HOME}/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh"
# if [[! -f $ZDOTDIR/completions/src/_cht ]]; then
#     curl https://cheat.sh/:zsh > $ZDOTDIR/completions/src/_cht
# fi
    # Open a new shell to load the plugin
# --- Completion generator setup ---
MY_COMPLETIONS_DIR=$ZDOTDIR/completions
GENCOMPL_FPATH=$MY_COMPLETIONS_DIR/src
ZSH_GEN_COMPLETIONS_FROM_MANPAGES_PATH="$HOME/.local/share/zsh/site"
fpath+=("$ZSH_GEN_COMPLETIONS_FROM_MANPAGES_PATH" $fpath)

# zstyle :plugin:zsh-completion-generator programs bat
fpath=($ZDOTDIR/completions/src $fpath)
source /home/alealfaro/.zsh/zsh-completion-generator/zsh-completion-generator.plugin.zsh
# --- Initialize completion system ---
autoload -Uz compinit
compinit -i -d ~/.cache/zsh/zcompdump-$ZSH_VERSION

# --- Replay intercepted compdefs from plugins ---
zinit cdreplay -q

# --- Completion styles ---
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

