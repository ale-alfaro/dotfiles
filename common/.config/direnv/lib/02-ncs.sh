#!/usr/bin/env bash

use_ncs_toolchain() {

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

  json=$(nrfutil sdk-manager toolchain env --json --skip-overhead --ncs-version "$ncs_version")

  zephyr_sdk_install_dir="$(jq -r '.env_variables[] | select(.key=="ZEPHYR_SDK_INSTALL_DIR") | .value' <<<"$json")"

  mapfile -t path_arr < <(jq -r '.env_variables[] | select(.key=="PATH") | .value | split(":") | .[]' <<<"$json")

  for p in "${path_arr[@]}"; do
    [[ "$p" == "$zephyr_sdk_install_dir"* ]] && PATH_add "$p"
  done

  export ZEPHYR_TOOLCHAIN_VARIANT="zephyr"
  export ZEPHYR_SDK_INSTALL_DIR="${zephyr_sdk_install_dir}"
  # local py_version=""
  # local supported_py_ver='python3.1[0-4]'
  # for py in "${toolchain_path}/usr/local/bin/"$supported_py_ver; do
  #   py_version=${py##*/python}
  # done
  # if [[ ! $py_version =~ ${supported_py_ver##python} ]]; then
  #   log_error "Couldn't derive a valid python version to use $py_version"
  #   return 1
  # fi
}

layout_ncs() {
  # local ncs_version
  env_vars_required ZEPHYR_BASE
  local ncs_version="${1:-3.1.0}"
  ncs_version="${ncs_version#v}"
  use ncs_toolchain "v${ncs_version}"
  west zephyr-export
  zephyr_python_setup "3.13"
}
