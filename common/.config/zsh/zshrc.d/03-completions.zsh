# Set Up Completion
# ------------------------------------------------------------------------------
# Problems with insecure directories under macOS?
# -> see https://stackoverflow.com/a/13785716/149220 for a solution
cache_directory="$XDG_CACHE_HOME/zsh"

## Use cache
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$cache_directory/completion-cache"


# --- Completion styles ---
# zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
## These were created by `compinstall`
zstyle ':completion:*' completer _complete _ignored _approximate
zstyle ':completion:*' matcher-list 'm:{[:lower:]}={[:upper:]} r:|[._-]=* r:|=*' 'm:{[:lower:]}={[:upper:]}' 'm:{[:lower:]}={[:upper:]}' 'm:{[:lower:]}={[:upper:]}'
zstyle ':completion:*' max-errors 2
zstyle :compinstall filename "$ZDOTDIR/.zshrc"

# Homebrew (brew.sh)
# ------------------------------------------------------------------------------
if [[ "$OSTYPE" == "darwin"* ]]; then
  if [[ -e "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    echo ERROR: Could not find brew. Skip setting up brew shellenv.
  fi
## Brew completions
  if type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
    autoload -Uz compinit
    compinit -d "$cache_directory/compinit-dumpfile"
  else
    echo ERROR: Could not load brew completions.
  fi
fi

if has nrfutil; then
  [[ -r "${HOME}/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh" ]] && . "${HOME}/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh"
fi
# --- Completion generator setup ---
ZSH_GEN_COMPLETIONS_FROM_MANPAGES_PATH="$HOME/.local/share/zsh/site"
fpath+=("$ZSH_GEN_COMPLETIONS_FROM_MANPAGES_PATH" $fpath)

fpath=( /home/alealfaro/.local/share/uv/tools/argcomplete/lib/python3.12/site-packages/argcomplete/bash_completion.d "${fpath[@]}" )
## Initialize completion system
### Set location for compinit's dumpfile.
fpath=($ZDOTDIR/completions/src $fpath)
# --- Initialize completion system ---
autoload -Uz compinit && compinit -d ${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump


