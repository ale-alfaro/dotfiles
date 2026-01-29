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

# Usage: load_toolchain_prefix <prefix_path>
#
# Expands some common path variables for the given <prefix_path> prefix. This is
# useful if you installed something in the <prefix_path> using
# $(./configure --prefix=<prefix_path> && make install) and want to use it in
# the project.
#
# Variables set:
#
#    CPATH
#    LD_LIBRARY_PATH
#    LIBRARY_PATH
#    MANPATH
#    PATH
#    PKG_CONFIG_PATH
#
# Example:
#
#    ./configure --prefix=$HOME/rubies/ruby-1.9.3
#    make && make install
#    # Then in the .envrc
#    load_prefix ~/rubies/ruby-1.9.3
#
load_toolchain_prefix() {
  local REPLY
  realpath.absolute "$1"
  path_add CPATH "$REPLY/include"
  path_add LD_LIBRARY_PATH "$REPLY/lib"
  path_add LIBRARY_PATH "$REPLY/lib"
  path_add PATH "$REPLY/bin"
  if [[ "$#" -gt 1 ]]; then
    shift
    while (($#)); do
      case $1 in
        opt/**/bin | usr/local/bin)
          log_status "added addional path prefix $1"
          PATH_add "$REPLY/$1"
          shift
          ;;
        man)
          MANPATH_add "$REPLY/man"
          MANPATH_add "$REPLY/share/man"
          shift
          ;;
        pkg)
          path_add PKG_CONFIG_PATH "$REPLY/lib/pkgconfig"
          shift
          ;;
        *)
          log_status "Unrecognized additional prefix $1. Skipping"
          shift
          ;;
      esac
    done
  fi
}
############## Envs ###################################

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

use_uv() {
  local pyver="${1:-3.11}"
  if ! has uv; then
    log_error"ERROR: uv not installed"
    return 1
  fi
  uv python install "$pyver"
  if [ ! -d .venv ]; then
    uv venv --python "$pyver"
  fi
  PATH_add ".venv/bin"
  export VIRTUAL_ENV="$PWD/.venv"
  if [ ! -f pyproject.toml ]; then
    uv init --bare
  fi
  watch_file pyproject.toml
  watch_file uv.lock
  if [ -f uv.lock ]; then
    uv sync --frozen || uv sync
  else
    uv sync
  fi
}

layout_uv() {
  if [ -f .python-version ]; then
    use uv "$(cat .python-version)"
  elif [ $# -eq 1 ]; then
    use uv "$1"
  else
    use uv
  fi

  export UV_ACTIVE=1 # or VENV_ACTIVE=1
  export UV_PYTHON="$VIRTUAL_ENV/bin/python"
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
