
# NCS
function ncs_env() {
    local ncs_version=$1
    eval $(nrfutil sdk-manager toolchain env --as-script $ncs_version)
}
