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

west := f'{{uvx}} west'

[default]
@_:
    just --list

####################################
# West Manifest and Workspace Recipes
####################################

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

####################################
# Toolchain and SDK related recipes
####################################

arch_toolchains := '-t arm-zephyr-eabi -t x86_64-zephyr-elf'

[arg('type', pattern='ncs|zephyr')]
_toolchain-install type version:
    {{ if type == "zephyr" { west + f' sdk install -b ~/zephyrproject/toolchains {{arch_toolchains}}  --version={{version}}' } else { require('nrfutil') + f' sdk-manager toolchain install --version {{version}}' } }}

[arg('version', pattern='^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-(0|[1-9A-Za-z-][0-9A-Za-z-]*)(?:\.(0|[1-9A-Za-z-][0-9A-Za-z-]*))* marshal)?(?:\+(0|[1-9A-Za-z-][0-9A-Za-z-]*)(?:\.(0|[1-9A-Za-z-][0-9A-Za-z-]*))* marshal)?$')]
ztoolchain-install version: (_toolchain-install 'zephyr' version)

####################################
# Build related recipes
####################################

menuconfig_path := zephyr_base / "scripts" / "kconfig" / "menuconfig.py"
menuconfig := "uv run --script " + uv_with_flags + uv_python_flags + " " + menuconfig_path
zephyr_artifacts := "zephyr.hex,zephyr.bin,zephyr.elf,.config,zephyr.dts"

[no-cd]
_setup_clangd build_dir="build":
    ln -s -f {{ build_dir / file_stem("$APP_DIR") / "compile_commands.json" }} {{ invocation_directory() }}

[no-cd]
_copy_artifacts app_dir artifact:
    mkdir -p {{ app_dir / "out_" + artifact }} && cp {{ app_dir / "build_" + artifact / artifact / "zephyr/{" + zephyr_artifacts }} {{ app_dir / "out_" + artifact }}

[group('build')]
[no-cd]
build app_dir board:
    {{ west }} build --pristine=always -b {{ board }}  -s {{ app_dir }}

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

twister := west + " twister "
twister_report_flags := "--report-dir twister_report --outdir twister_out"
twister_verbose_flags := env('TWISTER_VERBOSITY', '-v')
twister_default_flags := twister_verbose_flags + " -i -W --clobber-output --no-detailed-test-id "

[group('twister')]
[no-cd]
twister_run test_root platform *args:
    @echo "Running twister test suite at {{ invocation_directory() }} and test_root {{ test_root }}"
    {{ twister }} \
    {{ twister_default_flags }} \
    {{ replace(twister_report_flags, "twister", test_root + "/twister") }} \
      -p {{ platform }} \
      -T {{ test_root }} \
      {{ args }}

[group('twister')]
[no-cd]
twister_run_scenario test_root platform scenario *args:
    {{ twister }} \
    {{ twister_default_flags }} \
    {{ replace(twister_report_flags, "twister", test_root + "/twister") }} \
      -p {{ platform }} \
      -T {{ test_root }} \
      -s {{ scenario }} \
      {{ args }}

[group('twister')]
[no-cd]
prep-test test_root board: (twister_run board test_root "--prep-artifacts-for-testing")

# native_sim_west_flags := "-b native_sim -- -DCONFIG_UART_NATIVE_PTY_0_ON_STDINOUT=y"
# qemu_west_flags := "-b qemu_x86 -- -DQEMU_PIPE=qemu-fifo"

hardware_twister_flags := "--west-flash=--skip-rebuild --enable-slow --device-testing "
serial_flags := hardware_twister_flags + "--device-serial=" + env('SERIAL_PORT', '/dev/ttyACM0') + " "

[group('twister')]
[no-cd]
twister_run_hw test_root board *args: (twister_run test_root env('BOARD', board) hardware_twister_flags + args)

[group('twister')]
[no-cd]
twister_run_sim test_root *args: (twister_run test_root "native_sim" args)

[group('twister')]
[no-cd]
twister_run_serial test_root $BOARD *args: (twister_run test_root "$BOARD" quote(serial_flags + args))

pytest_base_opts := " --strict-markers --strict-config -ra "
pytest_debug_opts := " -v -s --log-cli-level='DEBUG' "
pytest_zephyr_opts := " --twister-harness "
pytest_opts := pytest_base_opts + pytest_debug_opts + pytest_zephyr_opts
pytest := uvx + " pytest"

_pytest_run *args:
    {{ pytest }} {{ pytest_base_opts }} {{ args }}

[group('pytest')]
[no-cd]
pytest_run platform build-dir *args:
    {{ pytest }} {{ pytest_opts }} {{ " --rootdir=pytest " + append(file_stem(build-dir), " --build-dir=") + " " + append(platform, " --device-type=") }} {{ args }}

[group('pytest')]
[no-cd]
pytest_run_hw build-dir *args: (pytest_run "hardware" build-dir args)

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

tree_cmd := 'tree --format NYKC --pager'
zephyr_bindings_dir := join(env('ZEPHYR_BASE', ''), "dts", "bindings")
zephyr_extra_bindings_dir := env('ZEPHYR_EXTRA_BINDINGS_DIR', '')
dtsh := uvx + " dtsh"

[group('tools')]
[no-cd]
dtsh build_dir *args:
    {{ dtsh }} {{ args }} {{ if zephyr_extra_bindings_dir != '' { '-b ' + zephyr_bindings_dir + ' -b ' + zephyr_extra_bindings_dir } else { '' } }} {{ join(build_dir, "zephyr", "zephyr.dts") }}

[group('tools')]
[no-cd]
dtsh-cmd build_dir +cmds=tree_cmd: (dtsh build_dir replace("-c 'CMD' ", "CMD", cmds))

[group('tools')]
[no-cd]
dtsh-tree build_dir: (dtsh-cmd build_dir tree_cmd)

find_cmd := 'find --with-dts-ord NUM --format psTd'

[group('tools')]
[no-cd]
dtsh-find build_dir dts-ord_num: (dtsh-cmd build_dir replace(find_cmd, "NUM", dts-ord_num))

mem_dtsh_file := join(source_directory(), "partitions.dtsh")

[group('tools')]
[no-cd]
dtsh-mem build_dir: (dtsh build_dir append(mem_dtsh_file, "-f "))

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
