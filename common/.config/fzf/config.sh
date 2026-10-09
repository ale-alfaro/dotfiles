export FZF_FILE_EXPLORER_PREVIEW="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

# export FZF_CTRL_T_COMMAND="fd -t file"
export FZF_ALT_C_OPTS="
    --walker-skip .git,node_modules,target
    --preview 'eza -lh --group-directories-first --icons=auto {}'
    --height=80%
    --bind 'ctrl-/:change-preview-window(down|hidden|)'
    --header 'CTRL-/: Toggle preview window position'
    "

export FZF_DEFAULT_COMMAND="rg --files --follow --hidden --glob '!.git'"
# export FZF_CTRL_T_OPTS="--height=100% --preview='bat --color=always {}'"
export FZF_CTRL_T_OPTS="
      --height=100%
      --preview='$FZF_FILE_EXPLORER_PREVIEW'
      "

# shellcheck disable=SC1091
. "${HOME}/dotfiles/common/.config/fzf/theme.sh"
# export FZF_DEFAULT_OPTS="--height 100% \
# --walker-skip .git,node_modules,target \
# --border sharp \
# --layout reverse \
# --color '$FZF_COLORS' \
# --prompt '∷ ' \
# --pointer ▶ \
# --marker ⇒"
export FZF_DEFAULT_OPTS="
--ansi  \
--info=inline-right \
--layout=reverse \
--border=none \
--bind shift-up:preview-page-up,shift-down:preview-page-down \
--color '$FZF_COLORS' \
"
