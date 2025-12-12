openocd_path := env('PICO_OPENOCD_PATH', "$HOME/.pico-sdk/openocd")
openocd_search_path := join(openocd_path, "0.12.0+dev/scripts")
openocd_default_target_mcu := "rp2350"
openocd_default_interface := "jlink"
openocd_setup_commands := "adapter speed 5000; init; targets; reset init; "
openocd_shutdown_commands := "reset run; shutdown"

@_:
    just --list

flash-openocd hex_file target=openocd_default_target_mcu interface=openocd_default_interface:
    @echo "Flashing {{ hex_file }} to {{ target }} with {{ interface }}"
    openocd -s {{ openocd_search_path }} -f interface/{{ interface }}.cfg -f target/{{ target }}.cfg -c '{{ openocd_setup_commands }}' -c 'flash write_image erase {{ hex_file }}' -c '{{ openocd_shutdown_commands }}'

reset-openocd target=openocd_default_target_mcu interface=openocd_default_interface:
    @echo "Resetting {{ target }} with {{ interface }}"
    openocd -s {{ openocd_search_path }} -f interface/{{ interface }}.cfg -f target/{{ target }}.cfg -c "init; reset; exit"

##### OpenOCD Debugging #####

openocd_gdb_port := "3333"
openocd_tcl_port := "6333"
openocd_telnet_port := "4444"

# Start OpenOCD GDB server
debug-server-openocd target=openocd_default_target_mcu interface=openocd_default_interface *extra_opts:
    @echo "Starting OpenOCD GDB server on port {{ openocd_gdb_port }} for target {{ target }} with interface {{ interface }}"
    @openocd \
        -s {{ openocd_search_path }} \
        -f interface/{{ interface }}.cfg \
        -f target/{{ target }}.cfg \
        -c "gdb_port {{ openocd_gdb_port }}" \
        -c "tcl_port {{ openocd_tcl_port }}" \
        -c "telnet_port {{ openocd_telnet_port }}" \
        -c "init" \
        -c "reset halt" \
        {{ extra_opts }}

# Start GDB client and connect to OpenOCD
debug-client-openocd artifact_name port=openocd_gdb_port *extra_opts:
    @just _debug-client-gdb "{{ artifact_name }}" "{{ port }}" "target extended-remote" extra_opts="{{ extra_opts }}"

# Helper to show debug commands
debug-openocd artifact_name target=openocd_default_target_mcu interface=openocd_default_interface:
    @echo "To debug with OpenOCD, run the following commands in two separate terminals:"
    @echo "Terminal 1: just debug-server-openocd --target {{ target }} --interface {{ interface }}"
    @echo "Terminal 2: just debug-client-openocd {{ artifact_name }}"
