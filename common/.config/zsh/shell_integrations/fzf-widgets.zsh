#!/usr/bin/env zsh

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
  rm -f /tmp/rg-fzf-{r,f}
  RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case "
  INITIAL_QUERY="${1:-}"
  fzf --ansi --disabled --query "$INITIAL_QUERY" \
    --bind "start:reload:$RG_PREFIX {q}" \
    --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
    --bind 'alt-t:transform:[[ ! $FZF_PROMPT =~ ripgrep ]] &&
      echo "rebind(change)+change-prompt(1. ripgrep> )+disable-search+transform-query:echo \{q} > /tmp/rg-fzf-f; cat /tmp/rg-fzf-r" ||
      echo "unbind(change)+change-prompt(2. fzf> )+enable-search+transform-query:echo \{q} > /tmp/rg-fzf-r; cat /tmp/rg-fzf-f"' \
    --color "hl:-1:underline,hl+:-1:underline:reverse" \
    --prompt '1. ripgrep> ' \
    --delimiter : \
    --header 'ALT-T: Switch between ripgrep/fzf' \
    --preview 'bat --color=always {1} --highlight-line {2}' \
    --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
    --bind 'enter:execute(nvim {1} +{2})'

  zle reset-prompt
}

bindkey '^g' fzf-nav-widget
zle -N fzf-nav-widget

justpick() {
  local jf recipe
  jf=$(
    fd '[Jj]ustfile|\..*just' --type file |
      fzf --ansi --no-sort --reverse --tiebreak=index \
        --preview 'bat --color=always --style=plain {}' \
        --preview-window up:60% \
        --prompt 'Justfiles> ' \
        --bind 'alt-e:execute(just --edit --justfile {})'
  ) || return

  recipe=$(
    just --justfile "$jf" --summary --unsorted |
      tr ' ' '\n' |
      fzf --ansi --no-sort --reverse --tiebreak=index \
        --prompt 'Recipes> ' \
        --preview "just --unstable --color always --justfile \"$jf\" --show {}" \
        --preview-window up:60% \
        --bind 'enter:accept'
  ) || return

  just --justfile "$jf" "$recipe"
}

fzf-just-widget() {

  res=$(justpick)

  if [[ -n "$res" ]]; then
    LBUFFER=$LBUFFER
    zle redisplay
  fi
}
bindkey '^j' fzf-just-widget
zle -N fzf-just-widget
