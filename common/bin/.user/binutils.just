set shell := ['zsh', '-uc', '--extendedglob']
set unstable := true

nrfutil := require('nrfutil')
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
dotfiles_dir := home_dir() / "dotfiles"

dots-bin *args:
    -print -rC1 {{ dotfiles_dir }}/**/bin/*(.x) | fzf  --prompt 'Executables> ' --preview '[[ -r {} ]] && bat --color=always {}' --bind 'enter:become({} {{ args }} )'

[group('binutils')]
addr2line-bat elf addr:
    {{ require('arm-zephyr-eabi-addr2line') }} -p -e {{ elf }} {{ addr }} | awk -- '{{ addr2line-bat-awk }}'
