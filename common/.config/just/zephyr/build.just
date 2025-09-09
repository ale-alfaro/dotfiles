
# full_board_name_cmd := 'west boards -f "{name}/{qualifiers}" --name "$1"'

build-base app_dir board artifact_name *extra_args:
    @echo "West Build for {{board}} in directory build_{{artifact_name}}"
    # --- Execute the command ---
    west build -s {{app_dir}} -d "{{app_dir}}/build_{{artifact_name}}" -b {{board}} --pristine=always {{extra_args}}

    # @echo "Creating artifacts directory"
    # @mkdir -p "artifacts/{{artifact_name}}_{{datetime('%H:%M:%S')}}"
    # @echo "Copying artifacts"
    # cp build_{{artifact_name}}/zephyr/{zephyr.hex,zephyr.bin,zephyr.elf} artifacts/{{artifact_name}}_{{datetime('%H:%M:%S')}}

build-full board artifact shield snippets app_dir=invocation_directory() *extra_args:
    just build-base {{app_dir}} {{board}} {{artifact}} "--shield {{shield}} -S {{snippets}} {{extra_args}}"
