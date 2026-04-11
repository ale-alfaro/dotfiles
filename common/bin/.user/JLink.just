set unstable := true

@_:
    just --list --justfile {{ source_file() }}

##### J-Link Documentation #####

obsidian_home := env('OBSIDIAN_HOME')
jlink_commander_docs := "https://kb.segger.com/J-Link_Commander"
jlink_manual := "/opt/SEGGER/JLink/Doc/Manuals/UM08001_JLink.pdf"

# Show J-Link command documentation
jlink-show-commands:
    @fd "JLinkCommander" {{ obsidian_home }} -X bat 

jlink-docs:
    @open {{ jlink_manual }}

jlink-commander-docs:
    @open {{ jlink_commander_docs }}

##### JLink Common #####

[private]
_jlink-run-probe := 'JLinkExe \
        -CommanderScript "$1" \
        -nogui 1 \
        -ExitOnError 1'
[private]
_jlink-run := 'JLinkExe \
        -device "$1" \
        -if swd \
        -speed 4000 \
        -CommanderScript "$2" \
        -nogui 1 \
        -ExitOnError 1'

# Hidden recipe to run JLinkExe with common options
##### JLink flashing #####

jlink_flash_commands := '''
    LE
    loadfile HEX
    r
    g
    writeDP 1 0
    readDP 1
    '''
jlink_reset_commands := '''
    r
'''

#Rpico2 has a VTOR_ADDR of 0x10000200

jlink-verify-command := '''
    r
    h
    mem32 VTOR_ADDR
    '''

# Flash a hex file using J-Link.
jlink-flash device hex_file erase='true' reset='true' *extra_opts:
    @echo "INFO: Flashing {{ hex_file }} to {{ device }}"
    {{ shell(_jlink-run, device, "\n" + f'''                               \
        {{reset && "r"}}                 \
        {{erase && "erase"}}             \
        LE                               \
        loadfile {{hex_file}}                       \
        r                                  \
        g                                  \
        writeDP 1 0                        \
        readDP 1
    ''') }}

# Reset the target using J-Link

jlink_reset_command := '''
    con
    reset
    q
'''

# jlink-reset device:
#     @echo "INFO: Resetting {{ device }} "
#     @just _jlink-run "{{ device }}" "{{ jlink_reset_script_tmp_path }}"
# Verify flash content by reading memory with J-Link
# verify-flash device:
#     @echo "r\nh\nmem32 0x10000200 4\nq" > {{ jlink_verify_script_tmp_path }}
#     @echo "INFO: Verifying flash on {{ device }}"...
#     @just _jlink-run "{{ device }}" "{{ jlink_verify_script_tmp_path }}"

jlink_status_command := '''
    st
    con
    q
'''

# jlink-status device:
#     @echo "{{ jlink_status_command }}"  > "{{ jlink_action_script_tmp_path }}"
#     @echo "INFO: Getting Device Status"
#     @just _jlink-run {{ device }} "{{ jlink_action_script_tmp_path }}"
##### J-Link Probe Actions #####

jlink_5v_power_command := '''
    power <STATE>
    q
'''

# Toggle target power. State must be 'on' or 'off'.
jlink-power state:
    {{ if state =~ 'on&&off' { error('Invalid state') } else { '' } }}
    @echo "INFO: Turning target power {{ state }}"
    @JLinkExe \
      -CommanderScript "{{ replace(jlink_5v_power_command, '<STATE>', state) }}" \
        -nogui 1 \
        -ExitOnError 1

jlink_vcom_command := '''
    VCOM <STATE>
    q
'''

# Toggle VCOM. State must be 'enable' or 'disable'.
jlink-vcom state:
    {{ if state =~ 'enable&&disable' { error('Invalid state') } else { '' } }}
    @echo "INFO: Setting VCOM to {{ state }}. Power-cycle the J-Link probe for change to take effect."
    @JLinkExe \
        -CommanderScript "{{ replace(jlink_vcom_command, '<STATE>', state) }}" \
        -nogui 1 \
        -ExitOnError 1

jlink_probe_status_command := '''
    st
    f
    q
'''

# Show J-Link probe hardware and firmware status
jlink-status-probe:
    @echo "INFO: Getting JLink probe status"
    @JLinkExe \
        -CommanderScript "{{ jlink_probe_status_command }}" \
        -nogui 1 \
        -ExitOnError 1

##### Debugging #####

gdb_executable := require("arm-zephyr-eabi-gdb")
jlink_gdb_port := "2331"
remote_cmd := f'target remote :{{jlink_gdb_port}}'
extra_cmds := '''

        monitor halt
        monitor reset
        load

'''

# # Hidden recipe for GDB client
jlink-debug-client-gdb elf_file *extra_opts:
    @echo "Starting GDB client for {{ elf_file }}, connecting to localhost:{{ jlink_gdb_port }}"
    {{ gdb_executable }} \
        {{ elf_file }} \
        -ex '{{ remote_cmd }}'

##### J-Link Debugging #####

iface := "swd"
speed := "auto"

# Start J-Link GDB server
jlink-debug-server device *extra_opts:
    @echo "Starting J-Link GDB server on port {{ jlink_gdb_port }} for device {{ device }}"
    @JLinkGDBServer \
        -device "{{ device }}" \
        -if "{{ iface }}" \
        -speed "{{ speed }}" \
        -port "{{ jlink_gdb_port }}" \
        -silent \
        -singlerun \
        {{ extra_opts }}
