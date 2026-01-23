#!bin/env zsh
#
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
}

_fzf_compgen_dir() {
  fd -td --strip-cwd-prefix "$1" 2>/dev/null
}

_fzf_compgen_run() {
  cmd="$1"
  shift
  case "$cmd" in
    pacman | yay)
      fpkg_pacman "$@"
      ;;
    *)
      fzf "$@"
      ;;
  esac
}
