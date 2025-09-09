#!/usr/bin/env bash

zephyr_workspace_setup() {
    eval "$(west completion zsh)"
    source $ZEPHYR_BASE/zephyr-env.sh
    west zephyr-export
}

use_zephyr_ncs() {
    local ncs_version
    ncs_version="${1:-v3.1.0}"
    eval $(nrfutil sdk-manager toolchain env --as-script --ncs-version $ncs_version)
    export NCS_SDK_ROOT="$HOME/ncs/sdk/$ncs_version"
    export ZEPHYR_BASE="$NCS_SDK_ROOT/zephyr"
    zephyr_workspace_setup
}

use_zephyr_main() {
    local zephyr_version
    zephyr_version="${1:-v0.17.2}"
    export ZEPHYR_TOOLCHAIN_VARIANT=zephyr
    export ZEPHYR_SDK_INSTALL_DIR="$HOME/zephyr-sdk-$zephyr_version"
    export ZEPHYR_PROJECT_ROOT=~/zephyrproject
    . $ZEPHYR_PROJECT_ROOT/.venv/bin/activate

    export PATH="$PATH:$ZEPHYR_SDK_INSTALL_DIR/arm-zephyr-eabi/bin"

    . $ZEPHYR_SDK_INSTALL_DIR/environment-setup-x86_64-pokysdk-linux
    export ZEPHYR_BASE="$ZEPHYR_PROJECT_ROOT/zephyr"
    zephyr_workspace_setup
}
