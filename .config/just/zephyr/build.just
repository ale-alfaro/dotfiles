
full_board_name_cmd := 'west boards --board-root ' + zmk_module_dir +  ' -f "{name}/{qualifiers}" ' + ' --name "$1"'

_build-full app_dir board artifact_name  *west_args="" *cmake_args="":
    @echo "Building zmk for {{board}}"
    # --- Execute the command ---
    west build -s {{app_dir}} -d "{{app_dir}}/build_{{artifact_name}}" -b "{{ shell(full_board_name_cmd, board) }}" {{west_args}} -p -- {{cmake_args}}

    @echo "Creating artifacts directory"
    @mkdir -p "{{app_dir}}/artifacts/{{artifact_name}}_{{datetime('%H:%M:%S')}}"
    @echo "Copying hex and uf2 files to artifacts directory"
    cp {{app_dir}}/build_{{artifact_name}}/zephyr/{zephyr.hex,zephyr.bin,zephyr.elf} {{app_dir}}/artifacts/{{artifact_name}}_{{datetime('%H:%M:%S')}}

