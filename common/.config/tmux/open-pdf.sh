#!/bin/bash

DIRS=(
    "$OBSIDIAN_HOME/Personal-Geek"
    "$OBSIDIAN_HOME/Sibel-Work"
)

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(fd . "${DIRS[@]}" --max-depth=2 --extension="djvu" --extension="epub" --extension="pdf" --full-path --base-directory "$HOME" |
        sed "s|^$HOME/||" |
        sk --margin 10% --color="bw")

    [[ $selected ]] && selected="$HOME/$selected"
fi

[[ ! $selected ]] && exit 0

selected_name=$(basename "$selected" | tr . _)

tmux neww -d zathura $selected
