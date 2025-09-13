#!/usr/bin/env bash

NRFUTIL="/usr/local/bin/nrfutil"

# @description Parses the output of the nrfutil toolchain env command
# @arg $1 string The output of the nrfutil command
# @glocal ncs_vars Associative array containing the parsed variables
# @glocal ncs_path_vars Associative array containing the parsed path-like variables
parse_ncs_env() {
  local nrf_env_output="$1"
  declare -gA ncs_vars
  declare -gA ncs_path_vars
  ncs_vars=()
  ncs_path_vars=()
  while IFS= read -r line; do
    # Strip potential trailing carriage returns
    line=${line%$'\r'}
    if [[ -z "$line" || $line != export* ]]; then
      continue
    fi
    line=${line#export }
    key=${line%%=*}
    value=${line#*=}
    if [[ "$value" == *":\$$key"* ]]; then
      value=${value%:"\$$key"}
      ncs_path_vars[$key]="$value"
    else
      ncs_vars[$key]="$value"
    fi
  done <<<"$nrf_env_output"
}

ncs_venv_setup() {
  if [ ! $# -eq 2 ]; then
    echo "Expects two arguments, the python interpreter and the requirements file"
    return 1
  fi
  if [[ -d ".venv" ]]; then
    VIRTUAL_ENV="$(pwd)/.venv"
  fi
  if [[ -z $VIRTUAL_ENV || ! -d $VIRTUAL_ENV ]]; then
    uv venv --python "$1"
    VIRTUAL_ENV="$(pwd)/.venv"
  fi
  PATH_add "$VIRTUAL_ENV/bin"
  export UV_ACTIVE=1 # or VENV_ACTIVE=1
  export VIRTUAL_ENV
  pip -qq install -r "$2/pip-packages/requirements.txt"
}

layout_ncs() {
  local ncs_version
  ncs_version="${1:-v3.1.0}"
  echo "Using NCS version $ncs_version"
  local nrf_env
  nrf_env="$($NRFUTIL sdk-manager toolchain env --as-script --ncs-version "$ncs_version")"
  parse_ncs_env "$nrf_env"

  # --- Apply Environment Variables FIRST ---
  local paths_to_add
  IFS=':' read -r -a paths_to_add <<<"${ncs_path_vars[PATH]}"
  for ((i = ${#paths_to_add[@]} - 1; i >= 0; i--)); do
    path_add PATH "${paths_to_add[i]}"
  done
  # local ld_paths_to_add
  # IFS=':' read -r -a ld_paths_to_add <<<"${ncs_path_vars[LD_LIBRARY_PATH]}"
  # for ((i = ${#ld_paths_to_add[@]} - 1; i >= 0; i--)); do
  #     path_add LD_LIBRARY_PATH "${ld_paths_to_add[i]}"
  # done
  # export GIT_EXEC_PATH="${ncs_vars[GIT_EXEC_PATH]}"
  # export GIT_TEMPLATE_DIR="${ncs_vars[GIT_TEMPLATE_DIR]}"
  export NRFUTIL_HOME="${ncs_vars[NRFUTIL_HOME]}"
  export ZEPHYR_TOOLCHAIN_VARIANT="${ncs_vars[ZEPHYR_TOOLCHAIN_VARIANT]}"
  export ZEPHYR_SDK_INSTALL_DIR="${ncs_vars[ZEPHYR_SDK_INSTALL_DIR]}"

  # --- Now, Use the Tools ---
  export NCS_SDK_ROOT="$HOME/ncs/sdk/$ncs_version"
  direnv_dir="$NCS_SDK_ROOT/.direnv"
  local python_home="${ncs_vars[PYTHONHOME]}"
  local python_exe=""
  if [[ -n "$python_home" ]]; then
    python_exe="$python_home/bin/python"
  fi
  ncs_venv_setup "$python_exe" "$direnv_dir"
}

use_zephyr_main() {
  local zephyr_version
  zephyr_version="${1:-v0.17.2}"
  export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
  export ZEPHYR_SDK_INSTALL_DIR="$HOME/zephyr-sdk-$zephyr_version"
  export ZEPHYR_PROJECT_ROOT=~/zephyrproject
  layout uv

  export PATH="$PATH:$ZEPHYR_SDK_INSTALL_DIR/arm-zephyr-eabi/bin"

  . "$ZEPHYR_SDK_INSTALL_DIR/environment-setup-x86_64-pokysdk-linux"
  export ZEPHYR_BASE="$ZEPHYR_PROJECT_ROOT/zephyr"
}

