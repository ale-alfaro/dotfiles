#!bin/env zsh

_fzf_compgen_path() {
  fd --hidden -tf --strip-cwd-prefix "$1" 2>/dev/null | sed 's@^\./@@'
  # rg --files --glob "!.git" "$1"
}

_fzf_compgen_dir() {
  fd --hidden -td --strip-cwd-prefix "$1" 2>/dev/null | sed 's@^\./@@'
  # fd --type d --hidden --follow --exclude ".git" --strip-cwd-prefix "$1"
}

# _fzf_compgen_run() {
#   cmd="$1"
#   shift
#   case "$cmd" in
#     pacman | yay) fpkg_pacman "$@" ;;
#     man) fman "$@" ;;
#     just) fjust "$@" ;;
#     export | unset) fzf --preview "eval 'echo \${}'" "$@" ;;
#     *) fzf "$@" ;;
#   esac
# }
_fzf_complete_j() {
    fzf \
      --query="$1" \
      --ansi \
      --reverse \
      --no-sort \
      --preview-label '[ Justfiles ]' \
      --preview 'just --list -f {}' \
      --header-first \
      --prompt "Justfiles > " \
      --preview-window up:60%
}


_fzf_complete_export() {
  _fzf_complete -m -- "$@" < <(
    declare -xp | sed 's/=.*//' | sed 's/.* //'
  )
}

_fzf_complete_unset() {
  _fzf_complete -m -- "$@" < <(
    declare -xp | sed 's/=.*//' | sed 's/.* //'
  )
}

_fzf_complete_unalias() {
  _fzf_complete +m -- "$@" < <(
    alias | sed 's/=.*//'
  )
}

_fzf_complete_kill() {
  local transformer
  transformer='
    if [[ $FZF_KEY =~ ctrl|alt|shift ]] && [[ -n $FZF_NTH ]]; then
      nths=( ${FZF_NTH//,/ } )
      new_nths=()
      found=0
      for nth in ${nths[@]}; do
        if [[ $nth = $FZF_CLICK_HEADER_NTH ]]; then
          found=1
        else
          new_nths+=($nth)
        fi
      done
      [[ $found = 0 ]] && new_nths+=($FZF_CLICK_HEADER_NTH)
      new_nths=${new_nths[*]}
      new_nths=${new_nths// /,}
      echo "change-nth($new_nths)+change-prompt($new_nths> )"
    else
      if [[ $FZF_NTH = $FZF_CLICK_HEADER_NTH ]]; then
        echo "change-nth()+change-prompt(> )"
      else
        echo "change-nth($FZF_CLICK_HEADER_NTH)+change-prompt($FZF_CLICK_HEADER_WORD> )"
      fi
    fi
  '
  _fzf_complete -m --header-lines=1 --no-preview --wrap --color fg:dim,nth:regular \
    --bind "click-header:transform:$transformer" -- "$@" < <(
    command ps -eo user,pid,ppid,start,time,command 2> /dev/null ||
      command ps -eo user,pid,ppid,time,args 2> /dev/null || # For BusyBox
      command ps --everyone --full --windows # For cygwin
  )
}

_fzf_complete_kill_post() {
  __fzf_exec_awk '{print $2}'
}
# List tracking spreadsheets (productivity, money ...)
# # Find in File using ripgrep
# # Search through all man pages
fman() {
  man -k . | fzf -q "$1" --prompt='man> ' --preview $'echo {} | tr -d \'()\' | awk \'{printf "%s ", $2} {print $1}\' | xargs -r man' | tr -d '()' | awk '{printf "%s ", $2} {print $1}' | xargs -r man
}
#



_fzf_complete_pacman() {
  fzf_args=(
    --query="$@"
    --multi
    --preview 'pacman -Sii {1}'
    --preview-label='alt-p: toggle description, alt-j/k: scroll, tab: multi-select'
    --preview-label-pos='bottom'
    --preview-window 'down:65%:wrap'
    --bind 'alt-p:toggle-preview'
    --bind 'alt-d:preview-half-page-down,alt-u:preview-half-page-up'
    --bind 'alt-k:preview-up,alt-j:preview-down'
    --color 'pointer:green,marker:green'
  )
  local -a tokens
  tokens=(${(z)1})
  case ${tokens[-1]} in
    -S)
      _fzf_complete +m -- "$@" < <(pacman -Slq | tr '\n' ' ') ;;
    *)_fzf_complete +m -- "$@" ;;
  esac

}
_fzf_complete_yay() {
  fzf_args=(
    --query="$@"
    --multi
    --preview 'yay -Siia {1}'
    --preview-label='alt-p: toggle description, alt-b/B: toggle PKGBUILD, alt-j/k: scroll, tab: multi-select'
    --preview-label-pos='bottom'
    --preview-window 'down:65%:wrap'
    --bind 'alt-p:toggle-preview'
    --bind 'alt-d:preview-half-page-down,alt-u:preview-half-page-up'
    --bind 'alt-k:preview-up,alt-j:preview-down'
    --bind 'alt-b:change-preview:yay -Gpa {1} | tail -n +5'
    --bind 'alt-B:change-preview:yay -Siia {1}'
    --color 'pointer:green,marker:green'
  )

  yay -Slqa | fzf "${fzf_args[@]}"

}

_fzf_complete_nvim() {
  [[ -f "$prefix" ]]  && _fzf_path_completion "$prefix" "$1" || rg --files-with-matches --no-messages "$prefix" "$1"
}
