#!/usr/bin/env zsh

# By default, Ctrl+d will not close your shell if the command line is filled, this fixes it:
zle_exit_zsh() { exit; }
zle -N zle_exit_zsh
bindkey '^D' zle_exit_zsh

# Edit command line in $EDITOR with Ctrl+V
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^V' edit-command-line

# Make CTRL-Z background things and unbackground them.
# Based off https://github.com/wincent/wincent/commit/30b502d811fbf4ca058db3a6f006aaecab68f6b7
function zle_fg_bg() {
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

zle -N zle_fg_bg
bindkey '^Z' zle_fg_bg

function zle_sesh_sessions() {
  {
    exec </dev/tty
    exec <&1
    local session
    session=$(sesh list -t -c | fzf --height 40% --reverse --border-label ' sesh ' --border --prompt '⚡  ')
    zle reset-prompt >/dev/null 2>&1 || true
    [[ -z "$session" ]] && return
    sesh connect $session -c 'mise en'
  }
}

zle -N zle_sesh_sessions
bindkey "^S" zle_sesh_sessions

zle_man() {
  manpage="echo {} | sed 's/\([[:alnum:][:punct:]]*\) (\([[:alnum:]]*\)).*/\2 \1/'"
  batman="${manpage} | xargs -r man | col -bx | bat --language=man --plain --color always --theme=\"Monokai Extended\""
  man -k . | sort |
    awk -v cyan=$(tput setaf 6) -v blue=$(tput setaf 4) -v res=$(tput sgr0) -v bld=$(tput bold) '{ $1=cyan bld $1; $2=res blue $2; } 1' |
    fzf \
      -q "$1" \
      --ansi \
      --tiebreak=begin \
      --prompt=' Man > ' \
      --preview-window '50%,rounded,<50(up,85%,border-bottom)' \
      --preview "${batman}" \
      --bind "enter:execute(${manpage} | xargs -r man)" \
      --bind "alt-c:+change-preview(cht.sh {1})+change-prompt(ﯽ Cheat > )" \
      --bind "alt-m:+change-preview(${batman})+change-prompt( Man > )" \
      --bind "alt-t:+change-preview(tldr --color=always {1})+change-prompt(ﳁ TLDR > )"
  zle reset-prompt
}

zle -N zle_man
bindkey '^H' zle_man

zle_copy_last_cmd() {
  wl-copy "!!"
}
zle -N zle_copy_last_cmd
bindkey '' zle_copy_last_cmd

# zle_edit_last_cmd() {
#   fc
# }
# zle -N zle_copy_last_cmd
# bindkey '' zle_copy_last_cmd
