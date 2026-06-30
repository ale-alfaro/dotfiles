
" after/compiler/west.vim — Zephyr `west build` (ninja + arm-zephyr-eabi gcc).
" Pulls compile/link diagnostics out of west/ninja output into the quickfix
" list. Use as:  :compiler west  then  :make
"            or:  :compiler west  then  :cfile <build.log>
"
" Overrides (set globally or per-buffer):
"   g:west_flags  extra `west build` flags  (default: --build-opt=-k0 → ninja keep-going)
"   g:west_app    source/app argument       (default: .)
" Pin a build dir via g:west_flags, e.g.
"   let g:west_flags = '-d build_debug --build-opt=-k0'

let current_compiler = 'mise'

" --- makeprg --------------------------------------------------------------
" Zephyr forces -fdiagnostics-color=always, so strip ANSI before the output
" reaches the parser — color escapes break errorformat matching.
let s:flags = get(b:, 'mise_flags', get(g:, 'mise_flags', ''))
let s:task = get(b:, 'mise_task',   get(g:, 'mise_task', 'build'))
exe 'CompilerSet makeprg=' .. escape('mise run'
      \ ..' '.. s:flags
      \ ..' '.. s:task
      \ ..' ', ' \|"')
" --- errorformat ----------------------------------------------------------
" Order matters. Drop gcc `note:` backtraces first (the macro-expansion notes
" from LOG_INF()/COND_CODE etc. otherwise flood the list), then type the real
" errors/warnings, then fall back to generic / linker `file:line:` lines.
" Everything else — ninja `[n/m]` progress, `FAILED:`, the echoed compile
" command, `In function`/`In file included from` context, dtc/Kconfig/CMake
" warnings, the linker size table — matches no rule and is dropped.
let s:efm = [
      \ '%-G%f:%l:%c: note:%.%#',
      \ '%-G%f:%l: note:%.%#',
      \ '%f:%l:%c: %trror: %m',
      \ '%f:%l:%c: %tarning: %m',
      \ '%f:%l: %trror: %m',
      \ '%f:%l: %tarning: %m',
      \ 'CMake %trror at %f:%l %m',
      \ '%f:%l:%c: %m',
      \ '%f:%l: %m',
      \ '%-G%.%#',
      \ ]
let &l:errorformat = join(s:efm, ',')


