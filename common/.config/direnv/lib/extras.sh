#!/usr/bin/env bash

############## Utils ###################################
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

############## Envs ###################################

use_llm_lang_rules() {
  if [[ ! "$#" -eq 1 ]]; then
    log_fatal "Need to specify the language to add llm rules for (cpp or python)"
  fi

  # Python codebase add python llm memory
  local llm_rules_dir="$XDG_CONFIG_HOME/direnv/res/llm_memory/${1:-"python"}"
  if [[ -d "$llm_rules_dir" ]]; then
    export LLM_MEMORY_DIR="$llm_rules_dir"
  fi

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
############## Python ###################################
layout_uv_venv() {
  if [ $# -ne 1 ]; then
    log_fatal "Need to specify python version"
  fi
  python_version="--python=$1"

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

layout_uv() {
  layout_uv_venv "$1"
  if [[ ! -f "$(pwd)/pyproject.toml" ]]; then
    log_status "No uv project exists. Executing uv init --bare to create one."
    uv init --bare
  fi
}

############## Node ###################################
use_nvm() {
  local node_version=$1
  nvm_sh=~/.nvm/nvm.sh
  if [[ -e $nvm_sh ]]; then
    source $nvm_sh
    nvm use "$node_version"
  fi
}

############## GIT ###################################
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

############## Nix ###################################
source_nix_url() {
  if ! has nix_direnv_version || ! nix_direnv_version 3.1.0; then
    source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/3.1.0/direnvrc" "sha256-yMJ2OVMzrFaDPn7q8nCBZFRYpL/f0RcHzhmw/i6btJM="
  else
    log_error "Couldn't source the nix-direnv url"
  fi
}
