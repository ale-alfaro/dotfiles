#!/bin/zsh
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
# Load more completions from other sources of fpath

# +---------+
# | Options |
# +---------+

# --------------------------------------------------------------

# Ztyle pattern
# :completion:<function>:<completer>:<command>:<argument>:<tag>

# Define completers
# ----------------
# Define the completers to use. The completers are  listed below and their definitions
# _complete - This is the main completer we need to use for our completion.
# _approximate - This one is similar to _complete, except that it will try to correct what you’ve typed already (the context) if no match is found.
# _expand_alias - Expand an alias you’ve typed. It needs to be declared before _complete.
# _extensions - Complete the glob *. with the possible file extensions.
# Load custom generated manually or through MAN pages

# zstyle ':completion:*' completer _complete _ignored _approximate
# Problems with insecure directories under macOS?
# -> see https://stackoverflow.com/a/13785716/149220 for a solution

# Complete the alias when _expand_alias is used as a function


fpath=("$ZDOTDIR/completions/src" "$XDG_DATA_HOME/zsh/generated_man_completions" "$XDG_STATE_HOME/zsh/plugins/zsh-users/zsh-completions/src" $fpath)
cache_directory="$XDG_CACHE_HOME/zsh"
autoload -Uz compinit && compinit -d $cache_directory
zstyle ':completion:*' completer _extensions _complete _approximate

bd_zsh="$ZDOTDIR/shell_integrations/bd.zsh"
[[ -f "$bd_zsh" ]] && source "$bd_zsh"

# Initialize First plguin, this plugin only adds more completions to the fpath so we call it before compload init

zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
## Auto complete with case insenstivity and allowing some characters to be
#forgotten at the start like a .
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'

# Completion style
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes

# Use custom just completion without shadowing the system _just.
autoload -Uz _just_custom && compdef _just_custom just

# Only display some tags for the command cd
zstyle ':completion:*:*:(z|cd|zd):*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:(v|n|nvim):*' file-patterns \
    '%p:globbed-files' '*(-/):directories' '*:all-files'
## Use cache
# Complete the alias when _expand_alias is used as a function
zstyle ':completion:*' complete true

# Use CTRL+X + A to expand an alias
zle -C alias-expension complete-word _generic
# bindkey '^Xa' alias-expension
zstyle ':completion:alias-expension:*' completer _expand_alias

#Select in a menu
# zstyle ':completion:*' menu select

# Autocomplete options for cd instead of directory stack
zstyle ':completion:*' complete-options true

zstyle ':completion:*' file-sort modification
# --- Completion styles ---
## disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no


zstyle -d ':completion:*' format
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:corrections' format '%d (errors: %e) %f'
zstyle ':completion:*:warnings' format ' no matches found %f'
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
# zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
# zstyle ':completion:*:*:*:*:descriptions' format '%F{blue}-- %D %d --%f'
# zstyle ':completion:*:*:*:*:messages' format ' %F{purple} -- %d --%f'
# zstyle ':completion:*:*:*:*:warnings' format ' %F{red}-- no matches found --%f'

# Colors for files and directory

# Only display some tags for the command cd

#######################################################
# Zsh Plugins
#######################################################

# Required for completion to be in good groups (named after the tags)

# zstyle ':completion:*:*:-command-:*:*' group-order aliases builtins functions commands
# Media Players
# zstyle ':completion:*:*:just:*' file-patterns '([Jj]ustfile|*.just):just\ files *(-/):directories'



[[ -r /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh

plugins=(
  Aloxaf/fzf-tab
)
__init_plugins "${plugins[@]}"

# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
source "$ZDOTDIR/completions/fzf.zsh"


# fzf-tab
# preview directory's content with eza when completing cd
# Fix colors for light terminal screens
zstyle ':fzf-tab:complete:(v|n|nvim):*' fzf-preview 'bat -n --color=always --line-range :500 $realpath'
# zstyle ':fzf-tab:complete:(z|cd|zd):*' fzf-preview 'eza --tree --color=always $realpath | head -200'
zstyle ':fzf-tab:complete:(z|cd|zd):*' fzf-preview 'eza --icons=always --oneline --no-git --all'
# To make fzf-tab follow FZF_DEFAULT_OPTS.
# NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
zstyle ':fzf-tab:*' use-fzf-default-opts yes

# Enable multi select in tab completions using tab and shift tab
zstyle ':fzf-tab:complete:*' fzf-bindings 'tab:toggle+down,shift-tab:toggle+up'

# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group ',' '.'

# Do continious completion for traversing paths with ` key
zstyle ':fzf-tab:*' continuous-trigger '`'
export LISTMAX=-1


# Include hidden files in autocomplete:
_comp_options+=(globdots)

function _aliased_with_prefix() {
  shift words
  ((CURRENT--))
  _normal
}
compdef _aliased_with_prefix sudo
