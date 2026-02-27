#!/bin/bash

CATEGORIES=(
    "WORK"
    "VIM"
    "WASTE"
    "STOP"
)

selected=$(printf "%s\n" "${CATEGORIES[@]}" | sk --margin 10% --color="bw" --bind 'q:abort')
sk_status=$?

if [[ $sk_status -ne 0 || -z "$selected" ]]; then
    exit 0
fi

tmux set -g status-interval 5

if [[ "$selected" == "STOP" ]]; then
    timew stop >/dev/null 2>&1
    tmux set -g status-right ""
else
    timew start "$selected" >/dev/null 2>&1
    tmux set -g status-right "$selected #(timew | awk '/^ *Total/ {print \$NF}')"

    if [[ "$selected" == "WASTE" ]]; then
        hostess rm www.youtube.com >/dev/null 2>&1
        hostess rm www.reddit.com >/dev/null 2>&1
    else
        hostess add www.youtube.com 127.0.0.1 >/dev/null 2>&1
        hostess add www.reddit.com 127.0.0.1 >/dev/null 2>&1
    fi

fi
