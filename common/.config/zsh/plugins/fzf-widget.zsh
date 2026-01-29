#!/usr/bin/env zsh
#
[[ -r /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
# Rebind ALT-c to CTRL-e
# bindkey -rM emacs '\ec'
# bindkey -rM vicmd '\ec'
# bindkey -rM viins '\ec'
#
# zle -N fzf-cd-widget
# bindkey -M emacs '\C-e' fzf-cd-widget
# bindkey -M vicmd '\C-e' fzf-cd-widget
# bindkey -M viins '\C-e' fzf-cd-widget

fjust() {
  local file="$(
    fd '[Jj]ustfile|\..*just' -tf --strip-cwd-prefix |
      fzf \
        --ansi \
        --reverse \
        --no-sort \
        --preview-label '[ Justfiles ]' \
        --preview 'just --list -f {}' \
        --header-first \
        --prompt "Justfiles > " \
        --preview-window up:60%
  )"

  if [[ -n "$file" ]]; then
    LBUFFER+="just -f $file --choose"
    zle reset-prompt
  fi
}
bindkey '^j' fjust
zle -N fjust

#

fzf-man-widget() {
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

# `Ctrl-H` keybinding to launch the widget (this widget works only on zsh, don't know how to do it on bash and fish (additionaly pressing`ctrl-backspace` will trigger the widget to be executed too because both share the same keycode)
bindkey '^h' fzf-man-widget
zle -N fzf-man-widget
# Icon used is nerdfont
#
fzf-nav-widget() {

  # Store the STDOUT of fzf in a variable
  selection=$(
    find -type d | fzf --multi --height=80% --border=sharp \
      --preview='tree -C {}' --preview-window='45%,border-sharp' \
      --prompt='Dirs > ' \
      --bind='del:execute(rm -ri {+})' \
      --bind='ctrl-p:toggle-preview' \
      --bind='ctrl-d:change-prompt(Dirs > )' \
      --bind='ctrl-d:+reload(find -type d)' \
      --bind='ctrl-d:+change-preview(tree -C {})' \
      --bind='ctrl-d:+refresh-preview' \
      --bind='ctrl-f:change-prompt(Files > )' \
      --bind='ctrl-f:+reload(find -type f)' \
      --bind='ctrl-f:+change-preview(cat {})' \
      --bind='ctrl-f:+refresh-preview' \
      --bind='ctrl-a:select-all' \
      --bind='ctrl-x:deselect-all' \
      --header '
    CTRL-D to display directories | CTRL-F to display files
    CTRL-A to select all | CTRL-x to deselect all
    ENTER to edit | DEL to delete
    CTRL-P to toggle preview
    '
  )

  # Determine what to do depending on the selection
  if [ -d "$selection" ]; then
    cd "$selection" || exit
  else
    eval "$EDITOR $selection"
  fi
  zle reset-prompt
}

bindkey '^g' fzf-nav-widget
zle -N fzf-nav-widget
