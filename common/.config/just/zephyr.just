# set shell := ["zsh", "-uc"]
# set unstable := true
# set allow-duplicate-recipes := true
# set allow-duplicate-variables := true

zephyr_base := env('ZEPHYR_BASE', "")
zephyr_scripts := zephyr_base / "scripts"
requirements_txt := zephyr_scripts / "requirements-base.txt"
uv_with_flags := "--with-requirements " + requirements_txt
uv_python_flags := " --python=3.13"
west := "uvx " + uv_with_flags + " west"

# has_nrfutil := shell('type "$1" &>/dev/null', "nrfutil")

import 'zephyr/test.just'
import 'zephyr/build.just'
import 'zephyr/dts.just'

@_:
    just --list

# initialize west
[group('manifest')]
[no-cd]
init west_yaml:
    {{ west }} init -l {{ west_yaml }}
    {{ west }} update --fetch-opt=--filter=blob:none
    {{ west }} zephyr-export

# update west
[group('manifest')]
[no-cd]
update:
    {{ west }} update --fetch-opt=--filter=blob:none

[group('install')]
install-nrfutil install_prefix="/usr/local/bin":
    curl https://files.nordicsemi.com/artifactory/swtools/external/nrfutil/executables/x86_64-unknown-linux-gnu/nrfutil -o nrfutil
    chmod +x nrfutil 
    mv nrfutil {{ install_prefix }}

# [group('install')]
# setup-nrfutil:
#     {{ if which('nrfutil') == '' { `just install-nrfutil` } else { which('nrfutil') } }}
#     {{ which('nrfutil') }} install completion device nrf5sdk-tools toolchain-manager sdk-manager

zephyr-mod-script := zephyr_scripts / "zephyr_module.py"

[group('install')]
inspect-zephyr-modules:
    {{ zephyr-mod-script }} --cmake-out mod.cmake
    {{ zephyr-mod-script }} --kconfig-out mod.kconfig

[group('debugging')]
[no-cd]
west-boards *filter:
    @echo "Getting all boards available"
    {{ west }} boards -f "{name}#_#_#{dir}#_#_{qualifiers}" | awk -v cwd="$(pwd)/" -F '#_#_#' 'BEGIN {print "| Board | Path | Qualifiers |"; print "|---|---|---|" } {{ filter }} { sub(cwd, "", $2); gsub(/^[ \t]+|[ \t]+$/, "", $1); gsub(/^[ \t]+|[ \t]+$/, "", $2); gsub(/^[ \t]+|[ \t]+$/, "", $3); print "| " $1 " | " $2 " | " $3 " |"}'

[group('zephyr')]
[no-cd]
west-boards-filter-by-path path="app":
    just west-boards '$2 ~ /\/{{ path }}\// '
