#!bin/env zsh
#

fjust() {
  fd '^[Jj]ustfile$|\..*just$' -tf --strip-cwd-prefix |
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

# List tracking spreadsheets (productivity, money ...)
# # Find in File using ripgrep
# # Search through all man pages
function fman() {
  man -k . | fzf -q "$1" --prompt='man> ' --preview $'echo {} | tr -d \'()\' | awk \'{printf "%s ", $2} {print $1}\' | xargs -r man' | tr -d '()' | awk '{printf "%s ", $2} {print $1}' | xargs -r man
}
#
fpkg_pacman() {
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

  pacman -Slq | fzf "${fzf_args[@]}" | tr '\n' ' '
}
fpkg_yay() {
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

ff() {
  fd --type file |
    fzf --prompt 'Files> ' \
      --header 'ALT-D: Switch between Files/Directories' \
      --bind 'alt-d:transform:[[ ! $FZF_PROMPT =~ Files ]] &&
                    echo "change-prompt(Files> )+reload(fd --type file)" ||
                    echo "change-prompt(Directories> )+reload(fd --type directory)"' \
      --preview '[[ $FZF_PROMPT =~ Files ]] && bat --color=always {} || eza -T -L 2 --group-directories-first --icons=auto {}'
}

_fzf_compgen_path() {
  fd -tf --strip-cwd-prefix "$1" 2>/dev/null
  # rg --files --glob "!.git" "$1"
}

_fzf_compgen_dir() {
  fd --hidden -td --strip-cwd-prefix "$1" 2>/dev/null
  # fd --type d --hidden --follow --exclude ".git" --strip-cwd-prefix "$1"
}

_fzf_compgen_run() {
  cmd="$1"
  shift
  case "$cmd" in
    pacman | yay) fpkg_pacman "$@" ;;
    man) fman "$@" ;;
    just) fjust "$@" ;;
    export | unset) fzf --preview "eval 'echo \${}'" "$@" ;;
    *) fzf "$@" ;;
  esac
}
