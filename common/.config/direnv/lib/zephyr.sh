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

layout_ncs_full() {
  local ncs_version
  ncs_version="${1:-v3.1.0}"
  echo "Using NCS version $ncs_version"
  local nrf_env
  nrf_env="$($NRFUTIL sdk-manager toolchain env --as-script --ncs-version "$ncs_version")"
  parse_ncs_env "$nrf_env"

  # --- Apply Fundamental Environment Variables FIRST ---
  local paths_to_add
  IFS=':' read -r -a paths_to_add <<<"${ncs_path_vars[PATH]}"
  for ((i = ${#paths_to_add[@]} - 1; i >= 0; i--)); do
    path_add PATH "${paths_to_add[i]}"
  done
  export NRFUTIL_HOME="${ncs_vars[NRFUTIL_HOME]}"
  export ZEPHYR_TOOLCHAIN_VARIANT="${ncs_vars[ZEPHYR_TOOLCHAIN_VARIANT]}"
  export ZEPHYR_SDK_INSTALL_DIR="${ncs_vars[ZEPHYR_SDK_INSTALL_DIR]}"

  export NCS_SDK_ROOT="$HOME/ncs/sdk/$ncs_version"
  export ZEPHYR_BASE="$NCS_SDK_ROOT/zephyr"

  # --- Apply Optional Environment Variables for full NCS setup ---
  local ld_paths_to_add
  IFS=':' read -r -a ld_paths_to_add <<<"${ncs_path_vars[LD_LIBRARY_PATH]}"
  for ((i = ${#ld_paths_to_add[@]} - 1; i >= 0; i--)); do
    path_add LD_LIBRARY_PATH "${ld_paths_to_add[i]}"
  done
  export GIT_EXEC_PATH="${ncs_vars[GIT_EXEC_PATH]}"
  export GIT_TEMPLATE_DIR="${ncs_vars[GIT_TEMPLATE_DIR]}"
  export PYTHON_HOME="${ncs_vars[PYTHONHOME]}"
  export PYTHON_PATH="${ncs_vars[PYTHONPATH]}"
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
  export NRFUTIL_HOME="${ncs_vars[NRFUTIL_HOME]}"
  export ZEPHYR_TOOLCHAIN_VARIANT="${ncs_vars[ZEPHYR_TOOLCHAIN_VARIANT]}"
  export ZEPHYR_SDK_INSTALL_DIR="${ncs_vars[ZEPHYR_SDK_INSTALL_DIR]}"

  export NCS_SDK_ROOT="$HOME/ncs/sdk/$ncs_version"
  export ZEPHYR_BASE="$NCS_SDK_ROOT/zephyr"
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
