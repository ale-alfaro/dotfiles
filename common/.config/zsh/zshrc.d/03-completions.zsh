# Set Up Completion
#   Amazing Article going over the Zsh completion system https://thevaluable.dev/zsh-completion-guide-examples/
#   To see the zsh completion help either call _complete_help in the shell or use CTRL+X h
#   Also look at man zshmodules and Search for “zstyle”
#
# Some general Zsh completion stuff:
#   Startup flow:
#     1. Load fpath completion directories (i.e directories with the _<CMD_NAME> style that provide completions for that command)
#     2. Call autocompload & compinit to inilize the completion system
#     3. Do zstyle adjustements to the completion namespace
#   Zstyle:
#     zstyle format: :<namespace>:<function>:<additional_args>
#     zstyle completion format: :completion:<function>:<completer>:<command>:<argument>:<tag>
# Definitions of zstyle completion (see all tags and other optons using man zshcompsys):
#   - completion - String acting as a namespace, to avoid pattern collisions with other scripts also using zstyle.
#   - <function> - Apply the style to the completion of an external function or widget.
#   - <completer> - Apply the style to a specific completer. We need to drop the underscore from the completer’s name here.
#   - <command> - Apply the style to a specific command, like cd, rm, or sed for example.
#   - <argument> - Apply the style to the nth option or the nth argument. It’s not available for many styles.
#   - <tag> - Apply the style to a specific tag.
# ------------------------------------------------------------------------------
#
# Initialize First plguin, this plugin only adds more completions to the fpath so we call it before compload init
plugins=(
  zsh-users/zsh-completions
)
__init_plugins "${plugins[@]}"
# --- MAN Completion generator ---
ZSH_GEN_COMPLETIONS_FROM_MANPAGES_PATH="$HOME/.local/share/zsh/site"
fpath+=("$ZSH_GEN_COMPLETIONS_FROM_MANPAGES_PATH" $fpath)

# Load my custom or generated manually completions
fpath=($ZDOTDIR/completions/src $fpath)
# Load more completions from other sources of fpath

# Homebrew completions (MacOS)
# ------------------------------------------------------------------------------
if [[ "$OSTYPE" == "darwin"* ]]; then
  if has brew; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
  fi
fi
if has nrfutil; then
  [[ -r "${HOME}/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh" ]] && . "${HOME}/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh"
fi

# --- Initialize completion system ---
autoload -U compinit
compinit
_comp_options+=(globdots) # With hidden files

# +---------+
# | Options |
# +---------+

# setopt GLOB_COMPLETE      # Show autocompletion menu with globs
setopt MENU_COMPLETE    # Automatically highlight first element of completion menu
setopt AUTO_LIST        # Automatically list choices on ambiguous completion.
setopt COMPLETE_IN_WORD # Complete from both ends of a word.
autoload -Uz compinit && compinit -d ${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump


# ------------------------------------------------------------------------------
# Define the completers to use. The completers are  listed below and their definitions
# _complete - This is the main completer we need to use for our completion.
# _approximate - This one is similar to _complete, except that it will try to correct what you’ve typed already (the context) if no match is found.
# _expand_alias - Expand an alias you’ve typed. It needs to be declared before _complete.
# _extensions - Complete the glob *. with the possible file extensions.
zstyle ':completion:*' completer _extensions _complete _approximate


# zstyle ':completion:*' completer _complete _ignored _approximate
# Problems with insecure directories under macOS?
# -> see https://stackoverflow.com/a/13785716/149220 for a solution
cache_directory="$XDG_CACHE_HOME/zsh"

## Use cache
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$cache_directory/completion-cache"

# Complete the alias when _expand_alias is used as a function
zstyle ':completion:*' complete true

# Use CTRL+X + A to expand an alias
zle -C alias-expension complete-word _generic
bindkey '^Xa' alias-expension
zstyle ':completion:alias-expension:*' completer _expand_alias

#Select in a menu
zstyle ':completion:*' menu select

# Autocomplete options for cd instead of directory stack
zstyle ':completion:*' complete-options true

zstyle ':completion:*' file-sort modification
# --- Completion styles ---
zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*:*:*:*:descriptions' format '%F{blue}-- %D %d --%f'
zstyle ':completion:*:*:*:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:*:*:*:warnings' format ' %F{red}-- no matches found --%f'

# zstyle ':completion:*:default' list-prompt '%S%M matches%s'
# Colors for files and directory
zstyle ':completion:*:*:*:*:default' list-colors ${(s.:.)LS_COLORS}

# Only display some tags for the command cd
zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
# zstyle ':completion:*:complete:git:argument-1:' tag-order !aliases

# Required for completion to be in good groups (named after the tags)
zstyle ':completion:*' group-name ''

zstyle ':completion:*:*:-command-:*:*' group-order aliases builtins functions commands


## These were created by `compinstall`
# zstyle ':completion:*' matcher-list 'm:{[:lower:]}={[:upper:]} r:|[._-]=* r:|=*' 'm:{[:lower:]}={[:upper:]}' 'm:{[:lower:]}={[:upper:]}' 'm:{[:lower:]}={[:upper:]}'
# zstyle ':completion:*' max-errors 2
# zstyle :compinstall filename "$ZDOTDIR/.zshrc"

# FZF-tab completion helper
# ------------------------------------------------------------------------------
plugins=(
  Aloxaf/fzf-tab
)
__init_plugins "${plugins[@]}"

zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
