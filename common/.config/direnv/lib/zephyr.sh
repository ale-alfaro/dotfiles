#!/usr/bin/env bash

fatal() {
  echo '[FATAL]' "$@" >&2
  exit 1
}

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

prefix_path_ncs() {
  local ncs_version
  ncs_version="${1:-v3.1.0}"
  echo "Using NCS version $ncs_version"
  local nrf_env
  NRFUTIL="$(which nrfutil)"
  nrf_env="$($NRFUTIL sdk-manager toolchain env --as-script --ncs-version "$ncs_version")"
  parse_ncs_env "$nrf_env"

  local paths_to_add
  ##export PATH=/opt/nordic/ncs/toolchains/5c0d382932/bin:
  ##/opt/nordic/ncs/toolchains/5c0d382932/usr/bin:
  #/opt/nordic/ncs/toolchains/5c0d382932/usr/local/bin:
  #/opt/nordic/ncs/toolchains/5c0d382932/opt/bin:
  #/opt/nordic/ncs/toolchains/5c0d382932/opt/nanopb/generator-bin:
  #/opt/nordic/ncs/toolchains/5c0d382932/nrfutil/bin:
  #/opt/nordic/ncs/toolchains/5c0d382932/opt/zephyr-sdk/arm-zephyr-eabi/bin:
  #/opt/nordic/ncs/toolchains/5c0d382932/opt/zephyr-sdk/riscv64-zephyr-elf/bin
  IFS=':' read -r -a paths_to_add <<<"${ncs_path_vars[PATH]}"
  for ((i = ${#paths_to_add[@]} - 1; i >= 0; i--)); do
    path_add PATH "${paths_to_add[i]}"
  done
}

use_ncs() {

  if [[ ! "$#" -eq 1 ]]; then
    fatal "use zephyr requires a version to be specified as an argument"
  fi
  local ncs_version
  ncs_version="$1"
  echo "Using NCS version $ncs_version"
  local nrf_env
  NRFUTIL="$(which nrfutil)"
  nrf_env="$($NRFUTIL sdk-manager toolchain env --as-script --ncs-version "$ncs_version")"
  parse_ncs_env "$nrf_env"

  export NRFUTIL_HOME="${ncs_vars[NRFUTIL_HOME]}"
  export ZEPHYR_TOOLCHAIN_VARIANT="${ncs_vars[ZEPHYR_TOOLCHAIN_VARIANT]}"
  export ZEPHYR_SDK_INSTALL_DIR="${ncs_vars[ZEPHYR_SDK_INSTALL_DIR]}"
  export NCS_SDK_HOME="${2:-$HOME/ncs}"
  if [[ ! -d "$NCS_SDK_HOME" ]]; then fatal "NCS_SDK_HOME ENV VAR MUST BE SET"; fi
  export NCS_SDK_ROOT="$NCS_SDK_HOME/sdk/$ncs_version"
  export ZEPHYR_BASE="$NCS_SDK_ROOT/zephyr"
}

use_zephyr_toolchain() {
  if [[ ! "$#" -eq 1 ]]; then
    fatal "use zephyr requires a version to be specified as an argument"
  fi
  local zephyr_version
  zephyr_version="$1"
  # zephyr_repo_path="${2:-~/zephyrproject}"

  echo "Using Zephyr version $zephyr_version"
  export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
  export ZEPHYR_TOOLCHAIN_ROOT="${2:-$HOME/zephyrproject/toolchains}"
  toolchain_dir="$ZEPHYR_TOOLCHAIN_ROOT/zephyr-sdk-$zephyr_version"
  echo "Toolchain dir $toolchain_dir"
  if [[ ! -e "$toolchain_dir" ]]; then
    echo "Zephyr SDK toolchain is not installed! Please run install_zephyr_sdk_toolchain <VERSION> first!"
    return
  fi
  export ZEPHYR_SDK_INSTALL_DIR=$toolchain_dir
  PATH_add "$ZEPHYR_SDK_INSTALL_DIR/arm-zephyr-eabi/bin"
}

zephyr_pip_install() {
  uv add --dev west pyelftools ninja intelhex
  zephyr_base_config=$(uv run --dev west config zephyr.base)
  zephyr_base=${ZEPHYR_BASE:-$zephyr_base_config}
  if [[ -d "$zephyr_base" ]]; then
    "$(uv run --dev west packages pip | xargs uv add --dev)" &>/dev/null || eval "$(uv add --requirements "$zephyr_base/scripts/requirements.txt" --dev)"

  else
    log_status "Not inside a workspace. Are you out-of-tree?"
  fi
}

layout_uv_zephyr() {
  # if [[ ! "$#" -eq 1 ]]; then
  #   fatal "layout_uv_zephyr requires python version to be specified"
  # fi
  layout uv "${1:-3.12}"

  echo "Installing west and required python packages for building (pyelftools ninja intelhex)"
  zephyr_pip_install
}
#Main Functions to use for setting up an environment:

layout_ncs() {
  local ncs_version
  ncs_version="${1:-v3.1.0}"
  use ncs "$ncs_version"
}

layout_zephyr() {
  local zephyr_version
  zephyr_version="${1:-0.17.2}"
  use zephyr_toolchain "$zephyr_version"
}

use_out_of_tree_west_workspace() {
  if [[ -z "$ZEPHYR_BASE" ]]; then
    fatal "ZEPHYR_BASE must be set to use an out of tree west workspace"
  fi
  if has west; then
    west config zephyr.base "$ZEPHYR_BASE"
    source "${ZEPHYR_BASE}/zephyr-env.sh"
    west zephyr-export
  else
    fatal "Need west to be installed in the uv environement"
  fi

}

use_west_workspace() {
  if [[ ! "$#" -eq 1 || ! -z "$ZEPHYR_BASE" ]]; then
    fatal "use west workspace requires the location of ZEPHYR_BASE to be specified as an argument or environment variable"
  fi
  if ! has west; then
    layout uv_zephyr
  fi
  west config zephyr.base "${1:-$ZEPHYR_BASE}"
  if [[ -z $ZEPHYR_BASE ]]; then
    export ZEPHYR_BASE="$(west topdir)/$1"
  else
    west zephyr-export
  fi
}
