# Path to your oh-my-zsh installation.
# Reevaluate the prompt string each time it's displaying a prompt
#
ZINIT_HOME="${XDG_CONFIG_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [[ ! -d "${ZINIT_HOME}" ]]; then
    mkdir -p "(dirname $ZINIT_HOME)" && \
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" && \
    echo "zinit installed"
fi

source "${ZINIT_HOME}/zinit.zsh"

#Add zsh plugins
#Add syntax highlighting to zsh
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
#Add fuzzy-finder completion search
zinit light Aloxaf/fzf-tab

#Add in snippets
#Git aliases (ga, gc, etc)
zinit snippet OMZP::git

#Press esc twice to add sudo to current command or
#the previous command that failed
zinit snippet OMZP::sudo

#Suggest packages after getting command not found
zinit snippet OMZP::command-not-found

#setopt prompt_subst
autoload -Uz compinit && compinit

zinit cdreplay -q

bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
#completion styling (case insensitive)
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors '${(s.:.)LS_COLORS}'
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups

export MANPAGER="$(which nvim) +Man!"
export XDG_CONFIG_HOME="$HOME/.config"
export EDITOR=/opt/homebrew/bin/nvim
alias v="nvim"

# ---- Aliases -----
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."
alias cl='clear'

# ---- Atuin (better shell command history) -----
eval "$(atuin init zsh)"

# ---- Brew service start Sketchybar ----
alias sbrld='brew services reload sketchybar'

# ---- JJ (Git alternative) -----
source <(jj util completion zsh)

# ----- Bat (better cat) -----

export BAT_THEME="Visual Studio Dark+"

# ---- Eza (better ls) -----
alias la="eza --icons=always --all --tree --no-git"
alias ls="eza --icons=always --all --oneline --no-git"

# ---- Starship (better prompt) -----
export STARSHIP_CONFIG=~/.config/starship/starship.toml
eval "$(starship init zsh)"
# ---- TheFuck -----

# thefuck alias
eval $(thefuck --alias)
eval $(thefuck --alias fk)

# ---- FZF -----

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"

# --- setup fzf theme ---
fg="#CBE0F0"
bg="#011628"
bg_highlight="#143652"
purple="#B388FF"
blue="#06BCE4"
cyan="#2CF9ED"

export FZF_DEFAULT_OPTS="--color=fg:${fg},bg:${bg},hl:${purple},fg+:${fg},bg+:${bg_highlight},hl+:${purple},info:${blue},prompt:${cyan},pointer:${cyan},marker:${cyan},spinner:${cyan},header:${cyan}"

# -- Use fd instead of fzf --

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

source ~/.config/fzf/fzf-git.sh
show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \${}'"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

# ---- Direnv (.envrc auto-loading) -----
eval "$(direnv hook zsh)"


# ---- zoxide (better cd) -----
if [[ "$CLAUDECODE" != "1" ]]; then
    eval "$(zoxide init --cmd cd zsh)"
fi

# ---- Zellij (better terminal) -----
export ZELLIJ_CONFIG_DIR="$XDG_CONFIG_HOME/zellij"
eval "$(zellij setup --generate-completion zsh)"

if [ "$TERM_PROGRAM" != "vscode" ]; then
    eval "$(zellij setup --generate-auto-start zsh)"
fi
# ---- Navi (CLI cheatsheets) -----
eval "$(navi widget zsh)"
export NAVI_CONFIG="$HOME/.config/navi/config.yaml"
export NAVI_PATH="$HOME/.config/navi/cheats"

# -- Completions --

# From nrfutil completion install for shell completion
[[ -r "${HOME}/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh" ]] && . "${HOME}/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh"

#For python invoke completion
## Invoke tab-completion script to be sourced with the Z shell.
# Known to work on zsh 5.0.x, probably works on later 4.x releases as well (as
# it uses the older compctl completion system).

_complete_invoke() {
    # `words` contains the entire command string up til now (including
    # program name).
    #
    # We hand it to Invoke so it can figure out the current context: spit back
    # core options, task names, the current task's options, or some combo.
    #
    # Before doing so, we attempt to tease out any collection flag+arg so we
    # can ensure it is applied correctly.
    collection_arg=''
    if [[ "${words}" =~ "(-c|--collection) [^ ]+" ]]; then
        collection_arg=$MATCH
    fi
    # `reply` is the array of valid completions handed back to `compctl`.
    # Use ${=...} to force whitespace splitting in expansion of
    # $collection_arg
    reply=( $(invoke ${=collection_arg} --complete -- ${words}) )
}


# Tell shell builtin to use the above for completing our given binary name(s).
# * -K: use given function name to generate completions.
# * +: specifies 'alternative' completion, where options after the '+' are only
#   used if the completion from the options before the '+' result in no matches.
# * -f: when function generates no results, use filenames.
# * positional args: program names to complete for.
compctl -K _complete_invoke + -f invoke inv


