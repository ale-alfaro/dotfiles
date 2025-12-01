default:
    @just --list

[group('nrfutil')]
flash hex_file snr:
    @nrfutil device program --serial-number {{ snr }} --firmware {{ join(invocation_directory(), hex_file) }} --options chip_erase_mode=ERASE_ALL,reset=RESET_SYSTEM

[group('nrfutil')]
list-snr:
    @nrfutil device list --json --skip-overhead | jq -r '.devices[].serialNumber'

[group('nrfutil')]
reset:
    @nrfutil device reset

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
    @arm-none-eabi-addr2line -p -e {{ elf }} {{ addr }} | awk -- '{{ addr2line-bat-awk }}'
