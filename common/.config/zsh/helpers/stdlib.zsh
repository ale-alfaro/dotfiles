#!/usr/bin/env zsh

# has <command>: 0 if a binary or shell function exists, else 1.
has() {
  type "$1" &>/dev/null || {
    print -u2 "Command not found: $1"
    return 1
  }
}

# safe_source <cmd> [args...]: source the output of a command if it exists.
safe_source() {
  has "$1" || return 1
  source <("$@")
}

# __init_plugins <owner/repo>...: clone into $ZDOTDIR/plugins if missing, then source.
__init_plugins() {
  local plugin dir
  for plugin in "$@"; do
    dir="$ZDOTDIR/plugins/$plugin"
    [[ -d "$dir" ]] || git clone "https://github.com/$plugin.git" "$dir"
    source "$dir/${plugin:t}.plugin.zsh"
  done
}
