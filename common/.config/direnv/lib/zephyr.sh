#!/usr/bin/env bash

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
    log_error "use zephyr requires a version to be specified as an argument"
    return 1
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
}

#TODO: Finish and make compatible with new toolchain dir structures
zephyr_toolchain_path_add() {

  env_vars_required ZEPHYR_BASE ZEPHYR_TOOLCHAIN_DIR ZEPHYR_TOOLCHAIN_VARIANT
  if [[ ! -d "$ZEPHYR_TOOLCHAIN_DIR" ]]; then
    log_error "Zephyr SDK toolchain is not found"
    return 1
  fi
  if [[ "$ZEPHYR_TOOLCHAIN_VARIANT" == "zephyr" ]]; then
    if [[ -d "${ZEPHYR_TOOLCHAIN_DIR}/gnu" ]]; then
      ZEPHYR_TOOLCHAIN_DIR="${ZEPHYR_TOOLCHAIN_DIR}/gnu"
    fi
    PATH_add "${ZEPHYR_TOOLCHAIN_DIR}/arm-zephyr-eabi/bin"
    PATH_add "${ZEPHYR_TOOLCHAIN_DIR}/x86_64-zephyr-elf/bin"
  elif [[ "$ZEPHYR_TOOLCHAIN_VARIANT" == "llvm" ]]; then
    found_version=$(semver_search "/opt/ATfE" "ATfE-" "21")
    export LLVM_TOOLCHAIN_PATH="/opt/ATfE/ATfE-${found_version}"
    PATH_add "${LLVM_TOOLCHAIN_PATH}/bin"
  else
    log_error "Invalid toolchain variant"
    return 1
  fi

  export ZEPHYR_SCRIPTS_DIR="${ZEPHYR_BASE:-$HOME/zephyrproject/zephyr}/scripts"
  PATH_add "$zephyr_scripts_path"
}

use_zephyr_sdk_toolchain() {

  if [[ ! "$#" -eq 2 ]]; then
    log_error "use zephyr requires a version and toolchain variant (zephyr, llvm, gnu)to be specified as an argument"
    return 1
  fi

  if [[ ! "$2" =~ zephyr|llvm ]]; then
    log_error "use zephyr toolchain variant must be one of the following (llvm, gnu)to be specified as an argument"
    return 1
  fi

  local version="$1"
  export ZEPHYR_SDK_INSTALL_DIR="${ZEPHYR_SDK_INSTALL_DIR:-$HOME/zephyrproject/toolchains}"
  local found_version
  found_version=$(semver_search "${ZEPHYR_SDK_INSTALL_DIR}" "zephyr-sdk-" "${version}")
  export ZEPHYR_TOOLCHAIN_DIR="${ZEPHYR_SDK_INSTALL_DIR}/zephyr-sdk-${found_version}"
  export ZEPHYR_TOOLCHAIN_VARIANT="$2"

  echo "Using Zephyr version $zephyr_version, looking for the ${ZEPHYR_TOOLCHAIN_VARIANT} in ${ZEPHYR_SDK_INSTALL_DIR}"
}

zephyr_pip_install() {
  # uv add west pyelftools ninja intelhex
  zephyr_scripts_path=${1:-"$ZEPHYR_BASE/scripts"}
  if [[ ! -d "$zephyr_scripts_path" ]]; then
    "$(uv run --dev west packages pip | xargs uv add --dev)" &>/dev/null || log_error "Couldn't get pip packages to install through  'west packages pip'"
  else
    uv add --requirements "$zephyr_scripts_path/requirements.txt" --dev
  fi
}

layout_python_zephyr() {
  layout uv "${1:-3.12}"
  log_status "Installing west and required python packages for building (pyelftools,ninja,intelhex,etc)"
  zephyr_pip_install
}
#Main Functions to use for setting up an environment:

layout_ncs() {
  local ncs_version
  ncs_version="${1:-v3.1.0}"
  use ncs "$ncs_version"
  env_vars_required ZEPHYR_BASE
  if [[ ! -d $ZEPHYR_BASE ]]; then
    log_error "ZEPHYR_BASE=$ZEPHYR_BASE is not a valid directory"
    return 1
  fi
  PATH_add "$ZEPHYR_BASE/scripts"
}

layout_zephyr() {
  local zephyr_version="${1:-0.17.4}"
  zephyr_version="${zephyr_version#v}"
  toolchain_variant="${2:-zephyr}"
  use zephyr_sdk_toolchain "$zephyr_version" "$toolchain_variant"
  zephyr_toolchain_path_add
}
