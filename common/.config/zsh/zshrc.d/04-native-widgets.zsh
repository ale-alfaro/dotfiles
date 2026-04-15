#!/usr/bin/env zsh


# By default, Ctrl+d will not close your shell if the command line is filled, this fixes it:
exit_zsh() { exit }
zle -N exit_zsh
bindkey '^D' exit_zsh
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
  Aloxaf/fzf-tab
)
__init_plugins "${plugins[@]}"
#
zvm_after_init_commands+=(fzf_init)
fzf_init() {
  # [[ -r /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
  [[ -r $ZDOTDIR/plugins/fzf.zsh ]] && source $ZDOTDIR/plugins/fzf.zsh
  bindkey '^g' fzf-nav-widget
  zle -N fzf-nav-widget
  # `Ctrl-H` keybinding to launch the widget (this widget works only on zsh, don't know how to do it on bash and fish (additionaly pressing`ctrl-backspace` will trigger the widget to be executed too because both share the same keycode)
  bindkey '^h' fzf-man-widget
  zle -N fzf-man-widget
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
  # zstyle ':fzf-tab:complete:*' fzf-bindings 'tab:toggle+down,shift-tab:toggle+up'

  # switch group using `<` and `>`
  zstyle ':fzf-tab:*' switch-group ',' '.'

  # Do continious completion for traversing paths with ` key
  zstyle ':fzf-tab:*' continuous-trigger '`'
}

# function sesh-sessions() {
#   {
#     exec </dev/tty
#     exec <&1
#     local session
#     session=$(sesh list -t -c | fzf --height 40% --reverse --border-label ' sesh ' --border --prompt '⚡  ')
#     zle reset-prompt >/dev/null 2>&1 || true
#     [[ -z "$session" ]] && return
#     sesh connect $session
#   }
# }
#
# zle -N sesh-sessions

