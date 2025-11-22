build_dir := "build"
app_name := "app"
zephyr_artifacts := "zephyr.hex,zephyr.bin,zephyr.elf,.config,zephyr.dts"

default:
    @just --list

[no-cd]
_setup_clangd app_dir:
    ln -s -f {{ app_dir / build_dir / app_name / "compile_commands.json" }} {{ app_dir }}

[no-cd]
_copy_artifacts app_dir artifact:
    mkdir -p {{ app_dir / "out_" + artifact }} && cp {{ app_dir / "build_" + artifact / artifact / "zephyr/{" + zephyr_artifacts }} {{ app_dir / "out_" + artifact }}

[group('lifecycle')]
[no-cd]
build_full app_dir artifact snippet="":
    {{ west }} build --pristine=always -s {{ app_dir }} -d {{ app_dir / "build_" + artifact }}  \
                  {{ if snippet != "" { '--snippet ' + snippet } else { "" } }}

[group('lifecycle')]
[no-cd]
menuconfig dir=build_dir:
    {{ west }} build -t menuconfig -d {{ dir }}

[group('lifecycle')]
[no-cd]
build_spec yaml_toml_spec *args:
    {{ source_dir() / "zephyr_cfg_build.py" }} {{ yaml_toml_spec }} {{ args }}

default_runner := if env('BOARD', "") =~ "^nrf5" { "nrfutil" } else { "jlink" }

# Flash with runner. Supported runners: uf2 (default) or jlink
# [group('zephyr')]
# flash build_dir runner="jlink":
#     @ {{ if runner == "uf2" { "sudo" } else { "" } }} uv run west flash -r {{ runner }} -d {{ build_dir }}

[group('lifecycle')]
[no-cd]
flash build_dir runner=default_runner:
    @echo "flashing with runner {{ runner }}"
    {{ west }} flash -r {{ runner }} -d {{ build_dir }}

[group('debugging')]
[no-cd]
rtt build_dir:
    {{ west }} rtt -r jlink --build-dir {{ build_dir }}
