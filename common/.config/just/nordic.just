sdk-download-url-base := 'https://files.nordicsemi.com/artifactory/ncs-src-mirror/external/'
sdk-types := "sdk-nrf-bm sdk-nrf"
nrfutil := require('nrfutil')

[default]
@list:
    just --list --justfile {{ source_file() }}

[arg('type', pattern='baremetal|zephyr')]
download_sdk type version:
    @wget  {{ sdk-download-url-base / type / version / "src.tar.gz" }} -O {{ f'{{version}}.tar.gz' }}
    @tar -xzf {{ f'{{version}}.tar.gz' }} {{ version }}

[arg('version', pattern='^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-(0|[1-9A-Za-z-][0-9A-Za-z-]*)(?:\.(0|[1-9A-Za-z-][0-9A-Za-z-]*))* marshal)?(?:\+(0|[1-9A-Za-z-][0-9A-Za-z-]*)(?:\.(0|[1-9A-Za-z-][0-9A-Za-z-]*))* marshal)?$')]
toolchain_install version:
    {{ shell(f'{{nrfutil}} sdk-manager toolchain install --version {{version}}') }}

[group('nrfutil')]
flash hex_file snr:
    @{{ nrfutil }} device program --serial-number {{ snr }} --firmware {{ join(invocation_directory(), hex_file) }} --options chip_erase_mode=ERASE_ALL,reset=RESET_SYSTEM

[group('nrfutil')]
list-snr:
    @{{ nrfutil }} device list --json --skip-overhead | jq -r '.devices[].serialNumber'

[group('nrfutil')]
reset:
    @{{ nrfutil }} device reset

addr2line-bat-awk := '''
  {
      file_line = $NF
      if (match(file_line, /:[0-9]+$/)) {
          line = substr(file_line, RSTART + 1)
          file = substr(file_line, 1, RSTART - 1)
          start = line - 10
          if (start < 1)
              start = 1
          end = line + 10
          system("bat --line-range " start ":" end " --highlight-line " line " " file)
      }
  }

  '''

[group('binutils')]
addr2line-bat elf addr:
    @{{ require('arm-none-eabi-addr2line') }} -p -e {{ elf }} {{ addr }} | awk -- '{{ addr2line-bat-awk }}'
