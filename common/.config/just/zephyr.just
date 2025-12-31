set shell := ["zsh", "-uc"]
set unstable := true

# set allow-duplicate-recipes := true

set allow-duplicate-variables := true

zephyr_base := env('ZEPHYR_BASE', "")
zephyr_scripts := zephyr_base / "scripts"
requirements_txt := zephyr_scripts / "requirements-base.txt"
uv_with_flags := "--with-requirements " + requirements_txt
uv_python_flags := " --python=3.13 "
uvx := "uvx " + uv_with_flags + uv_python_flags

# west := uvx + " west"

west := if which('west') != '' { require('west') } else { f'{{uvx}} west' }

[default]
@list:
    just --list --color=always --justfile {{ source_file() }}
    just --list --color=always --justfile {{ source_dir() / "zephyr" / "twister.just" }}

zephyr_just := x'${JUST_HOME}/zephyr'

####################################
# West Manifest and Workspace Recipes
####################################

# initialize west
[group('workspace')]
[no-cd]
init west_yaml:
    {{ west }} init -l {{ west_yaml }}
    {{ west }} update --fetch-opt=--filter=blob:none
    {{ west }} zephyr-export

[group('workspace')]
[no-cd]
setup:
    cp {{ f'{{zephyr_just}}/Justfile.template' }} {{ invocation_directory() / 'Justfile' }}
    echo ''' \
        WEST_TOPDIR="{{ `west topdir` }}" \
        ZEPHYR_BASE="{{ env('ZEPHYR_BASE') }}" \
        APP_NAME="app" \
        #DEFAULT_BOARD="" \
    ''' >> {{ invocation_directory() / '.env' }}
    just -g agents::ln_file zephyr {{ invocation_directory() / "AGENTS.md" }}

# update west
[group('workspace')]
[no-cd]
update:
    {{ west }} update --fetch-opt=--filter=blob:none

####################################
# Toolchain and SDK related recipes
####################################

arch_toolchains := '-t arm-zephyr-eabi -t x86_64-zephyr-elf'

[arg('version', pattern='^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-(0|[1-9A-Za-z-][0-9A-Za-z-]*)(?:\.(0|[1-9A-Za-z-][0-9A-Za-z-]*))* marshal)?(?:\+(0|[1-9A-Za-z-][0-9A-Za-z-]*)(?:\.(0|[1-9A-Za-z-][0-9A-Za-z-]*))* marshal)?$')]
toolchain-install version:
    {{ west + f' sdk install -b ~/zephyrproject/toolchains {{arch_toolchains}}  --version={{version}}' }}

####################################
# Build related recipes
####################################

menuconfig_path := zephyr_base / "scripts" / "kconfig" / "menuconfig.py"
menuconfig := "uv run --script " + uv_with_flags + uv_python_flags + " " + menuconfig_path
zephyr_artifacts := "zephyr.hex,zephyr.bin,zephyr.elf,.config,zephyr.dts"

[group('build')]
[no-cd]
build app_dir=invocation_directory() board=env('BOARD', ''):
    {{ west }} build --pristine=always -b {{ board }}  -s {{ app_dir }}
    ln -sf {{ shell('fd "$1" "$2"', 'compile_commands.json', f'{{app_dir}}/build/{{board}}') }} {{ env('WEST_TOPDIR', f'{{app_dir}}') / "compile_commands.json" }}

[group('build')]
[no-cd]
build_full app_dir artifact snippet="":
    {{ west }} build --pristine=always -s {{ app_dir }} -d {{ app_dir / "build_" + artifact }}  \
                  {{ if snippet != "" { '--snippet ' + snippet } else { "" } }}

[group('build')]
[no-cd]
menuconfig $DOTCONF:
    {{ menuconfig }}

zephyr-mod-script := zephyr_scripts / "zephyr_module.py"

[group('build')]
inspect-zephyr-modules:
    {{ zephyr-mod-script }} --cmake-out mod.cmake
    {{ zephyr-mod-script }} --kconfig-out mod.kconfig

####################################
# Flash, Debug and Other related recipes
####################################

default_runner := if env('BOARD', "") =~ "^nrf5" { "nrfutil" } else { "jlink" }

[group('flash')]
[no-cd]
flash build_dir runner=default_runner:
    @echo "flashing with runner {{ runner }}"
    {{ west }} flash -r {{ runner }} -d {{ build_dir }}

[group('debug')]
[no-cd]
rtt build_dir:
    {{ west }} rtt -r jlink --build-dir {{ build_dir }}

####################################
# Twister, Pytest and Testing Recipes
####################################

# import? x'${JUST_HOME}/zephyr/twister.just'
mod twister x'${JUST_HOME}/zephyr/twister.just'

####################################
# Devicetree (dts,dtsi)
# ###################################
# Add custom bindings directory to dtsh
# custom_bindings_dir := join(app_dir, 'dts', 'bindings')
# shell-like interface with Devicetree
#
# user files:
#   -u, --user-files    initialize per-user configuration files and exit
#   --preferences FILE  load additional preferences file
#   --theme FILE        load additional styles file
#
# session control:
#   -c CMD              execute CMD at startup (may be repeated)
#   -f FILE             execute batch commands from FILE at startup
#   -i, --interactive   enter interactive loop after batch command
#
#   * - a - unit address
#   * - A - node aliases
#   * - b - bus of appearance
#   * - B -supported bus protocols
#   * - c - compatible strings
#   * - C
# binding's compatible or headline
#   * - d
# binding's description
#   * - D
# node dependencies
#   * - i
# generated interrupts
#   * - K
# all labels and aliases
#   * - l
# device label
#   * - L
# DTS labels
#   * - N
# node name
#   * - n
# unit name
#   * - o
# dependency ordinal (aka ``dts_ord``)
#   * - p
# path name
#   * - r
# registers (base address and size)
#   * - R
# registers (address range)
#   * - s
# status string
#   * - T
# dependent nodes
#   * - v
# vendor name
#   * - X
# child-binding depth
#   * - Y
# bus information

zephyr_bindings_dir := join(zephyr_base, "dts", "bindings")
zephyr_extra_bindings_dir := env('ZEPHYR_EXTRA_BINDINGS_DIR', '')
dts_bindings_flags := if zephyr_extra_bindings_dir != '' { '-b ' + zephyr_bindings_dir + ' -b ' + zephyr_extra_bindings_dir } else { '' }
dtsh_dir := x'${JUST_HOME}/zephyr/dtsh'
dtsh_pref := dtsh_dir / "dtsh.ini"
dtsh := if which("dtsh") == '' { 'dtsh is not in the PATH. Please install it' } else { require('dtsh') }

[no-cd]
_dtsh-cmd build_dir +cmds:
    {{ if path_exists(dtsh) != 'true' { error(dtsh) } else { '' } }}
    {{ dtsh }} -c '{{ cmds }}' {{ join(build_dir, "zephyr", "zephyr.dts") }}

[group('tools')]
[no-cd]
dtsh-sh build_dir *args:
    {{ if path_exists(dtsh) != 'true' { error(dtsh) } else { '' } }}
    {{ dtsh }} {{ args }} {{ join(build_dir, "zephyr", "zephyr.dts") }}

# Print tree with NYKC (Node name, bus info, labels/aliases, bindings compat str)
[group('tools')]
dtsh-tree build_dir: (_dtsh-cmd build_dir "tree --format NYKC --pager")

# Print tree with NYKC (Node name, bus info, labels/aliases, bindings compat str)
[group('tools')]
dtsh-cat node build_dir: (_dtsh-cmd build_dir f"cat &{{node}} --format Bd --pager")

[group('tools')]
dtsh-ls build_dir: (_dtsh-cmd build_dir "ls -l NYKC")

[group('tools')]
dtsh-find build_dir dts-ord_num: (_dtsh-cmd build_dir f'find --with-dts-ord {{dts-ord_num}} --format psTd')

[group('tools')]
dtsh-mem build_dir: (_dtsh-cmd build_dir f' -f {{dtsh_dir}}/partitions.dtsh')

####################################
# Misc

# ###################################
[group('misc')]
[no-cd]
west-boards *filter:
    @echo "Getting all boards available"
    {{ west }} boards -f "{name}#_#_#{dir}#_#_{qualifiers}" | awk -v cwd="$(pwd)/" -F '#_#_#' 'BEGIN {print "| Board | Path | Qualifiers |"; print "|---|---|---|" } {{ filter }} { sub(cwd, "", $2); gsub(/^[ \t]+|[ \t]+$/, "", $1); gsub(/^[ \t]+|[ \t]+$/, "", $2); gsub(/^[ \t]+|[ \t]+$/, "", $3); print "| " $1 " | " $2 " | " $3 " |"}'

[group('misc')]
[no-cd]
west-boards-filter-by-path path="app":
    just west-boards '$2 ~ /\/{{ path }}\// '
