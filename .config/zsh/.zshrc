# Path to your oh-my-zsh installation.
# Reevaluate the prompt string each time it's displaying a prompt
#
ZINIT_HOME="${XDG_CONFIG_HOME:-${HOME}/.local/share}/zinit/zinit.git"


#>>> go setup
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

#>>> Added by Toolbox App
export PATH="$PATH:/usr/local/bin"

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
#Add fuzzy-finder completion search (Using plugin https://github.com/Aloxaf/fzf-tab)
zinit light zsh-users/zsh-autosuggestions

# For postponing loading `fzf`
zinit ice lucid wait
zinit snippet OMZP::fzf
# zsh-fzf-history-search
zinit ice lucid wait'0'
zinit light joshskidmore/zsh-fzf-history-search

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

#VIM MOTIONS IN TERMINAL YAY
zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode
# preview directory's content with eza when completing cd
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors '${(s.:.)LS_COLORS}'

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

# ---- Editor -----
export EDITOR=/opt/homebrew/bin/nvim
alias v="nvim"
alias nvim_pre='~/.local/nvim-0_12-prerelease/bin/nvim'

# ---- Aliases -----
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ......="cd ../../../../.."
alias cl='clear'

function zvm_after_init() {

  # ---- FZF -----

  # eval "$(fzf --zsh)"
  # fzf init script for additional customizations such as:
  # key bindings
  # previews
  # tab completion
  # [ -f ${XDG_CONFIG_HOME}/fzf/fzf-init.sh ] && source ${XDG_CONFIG_HOME}/fzf/fzf-init.sh

  # atuin search
  zvm_bindkey viins '^R' atuin-search
  zvm_bindkey vicmd '^R' atuin-search
}

# The plugin will auto execute this zvm_config function
zvm_config() {
# Disable the cursor style feature
    ZVM_CURSOR_STYLE_ENABLED=false
  # # Retrieve default cursor styles
  # local ncur=$(zvm_cursor_style $ZVM_NORMAL_MODE_CURSOR)
  # local icur=$(zvm_cursor_style $ZVM_INSERT_MODE_CURSOR)
  #
  # # Append your custom color for your cursor
  # ZVM_INSERT_MODE_CURSOR=$icur'\e\e]12;red\a'
  # ZVM_NORMAL_MODE_CURSOR=$ncur'\e\e]12;#008800\a'
}


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
#
# # -- Completions --
#
# # From nrfutil completion install for shell completion
# [[ -r "${HOME}/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh" ]] && . "${HOME}/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh"
#
# #For python invoke completion
# ## Invoke tab-completion script to be sourced with the Z shell.
# # Known to work on zsh 5.0.x, probably works on later 4.x releases as well (as
# # it uses the older compctl completion system).
#
# _complete_invoke() {
#     # `words` contains the entire command string up til now (including
#     # program name).
#     #
#     # We hand it to Invoke so it can figure out the current context: spit back
#     # core options, task names, the current task's options, or some combo.
#     #
#     # Before doing so, we attempt to tease out any collection flag+arg so we
#     # can ensure it is applied correctly.
#     collection_arg=''
#     if [[ "${words}" =~ "(-c|--collection) [^ ]+" ]]; then
#         collection_arg=$MATCH
#     fi
#     # `reply` is the array of valid completions handed back to `compctl`.
#     # Use ${=...} to force whitespace splitting in expansion of
#     # $collection_arg
#     reply=( $(invoke ${=collection_arg} --complete -- ${words}) )
# }
#

# Tell shell builtin to use the above for completing our given binary name(s).
# * -K: use given function name to generate completions.
# * +: specifies 'alternative' completion, where options after the '+' are only
#   used if the completion from the options before the '+' result in no matches.
# * -f: when function generates no results, use filenames.
# * positional args: program names to complete for.
# compctl -K _complete_invoke + -f invoke inv


#pyenv
source ~/.pyenv-init



. "$HOME/.local/bin/env"
