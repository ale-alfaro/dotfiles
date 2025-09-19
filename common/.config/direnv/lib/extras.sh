#!/usr/bin/env bash

# Usage: use_env_dir [env_dir]
#
# Load environment variables from `$(direnv_layout_dir)/envs" directory.
# Under this directory, every file is read and set to an environment
# variable whose name is the filename and value is the file content.
#
# Also watch files so to automatically reload on every file update.
use_env_dir() {
  local env_dir
  env_dir="${1:-$(direnv_layout_dir)/envs}"
  if [[ -d $env_dir ]]; then
    for f in "$env_dir"/*; do
      if [[ -f $f ]]; then
        watch_file "$f"
        export "$(basename "$f")=$(cat "$f")"
      fi
    done
  fi
}

layout_uv() {
  if [[ -d ".venv" ]]; then
    VIRTUAL_ENV="$(pwd)/.venv"
  fi
  if [[ -z $VIRTUAL_ENV || ! -d $VIRTUAL_ENV ]]; then
    log_status "No virtual environment exists. Executing uv venv to create one."
    uv venv
    VIRTUAL_ENV="$(pwd)/.venv"
  fi
  PATH_add "$VIRTUAL_ENV/bin"
  export UV_ACTIVE=1 # or VENV_ACTIVE=1
  export VIRTUAL_ENV
  export UV_PYTHON="$VIRTUAL_ENV/bin/python"
}

layout_and_init_uv() {
  if [[ -d ".venv" ]]; then
    VIRTUAL_ENV="$(pwd)/.venv"
  fi
  if [[ -z $VIRTUAL_ENV || ! -d $VIRTUAL_ENV ]]; then
    log_status "No uv project exists. Executing uv init --no-readme to create one."
    uv init --no-readme
    rm hello.py
    uv venv
    VIRTUAL_ENV="$(pwd)/.venv"
  fi
  PATH_add "$VIRTUAL_ENV/bin"
  export UV_ACTIVE=1 # or VENV_ACTIVE=1
  export VIRTUAL_ENV
  export UV_PYTHON="$VIRTUAL_ENV/bin/python"
}

alias_justfile_recipes() {
  justfile_home="${JUSTFILE_HOME:-$HOME/.config/just}"
  justfile_recipes="$justfile_home/${1:""}/justfile"
  for recipe in $(just --justfile "$justfile_recipes" --summary); do
    echo "aliasing $recipe"
    alias "$recipe"='just --justfile "$justfile_recipes" --working-directory . "$recipe"'
  done
}
#Github, Gemini env vars
use_developer_envs() {
  use_env_dir "$HOME/.config/direnv/envs"
}

use_nvm() {
  local node_version=$1
  nvm_sh=~/.nvm/nvm.sh
  if [[ -e $nvm_sh ]]; then
    source $nvm_sh
    nvm use "$node_version"
  fi
}
