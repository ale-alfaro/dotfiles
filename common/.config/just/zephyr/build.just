
# zephyr_base := env('ZEPHYR_BASE')
menuconfig_path := zephyr_base / "scripts" / "kconfig" / "menuconfig.py"
menuconfig := "uv run --script " + uv_with_flags + uv_python_flags + " " + menuconfig_path
app_name := "app"
zephyr_artifacts := "zephyr.hex,zephyr.bin,zephyr.elf,.config,zephyr.dts"

[no-cd]
_setup_clangd app_dir build_dir="build":
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
menuconfig $DOTCONF:
  {{ menuconfig }}

# {{ west }} build -b {{ board }} -t menuconfig  -s {{ app_dir }} -d {{  app_dir / build_dir }}

default_runner := if env('BOARD', "") =~ "^nrf5" { "nrfutil" } else { "jlink" }

[group('lifecycle')]
[no-cd]
flash build_dir runner=default_runner:
    @echo "flashing with runner {{ runner }}"
    {{ west }} flash -r {{ runner }} -d {{ build_dir }}

[group('debugging')]
[no-cd]
rtt build_dir:
    {{ west }} rtt -r jlink --build-dir {{ build_dir }}
