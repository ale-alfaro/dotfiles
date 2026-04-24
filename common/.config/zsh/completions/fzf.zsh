#!bin/env zsh

_fzf_compgen_path() {
  fd --hidden -tf --strip-cwd-prefix "$1" 2>/dev/null | sed 's@^\./@@'
  # rg --files --glob "!.git" "$1"
}

_fzf_compgen_dir() {
  fd --hidden -td --strip-cwd-prefix "$1" 2>/dev/null | sed 's@^\./@@'
  # fd --type d --hidden --follow --exclude ".git" --strip-cwd-prefix "$1"
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
      command ps -eo user,pid,ppid,start,time,command 2>/dev/null ||
        command ps -eo user,pid,ppid,time,args 2>/dev/null || # For BusyBox
        command ps --everyone --full --windows                # For cygwin
    )
}

_fzf_complete_kill_post() {
  __fzf_exec_awk '{print $2}'
}
# List tracking spreadsheets (productivity, money ...)
# # Find in File using ripgrep
# # Search through all man pages
