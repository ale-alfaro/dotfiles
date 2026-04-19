#!/usr/bin/env zsh
#
## Set option for bash compatibility
## BASH_REMATCH stores the result of a regex expression
# setopt BASH_REMATCH
## Zsh arrays are 1-indexed by default. This options enable 0-indexed arrays which are compatible with bash
# setopt KSH_ARRAYS
# Usage: has <command>

# Usage: log_status [<message> ...]
#
# Logs a status message. Acts like echo,
# but wraps output in the standard direnv log format
# and directs it to stderr rather than stdout.
#
# Example:
#
#    log_status "Loading ..."
#
log_status() {
  print "$*"
}

# Usage: log_error [<message> ...]
#
# Logs an error message. Acts like echo,
# but wraps output in the standard direnv log format
# and directs it to stderr rather than stdout.
#
# Example:
#
#    log_error "Unable to find specified directory!"

log_error() {
  print "error: $*"
  exit 1
}
# Returns 0 if the <command> is available. Returns 1 otherwise. It can be a
# binary in the PATH or a shell function.
#
# Example:
#
#    if has curl; then
#      echo "Yes we do"
#    fi
#
has() {
  type "$1" &>/dev/null || {
    error "Command not found: $1 "
    return 1
  }
  return 0
}

safe_source() {
  cmd="$1"
  type "$cmd" &>/dev/null || {
    error "Command not found: $cmd "
    return 1
  }
  shift
  source <($cmd "$@")
}
# ------------------------------------------------------------------------------
## Load this module to ensure $EPOCHSECONDS is available
zmodload zsh/datetime

local enable_plugin_helper_messages=false
local plugins_dir="$ZDOTDIR/plugins"

function __init_plugins() {
  local plugins=("$@")
  for plugin in "${plugins[@]}"; do
    if [[ ! -d "$plugins_dir/$plugin" ]]; then
      __install_plugin "$plugin"
    fi
    if [[ -d "$plugins_dir/$plugin" ]]; then
      __load_plugin "$plugin"
    fi
  done
}

function __load_plugin() {
  local plugin="$1"
  local plugin_dir="$plugins_dir/$plugin"

  if [[ ! -d "$plugin_dir" ]]; then
    echo "Loading of plugin '$plugin' aborted, because it could not be found."
    return 1
  fi

  if $enable_plugin_helper_messages; then
    echo "Loading '$plugin'..."
  fi
  source "$plugin_dir/$(basename $plugin).plugin.zsh"
}
# ------------------------------------------------------------------------------
#     Private functions
# ------------------------------------------------------------------------------
local function __install_plugin() {
  local plugin="$1"
  local plugin_dir="$plugins_dir/$plugin"

  if [[ -d "$plugin_dir" ]]; then
    echo "Installation of '$plugin' aborted, because plugin directory already exists."
    return 1
  fi

  echo "Installing '$plugin' into '$plugin_dir'..."
  git clone "https://github.com/$plugin.git" "$plugin_dir"
}

local function __update_plugin() {
  local plugin="$1"
  local plugin_dir="$plugins_dir/$plugin"

  if [[ ! -d "$plugin_dir" ]]; then
    echo "Update aborted, because plugin '$plugin' could not be found."
    return 1
  fi

  echo "Updating '$plugin'..."
  git --git-dir="$plugin_dir/.git" pull --no-rebase
}
