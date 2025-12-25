#!/usr/bin/env bash

zephyr_python_setup() {
  py_ver="${1:-3.12}"
  layout uv "$py_ver"
  uv add -r "$ZEPHYR_BASE/scripts/requirements-base.txt" --python="$py_ver"
  env_vars_required ZEPHYR_BASE
  zephyr_scripts_path="$ZEPHYR_BASE/scripts"
  PATH_add "$ZEPHYR_BASE/scripts"
}

#TODO: Finish and make compatible with new toolchain dir structures
zephyr_toolchain_path_add() {

  env_vars_required ZEPHYR_BASE ZEPHYR_SDK_INSTALL_DIR ZEPHYR_SDK_VERSION ZEPHYR_TOOLCHAIN_VARIANT
  if [[ ! -d "$ZEPHYR_SDK_INSTALL_DIR" ]]; then
    log_error "Zephyr SDK toolchain is not found"
    return 1
  fi
  if [[ "$ZEPHYR_TOOLCHAIN_VARIANT" == "zephyr" ]]; then
    local prefix="$ZEPHYR_SDK_INSTALL_DIR"
    if [[ -d "${ZEPHYR_SDK_INSTALL_DIR}/gnu" ]]; then
      prefix="${ZEPHYR_SDK_INSTALL_DIR}/gnu"
    fi
    PATH_add "${prefix}/arm-zephyr-eabi/bin"
    PATH_add "${prefix}/x86_64-zephyr-elf/bin"
  elif [[ "$ZEPHYR_TOOLCHAIN_VARIANT" == "llvm" ]]; then
    found_version=$(semver_search "/opt/ATfE" "ATfE-" "21")
    export LLVM_TOOLCHAIN_PATH="/opt/ATfE/ATfE-${found_version}"
    PATH_add "${LLVM_TOOLCHAIN_PATH}/bin"
    unset ZEPHYR_SDK_INSTALL_DIR
  elif [[ "$ZEPHYR_TOOLCHAIN_VARIANT" == "host" ]]; then
    log_status "Using host toolchain variant. Remember to change it to zephyr when building for remote targets"
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

  if [[ ! "$2" =~ host|zephyr|llvm ]]; then
    log_error "use zephyr toolchain variant must be one of the following (llvm, gnu)to be specified as an argument"
    return 1
  fi

  local version="$1"
  ZEPHYR_SDK_BASE_INSTALL_DIR="${ZEPHYR_SDK_INSTALL_DIR:-$HOME/zephyrproject/toolchains}"
  ZEPHYR_SDK_VERSION="$(semver_search "${ZEPHYR_SDK_BASE_INSTALL_DIR}" "zephyr-sdk-" "${version}")"
  ZEPHYR_SDK_INSTALL_DIR="${ZEPHYR_SDK_BASE_INSTALL_DIR}/zephyr-sdk-${ZEPHYR_SDK_VERSION}"
  export ZEPHYR_SDK_VERSION
  export ZEPHYR_SDK_INSTALL_DIR
  export ZEPHYR_TOOLCHAIN_VARIANT="$2"

  echo "Using Zephyr version $zephyr_version, looking for the ${ZEPHYR_TOOLCHAIN_VARIANT} in ${ZEPHYR_SDK_INSTALL_DIR}"
  zephyr_toolchain_path_add
}

layout_zephyr() {
  env_vars_required ZEPHYR_BASE
  local zephyr_version="${1:-0.17.4}"
  zephyr_version="${zephyr_version#v}"
  toolchain_variant="${2:-zephyr}"
  use zephyr_sdk_toolchain "$zephyr_version" "$toolchain_variant"
  west zephyr-export
  zephyr_python_setup "3.13"
}

layout_pigweed() {
  # if [ -z "$PW_ENVIRONMENT_ROOT" ]; then
  #   log_error "Please specify the PW_ENVIRONMENT_ROOT"
  #   return 1
  # fi
  #
  # # Determine project-level root directory.
  # if [ -n "$PW_PROJECT_ROOT" ]; then
  #   _PW_ENV_PREFIX="$PW_PROJECT_ROOT"
  # elif [ -n "$PW_ROOT" ]; then
  #   _PW_ENV_PREFIX="$PW_ROOT"
  # else
  #   log_error "Please specify the PW_PROJECT_ROOT or PW_ROOT"
  #   return 1
  # fi
  # dotenv_if_exists "${HOME}/pigweed/envs/.env"
  export LLVM_TOOLCHAIN_PATH="${HOME}/pigweed/toolchains/clang-latest"

  if [[ ! -d "$LLVM_TOOLCHAIN_PATH" ]]; then
    log_error "$LLVM_TOOLCHAIN_PATH not a directory"
    return 1
  fi
  load_toolchain_prefix "$LLVM_TOOLCHAIN_PATH"
  export ZEPHYR_TOOLCHAIN_VARIANT="llvm"

}
