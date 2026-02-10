#!/usr/bin/env zsh
# +---------+
# | Widgets |
# +---------+
# autoloading functions
## Enable vi mode
bindkey -v
export KEY_TIMEOUT=1

# create a zkbd compatible hash;
# to add other keys to this hash, see: man 5 terminfo
typeset -g -A key

# key[Home]="${terminfo[khome]}"
# key[End]="${terminfo[kend]}"
# key[Insert]="${terminfo[kich1]}"
# key[Backspace]="${terminfo[kbs]}"
# key[Delete]="${terminfo[kdch1]}"
# key[Up]="${terminfo[kcuu1]}"
# key[Down]="${terminfo[kcud1]}"
# key[Left]="${terminfo[kcub1]}"
# key[Right]="${terminfo[kcuf1]}"
# key[PageUp]="${terminfo[kpp]}"
# key[PageDown]="${terminfo[knp]}"
# key[ShiftTab]="${terminfo[kcbt]}"
#
# # setup key accordingly
# [[ -n "${key[Home]}"      ]] && bindkey -- "${key[Home]}"      beginning-of-line
# [[ -n "${key[End]}"       ]] && bindkey -- "${key[End]}"       end-of-line
# [[ -n "${key[Insert]}"    ]] && bindkey -- "${key[Insert]}"    overwrite-mode
# [[ -n "${key[Backspace]}" ]] && bindkey -- "${key[Backspace]}" backward-delete-char
# [[ -n "${key[Delete]}"    ]] && bindkey -- "${key[Delete]}"    delete-char
# [[ -n "${key[Up]}"        ]] && bindkey -- "${key[Up]}"        up-line-or-history
# [[ -n "${key[Down]}"      ]] && bindkey -- "${key[Down]}"      down-line-or-history
# [[ -n "${key[Left]}"      ]] && bindkey -- "${key[Left]}"      backward-char
# [[ -n "${key[Right]}"     ]] && bindkey -- "${key[Right]}"     forward-char
# [[ -n "${key[PageUp]}"    ]] && bindkey -- "${key[PageUp]}"    beginning-of-buffer-or-history
# [[ -n "${key[PageDown]}"  ]] && bindkey -- "${key[PageDown]}"  end-of-buffer-or-history
# [[ -n "${key[ShiftTab]}"  ]] && bindkey -- "${key[ShiftTab]}"  reverse-menu-complete
#
# bindkey -M viins "^q" push-input
#
# # Finally, make sure the terminal is in application mode, when zle is
# # active. Only then are the values from $terminfo valid.
# if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
# 	autoload -Uz add-zle-hook-widget
# 	function zle_application_mode_start { echoti smkx }
# 	function zle_application_mode_stop { echoti rmkx }
# 	add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
# 	add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
# fi
#
# autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
# zle -N up-line-or-beginning-search
# zle -N down-line-or-beginning-search
#
# [[ -n "${key[Up]}"   ]] && bindkey -- "${key[Up]}"   up-line-or-beginning-search
# [[ -n "${key[Down]}" ]] && bindkey -- "${key[Down]}" down-line-or-beginning-search

# By default, Ctrl+d will not close your shell if the command line is filled, this fixes it:

autoload -U edit-command-line
zle -N edit-command-line
bindkey '^V' edit-command-line

# Make CTRL-Z background things and unbackground them.
# Based off https://github.com/wincent/wincent/commit/30b502d811fbf4ca058db3a6f006aaecab68f6b7
function fg-bg() {
  if [[ $#BUFFER -eq 0 ]]; then
    local backgroundProgram="$(jobs | tail -n 1 | awk '{print $4}')"
    case "$backgroundProgram" in
      "nc" | "ncat" | "netcat" | "resize-netcat-listener" | "rnc")
        # Make sure that /dev/tty is given to the stty command by doing </dev/tty
        terminal-size-clip </dev/tty
        stty raw -echo </dev/tty
        fg
        ;;
      *)
        fg
        ;;
    esac
  else
    zle push-input
  fi
}
zle -N fg-bg
bindkey '^Z' fg-bg

bd_zsh="$ZDOTDIR/plugins/bd.zsh"
[[ -f "$bd_zsh" ]] && source "$bd_zsh"

source <(fzf --zsh)

plugins=(
  jeffreytse/zsh-vi-mode
  Aloxaf/fzf-tab
)
__init_plugins "${plugins[@]}"
#
zvm_after_init_commands+=(fzf_init)
fzf_init() {
  [[ -r "$ZDOTDIR/plugins/fzf-widget.zsh" ]] && source "$ZDOTDIR/plugins/fzf-widget.zsh"
  # fzf-tab
  # preview directory's content with eza when completing cd
  # Fix colors for light terminal screens
  zstyle ':fzf-tab:complete:(v|n|nvim):*' fzf-preview '[[ -d $realpath ]] && eza --tree --color=always $realpath | head -200 || bat -n --color=always --line-range :500 $realpath'
  zstyle ':fzf-tab:complete:(z|cd|zd):*' fzf-preview 'eza --tree --color=always $realpath | head -200'
  # zstyle ':fzf-tab:complete:(z|cd|zd):*' fzf-preview 'eza --icons=always --oneline --no-git --all $realpath'
  # To make fzf-tab follow FZF_DEFAULT_OPTS.
  # NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
  zstyle ':fzf-tab:*' use-fzf-default-opts yes

  # Enable multi select in tab completions using tab and shift tab
  zstyle ':fzf-tab:complete:*' fzf-bindings 'tab:toggle+down,shift-tab:toggle+up'

  # switch group using `<` and `>`
  zstyle ':fzf-tab:*' switch-group ',' '.'

  # Do continious completion for traversing paths with ` key
  zstyle ':fzf-tab:*' continuous-trigger '`'
}
