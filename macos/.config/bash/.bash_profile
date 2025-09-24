#!/bin/bash
[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"

if [[ -f ~/.bashrc ]]; then
  source ~/.bashrc
fi

. "$HOME/.local/bin/env"
