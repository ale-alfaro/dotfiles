" after/compiler/west.vim — Zephyr `west build` (ninja + arm-zephyr-eabi gcc).
" Pulls compile/link diagnostics out of west/ninja output into the quickfix
" list. Use as:  :compiler west  then  :make
"            or:  :compiler west  then  :cfile <build.log>
"
" Overrides (set globally or per-buffer):
"   g:west_flags  extra `west build` flags  (default: -p (--pristine))
"   g:west_board  target board (default: native_sim/native)
"   g:west_app    source/app argument       (default: .)
" Pin a build dir via g:west_flags, e.g.
"   let g:west_flags = '-p -d build_debug'

let current_compiler = 'west'

" --- makeprg --------------------------------------------------------------
" Zephyr forces -fdiagnostics-color=always, so strip ANSI before the output
" reaches the parser — color escapes break errorformat matching.
let s:flags = get(b:, 'west_flags', get(g:, 'west_flags', '-p'))
let s:board = get(b:, 'west_board', get(g:, 'west_board', 'native_sim/native'))
let s:app   = get(b:, 'west_app',   get(g:, 'west_app', '.'))
let &l:makeprg = 'west build ' . s:flags . ' -b ' . s:board . ' ' . s:app
      \ . " 2>&1 | sed -u 's/\\x1b\\[[0-9;?]*[a-zA-Z]//g'"

" --- errorformat ----------------------------------------------------------
" Order matters. Drop gcc `note:` backtraces and the legacy "undeclared
" identifier" footer first (the macro-expansion notes from LOG_INF()/
" COND_CODE etc. otherwise flood the list), then devicetree errors, then
" type the real compiler errors/warnings, then CMake/Kconfig/west-level
" diagnostics, then fall back to generic / linker `file:line:` lines.
" Everything else — ninja `[n/m]` progress, the echoed compile command,
" `In function`/`In file included from` context, dtc unit-address warnings,
" the linker size table — matches no rule and is dropped.
let s:efm = [
      \ '%-G%f:%l:%c: note:%.%#',
      \ '%-G%f:%l: note:%.%#',
      \ '%-G%f:%l: %trror: (Each undeclared identifier is reported only once',
      \ '%-G%f:%l: %trror: for each function it appears in.)',
      \ 'devicetree %trror: %f:%l (column %c): %m',
      \ 'devicetree %trror: %f:%l: %m',
      \ '%f:%l:%c: %trror: %m',
      \ '%f:%l:%c: %tarning: %m',
      \ '%f:%l: %trror: %m',
      \ '%f:%l: %tarning: %m',
      \ 'CMake %tarning%.%# at %f:%l %m',
      \ 'CMake %trror at %f:%l %m',
      \ 'CMake %trror: %m',
      \ 'CMake %tarning: %m',
      \ 'FATAL ERROR: %m',
      \ '%tarning: %m',
      \ '%f:%l:%c: %m',
      \ '%f:%l: %m',
      \ '%-G%.%#',
      \ ]
let &l:errorformat = join(s:efm, ',')
