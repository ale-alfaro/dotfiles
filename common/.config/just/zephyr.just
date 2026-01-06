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
    just --list --color=always --justfile {{ source_dir() / 'submods' / "zephyr" / "twister.just" }}

zephyr_just := f'{{source_file()}}/zephyr'

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
# Configuration through west recipes
# ###################################

# mod conf x'${JUST_HOME}/zephyr/westconfig.just'
mod conf 'submods/zephyr/westconfig.just'

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
build dir=invocation_dir() *args:
    {{ if `west config alias.bd 2>/dev/null` != '' { f'west bd {{args}}' } else { f'west build -s {{dir}}}' } }}

[group('build')]
[no-cd]
build_clean dir=join(invocation_dir(), 'build') *args: && (build args)
    {{ if dir && path_exists(dir) == 'true' { f'rm -r {{dir}}' } else { error(f"Build dir {{dir}} doesn't exist") } }}

[group('tools')]
[no-cd]
config dir=join(invocation_dir(), 'build'): (conf::set 'target=menuconfig')
    {{ if `west config alias.tgt 2>/dev/null` != '' { f'west tgt menuconfig' } else { f'{{west}} build -d {{dir}} -t menuconfig' } }}

zephyr-mod-script := zephyr_scripts / "zephyr_module.py"

[group('build')]
[group('tools')]
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

mod twister 'submods/zephyr/twister.just'

####################################
# Devicetree (dts,dtsi)
# ###################################

mod dtsh 'submods/zephyr/dtsh.just'

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
