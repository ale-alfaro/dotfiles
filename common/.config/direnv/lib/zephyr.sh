#!/usr/bin/env bash

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

zephyr_python_setup() {
  layout uv "${1:-3.12}"
  log_status "Installing west and required python packages for building (pyelftools,ninja,intelhex,etc)"
  env_vars_required ZEPHYR_BASE
  zephyr_scripts_path="$ZEPHYR_BASE/scripts"
  # uv add --requirements "$zephyr_scripts_path/requirements.txt" --dev --marker "sys_platform == 'linux'"
  PATH_add "$ZEPHYR_BASE/scripts"
}
use_ncs() {

  if [[ ! "$#" -eq 1 ]]; then
    log_error "use zephyr requires a version to be specified as an argument"
    return 1
  fi
  local ncs_version
  ncs_version="$1"
  echo "Using NCS version $ncs_version"
  local toolchain_path
  toolchain_path=$(nrfutil sdk-manager toolchain list --json-pretty | jq -r --arg VERSION "$ncs_version" '.data.toolchains[] | select(.ncs_version == $VERSION) | .path')

  if [[ -z "$toolchain_path" ]]; then
    log_error "Toolchain version not found"
    return 1
  elif [[ ! -d "$toolchain_path" ]]; then
    log_error "Toolchain path is not a directory $toolchain_path"
    return 1
  fi
  load_toolchain_prefix "$toolchain_path" "opt/zephyr-sdk/arm-zephyr-eabi/bin"
  export ZEPHYR_TOOLCHAIN_VARIANT="zephyr"
  export ZEPHYR_SDK_INSTALL_DIR="${toolchain_path}/opt/zephyr-sdk"
  local py_version=""
  local supported_py_ver='python3.1[0-4]'
  for py in "${toolchain_path}/usr/local/bin/"$supported_py_ver; do
    py_version=${py##*/python}
  done
  if [[ ! $py_version =~ ${supported_py_ver##python} ]]; then
    log_error "Couldn't derive a valid python version to use $py_version"
    return 1
  fi
  log_status "python version to use $py_version"
  zephyr_python_setup "$py_version"
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

layout_ncs() {
  # local ncs_version
  local ncs_version="${1:-3.1.0}"
  ncs_version="${ncs_version#v}"
  use ncs "v${ncs_version}"
  env_vars_required ZEPHYR_BASE
  if [[ ! -d $ZEPHYR_BASE ]]; then
    log_error "ZEPHYR_BASE=$ZEPHYR_BASE is not a valid directory"
    return 1
  fi
}

layout_zephyr() {
  env_vars_required ZEPHYR_BASE
  local zephyr_version="${1:-0.17.4}"
  zephyr_version="${zephyr_version#v}"
  toolchain_variant="${2:-zephyr}"
  use zephyr_sdk_toolchain "$zephyr_version" "$toolchain_variant"
  zephyr_python_setup "3.13"
  west zephyr-export
  # uvx --with-requirements "$ZEPHYR_BASE/scripts/requirements-base.txt" --python=3.13 west zephyr-export
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
