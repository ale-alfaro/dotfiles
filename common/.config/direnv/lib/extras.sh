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

uv_check_for_deps() {
  deps_map=("$@")
  if [[ -z "$deps_map" ]]; then
    log_error "uv_check_for_deps: No dependency map provided."
    return 1
  fi

  for group in "${!deps_map[@]}"; do
    local deps_list="${deps_map[$group]}"
    read -r -a individual_deps <<<"$deps_list"

    for dep in "${individual_deps[@]}"; do
      if ! uv pip show "$dep" &>/dev/null; then
        log_status "uv has missing dependency: $dep (group: $group). Adding."
        uv add --group "$group" "$dep"
      fi
    done
  done
}

layout_uv_venv() {

  python_version="--python=${1:-3.12}"

  if [[ -d ".venv" ]]; then
    VIRTUAL_ENV="$(pwd)/.venv"
  fi
  if [[ -z $VIRTUAL_ENV || ! -d $VIRTUAL_ENV ]]; then
    log_status "No virtual environment exists. Executing uv venv to create one."
    uv venv "$python_version"
    VIRTUAL_ENV="$(pwd)/.venv"
  fi
  PATH_add "$VIRTUAL_ENV/bin"
  export UV_ACTIVE=1 # or VENV_ACTIVE=1
  export VIRTUAL_ENV
  export UV_PYTHON="$VIRTUAL_ENV/bin/python"
}

layout_uv_project() {

  project_type="${1:-virtual}"
  uv_project_init_cmd="uv init --bare --$project_type"
  if [[ ! -f "$(pwd)/pyproject.toml" ]]; then
    log_status "No uv project exists. Executing $uv_project_init_cmd to create one."
    $uv_project_init_cmd
  fi
}

layout_uv() {
  layout_uv_venv "$1"
  layout_uv_project "$2"
}

alias_justfile_recipes() {
  justfile_home="${JUSTFILE_HOME:-$HOME/.config/just}"
  justfile_recipes="$justfile_home/${1:""}/justfile"
  for recipe in $(just --justfile "$justfile_recipes" --summary); do
    echo "aliasing $recipe"
    alias "$recipe"='just --justfile "$justfile_recipes" --working-directory . "$recipe"'
  done
}
use_developer_envs() {

  local env_type
  if [[ -z $WORK_ENV ]]; then
    env_type="personal"
  else
    env_type="work"
  fi
  use_env_dir "$XDG_CONFIG_HOME/direnv/envs/common"
  use_env_dir "$XDG_CONFIG_HOME/direnv/envs/${env_type}"
}

use_nvm() {
  local node_version=$1
  nvm_sh=~/.nvm/nvm.sh
  if [[ -e $nvm_sh ]]; then
    source $nvm_sh
    nvm use "$node_version"
  fi
}

git_update_submodules() {
  git submodule status | while IFS= read -r line; do
    status_prefix=$(echo "$line" | awk '{print substr($1, 1, 1)}')
    # submodule_path=$(echo "$line" | awk '{print $2}')
    if [[ $status_prefix == "-" ]]; then
      echo "Updating submodules"
      git submodule update --init --recursive --remote
      break
    fi
  done
}
