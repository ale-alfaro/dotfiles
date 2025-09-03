
openocd_search_path := "/home/alealfaro/.pico-sdk/openocd/0.12.0+dev/scripts"


# default_target_mcu := env(PICO_TARGET_MCU, "rp2350")
# default_interface := env(PICO_DEBUG_INTERFACE, "jlink")
# default_hex_file := env(PICO_HEX_FILE, "build/zephyr/zephyr.hex")
default_target_mcu := "rp2350"
default_interface := "jlink"
default_hex_file := "build/zephyr/zephyr.hex"
# openocd_program_command :=  "program {{hex_file}} verify reset exit"
openocd_setup_commands := "adapter speed 5000; init; targets; reset init; "

openocd_shutdown_commands := "reset run; shutdown"

flash-rpico target=default_target_mcu interface=default_interface hex_file=default_hex_file:
    @echo "Flashing {{hex_file}} to {{target}} with {{interface}}"
    openocd -s {{openocd_search_path}} -f interface/{{interface}}.cfg -f target/{{target}}.cfg -c '{{openocd_setup_commands}}' -c 'flash write_image erase {{hex_file}}' -c '{{openocd_shutdown_commands}}'

reset-rpico target=default_target_mcu interface=default_interface:
    @echo "Resetting {{target}} with {{interface}}"
    openocd -s {{openocd_search_path}} -f interface/{{interface}}.cfg -f target/{{target}}.cfg -c "init; reset; exit"
