#!/usr/bin/env zsh
# Interactive shells. Reference: https://thevaluable.dev/zsh-install-configure-mouseless/
#
#
# Fill in graphical session env if missing
# for the case of starting a tmux started/attached over SSH.
# This is a problem for iOS mobile ssh clients connecting or starting
# a session in tmux
: ${XDG_RUNTIME_DIR:=/run/user/$UID}
export XDG_RUNTIME_DIR

if [[ -z $WAYLAND_DISPLAY ]]; then
  for s in $XDG_RUNTIME_DIR/wayland-*~*.lock(N=); do
    export WAYLAND_DISPLAY=${s:t}; break
  done
fi

if [[ -z $DISPLAY ]]; then
  for s in /tmp/.X11-unix/X*(N=); do
    export DISPLAY=:${${s:t}#X}; break
  done
fi

if [[ -z $DBUS_SESSION_BUS_ADDRESS && -S $XDG_RUNTIME_DIR/bus ]]; then
  export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus
fi

source $ZDOTDIR/helpers/stdlib.zsh

#######################################################
# Options (man zshoptions)
#######################################################
setopt no_flow_control # free ^S / ^Q for keybindings
setopt notify monitor  # report background job status immediately

setopt append_history extended_history share_history
setopt hist_expire_dups_first hist_find_no_dups hist_ignore_all_dups hist_ignore_dups
setopt hist_ignore_space hist_reduce_blanks hist_save_no_dups hist_verify

setopt auto_cd auto_pushd pushd_ignore_dups pushd_minus
setopt bang_hist correct interactive_comments multios no_beep prompt_subst

setopt extended_glob globdots null_glob numericglobsort
setopt auto_list complete_in_word glob_complete

# Allows the gpg passphrase prompt to spawn (signing commits).
export GPG_TTY="$(tty)"

#######################################################
# Completion (man zshcompsys, _complete_help or ^X h in the shell)
#   zstyle ':completion:<function>:<completer>:<command>:<argument>:<tag>' style value
#######################################################
fpath+=("$ZDOTDIR/completions/src" "$ZDOTDIR/functions")
[[ -r ~/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh ]] && source ~/.nrfutil/share/nrfutil-completion/scripts/zsh/setup.zsh

autoload -Uz compinit && compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"
autoload -Uz +X bashcompinit && bashcompinit
_comp_options+=(globdots)

command -v dircolors >/dev/null && eval "$(dircolors -b)"

zstyle ':completion:*' completer _complete _expand_alias _extensions _approximate _history
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu select
zstyle ':completion:*' verbose yes
zstyle ':completion:*' group-name ''
zstyle ':completion:*' file-sort modification
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:corrections' format '%d (errors: %e) %f'
zstyle ':completion:*:warnings' format ' no matches found %f'
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*:*:(z|cd|zd):*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:git-checkout:*' sort false

#######################################################
# Plugins
#######################################################
# Initialize vi-mode while sourcing so every bindkey below sticks.
ZVM_INIT_MODE=sourcing
source $ZDOTDIR/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh

source $XDG_CONFIG_HOME/fzf/config.sh # not stowed into ~/.config
source <(fzf --zsh)

__init_plugins Aloxaf/fzf-tab
zstyle ':fzf-tab:*' use-fzf-default-opts yes # see Aloxaf/fzf-tab#455 if flags break it
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' continuous-trigger '`'
zstyle ':fzf-tab:complete:*' fzf-bindings 'tab:toggle+down,shift-tab:toggle+up'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color=always $realpath'

export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f $ZDOTDIR/plugins/bd.zsh ]] && source $ZDOTDIR/plugins/bd.zsh

#######################################################
# Keybindings (man 5 terminfo for the key names)
#######################################################
typeset -gA key=(
  Home      "${terminfo[khome]}"
  End       "${terminfo[kend]}"
  Delete    "${terminfo[kdch1]}"
  Backspace "${terminfo[kbs]}"
  Up        "${terminfo[kcuu1]}"
  Down      "${terminfo[kcud1]}"
  Left      "${terminfo[kcub1]}"
  Right     "${terminfo[kcuf1]}"
  PageUp    "${terminfo[kpp]}"
  PageDown  "${terminfo[knp]}"
  Shift-Tab "${terminfo[kcbt]}"
)

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

[[ -n "${key[Home]}"      ]] && bindkey -- "${key[Home]}"      beginning-of-line
[[ -n "${key[End]}"       ]] && bindkey -- "${key[End]}"       end-of-line
[[ -n "${key[Delete]}"    ]] && bindkey -- "${key[Delete]}"    delete-char
[[ -n "${key[Backspace]}" ]] && bindkey -- "${key[Backspace]}" backward-delete-char
[[ -n "${key[Up]}"        ]] && bindkey -- "${key[Up]}"        up-line-or-beginning-search
[[ -n "${key[Down]}"      ]] && bindkey -- "${key[Down]}"      down-line-or-beginning-search
[[ -n "${key[Left]}"      ]] && bindkey -- "${key[Left]}"      backward-char
[[ -n "${key[Right]}"     ]] && bindkey -- "${key[Right]}"     forward-char
[[ -n "${key[PageUp]}"    ]] && bindkey -- "${key[PageUp]}"    beginning-of-buffer-or-history
[[ -n "${key[PageDown]}"  ]] && bindkey -- "${key[PageDown]}"  end-of-buffer-or-history
[[ -n "${key[Shift-Tab]}" ]] && bindkey -- "${key[Shift-Tab]}" reverse-menu-complete
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^a' beginning-of-line 
bindkey '^e' end-of-line 

# $terminfo values are only valid while the terminal is in application mode.
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
  autoload -Uz add-zle-hook-widget
  zle_application_mode_start() { echoti smkx }
  zle_application_mode_stop() { echoti rmkx }
  add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
  add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi

#######################################################
# Aliases and local overrides
#######################################################
[[ -n "${SSH_CONNECTION}" ]] && source $XDG_CONFIG_HOME/uwsm/env
[[ -f $ZDOTDIR/.aliases ]] && source $ZDOTDIR/.aliases
[[ -f $ZDOTDIR/.zshrc.local ]] && source $ZDOTDIR/.zshrc.local
[[ -f $ZDOTDIR/.aliases.local ]] && source $ZDOTDIR/.aliases.local

# Must be sourced last so it sees every widget.
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
