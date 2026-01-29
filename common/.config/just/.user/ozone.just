template := source_dir() / 'ozone' / 'TEMPLATE.jdebug'

# Creates a .jdebug file from the template
[arg('device_type', pattern='nRF52840_xxAA')]
ozone_init elf_file device_type='nRF52840_xxAA' project_dir=invocation_dir():
    @sed \
        -e 's|{{{{ PROJECT_DIR }}|"{{ project_dir }}"|g' \
        -e 's|{{{{ DEVICE_TYPE }}|"{{ device_type }}"|g' \
        -e 's|{{{{ ELF_FILE_PATH }}|"{{ elf_file }}"|g' \
         {{ template }} > "{{ project_dir / device_type }}.jdebug"
    @echo "Created {{ project_dir / device_type }} from template"
