-- ┌─────────────────┐
-- │ Custom mappings │
-- └─────────────────┘
--[
--    1.3 MAPPING AND MODES					*:map-modes*
--        *mapmode-nvo* *mapmode-n* *mapmode-v* *mapmode-o* *mapmode-t*
--
--    There are seven sets of mappings
--    - For Normal mode: When typing commands.
--    - For Visual mode: When typing commands while the Visual area is highlighted.
--    - For Select mode: like Visual mode but typing text replaces the selection.
--    - For Operator-pending mode: When an operator is pending (after "d", "y", "c",
--      etc.).  See below: |omap-info|.
--    - For Insert mode.  These are also used in Replace mode.
--    - For Command-line mode: When entering a ":" or "/" command.
--    - For Terminal mode: When typing in a |:terminal| buffer.
--
--    Special case: While typing a count for a command in Normal mode, mapping zero
--    is disabled.  This makes it possible to map zero without making it impossible
--    to type a count with a zero.
--
--                *map-overview* *map-modes*
--    Overview of which map command works in which mode.  More details below.
--        COMMANDS                    MODES ~
--    :map   :noremap  :unmap     Normal, Visual, Select, Operator-pending
--    :nmap  :nnoremap :nunmap    Normal
--    :vmap  :vnoremap :vunmap    Visual and Select
--    :smap  :snoremap :sunmap    Select
--    :xmap  :xnoremap :xunmap    Visual
--    :omap  :onoremap :ounmap    Operator-pending
--    :map!  :noremap! :unmap!    Insert and Command-line
--    :imap  :inoremap :iunmap    Insert
--    :lmap  :lnoremap :lunmap    Insert, Command-line, Lang-Arg
--    :cmap  :cnoremap :cunmap    Command-line
--    :tmap  :tnoremap :tunmap    Terminal
--
--  Keycodes                                 *key-notation* *key-codes* *keycodes*
--
--  These names for keys are used in the documentation.  They can also be used
--  with the ":map" command.
--
--  notation        meaning             equivalent  decimal value(s)        ~
--  <Nul>           Zero                    CTRL-@    0 (stored as 10) *<Nul>*
--  <BS>            Backspace               CTRL-H    8     *backspace*
--  <Tab>           Tab                     CTRL-I    9     *tab* *Tab*
--                                                          *linefeed*
--  <NL>            Linefeed                CTRL-J   10 (used for <Nul>)
--  <CR>            Carriage return         CTRL-M   13     *carriage-return*
--  <Return>        Same as <CR>                            *<Return>*
--  <Enter>         Same as <CR>                            *<Enter>*
--  <Esc>           Escape                  CTRL-[   27     *escape* *<Esc>*
--  <Space>         Space                            32     *space*
--  <lt>            Less-than               <        60     *<lt>*
--  <Bslash>        Backslash               \        92     *backslash* *<Bslash>*
--  <Bar>           Vertical bar            |       124     *<Bar>*
--  <Del>           Delete                          127
--  <CSI>           Command sequence intro  ALT-Esc 155     *<CSI>*
--
--  <EOL>           End-of-line (can be <CR>, <NL> or <CR><NL>,
--                  Depends on system and 'fileformat')     *<EOL>*
--  <Ignore>        Cancel wait-for-character               *<Ignore>*
--  <NOP>           Do nothing (no-op). Useful in mappings. *<Nop>*
--                  <Ignore> is a key, <NOP> is "absence of a key".
--
--  <Up>            Cursor-up                       *cursor-up* *cursor_up*
--  <Down>          Cursor-down                     *cursor-down* *cursor_down*
--  <Left>          Cursor-left                     *cursor-left* *cursor_left*
--  <Right>         Cursor-right                    *cursor-right* *cursor_right*
--  <S-Up>          Shift-cursor-up
--  <S-Down>        Shift-cursor-down
--  <S-Left>        Shift-cursor-left
--  <S-Right>       Shift-cursor-right
--  <C-Left>        Control-cursor-left
--  <C-Right>       Control-cursor-right
--  <F1> - <F12>    Function keys 1 to 12           *function_key* *function-key*
--  <S-F1> - <S-F12> Shift-function keys 1 to 12    *<S-F1>*
--  <Help>          Help key
--  <Undo>          Undo key
--  <Find>          Find key
--  <Select>        Select key
--  <Insert>        Insert key
--  <Home>          Home                            *home*
--  <End>           End                             *end*
--  <PageUp>        Page-up                         *page_up* *page-up*
--  <PageDown>      Page-down                       *page_down* *page-down*
--  <kUp>           Keypad cursor-up                *keypad-cursor-up*
--  <kDown>         Keypad cursor-down              *keypad-cursor-down*
--  <kLeft>         Keypad cursor-left              *keypad-cursor-left*
--  <kRight>        Keypad cursor-right             *keypad-cursor-right*
--  <kHome>         Keypad home (upper left)        *keypad-home*
--  <kEnd>          Keypad end (lower left)         *keypad-end*
--  <kOrigin>       Keypad origin (middle)          *keypad-origin*
--  <kPageUp>       Keypad page-up (upper right)    *keypad-page-up*
--  <kPageDown>     Keypad page-down (lower right)  *keypad-page-down*
--  <kDel>          Keypad delete                   *keypad-delete*
--  <kPlus>         Keypad +                        *keypad-plus*
--  <kMinus>        Keypad -                        *keypad-minus*
--  <kMultiply>     Keypad *                        *keypad-multiply*
--  <kDivide>       Keypad /                        *keypad-divide*
--  <kPoint>        Keypad .                        *keypad-point*
--  <kComma>        Keypad ,                        *keypad-comma*
--  <kEqual>        Keypad =                        *keypad-equal*
--  <kEnter>        Keypad Enter                    *keypad-enter*
--  <k0> - <k9>     Keypad 0 to 9                   *keypad-0* *keypad-9*
--  <S-…>           Shift-key                       *shift* *<S-*
--  <C-…>           Control-key                     *control* *ctrl* *<C-*
--  <M-…>           Alt-key or meta-key             *META* *ALT* *<M-*
--  <A-…>           Same as <M-…>                   *<A-*
--  <T-…>           Meta-key, when it's not alt     *<T-*
--  <D-…>           Command-key or "super" key      *<D-*
--
--
--    - Availability of some keys (<Help>, <S-Right>, …) depends on the UI or host
--      terminal.
--    - If numlock is on the |TUI| receives plain ASCII values, so mapping <k0>,
--      <k1>, ..., <k9> and <kPoint> will not work.
--    - Nvim supports mapping multibyte chars with modifiers such as `<M-ä>`. Which
--      combinations actually work depends on the UI or host terminal.
--    - When a key is pressed using a meta or alt modifier and no mapping exists for
--      that keypress, Nvim may behave as though <Esc> was pressed before the key.
--    - It is possible to notate combined modifiers (e.g. <M-C-T> for CTRL-ALT-T),
--      but your terminal must encode the input for that to work. |tui-input|
--
--                                                                    *<>*
--    Examples are often given in the <> notation.  Sometimes this is just to make
--    clear what you need to type, but often it can be typed literally, e.g., with
--    the ":map" command.  The rules are:
--    1.  Printable characters are typed directly, except backslash and "<"
--    2.  Backslash is represented with "\\", double backslash, or "<Bslash>".
--    3.  Literal "<" is represented with "\<" or "<lt>".  When there is no
--        confusion possible, "<" can be used directly.
--    4.  "<key>" means the special key typed (see the table above).  Examples:
--        - <Esc>             Escape key
--        - <C-G>             CTRL-G
--        - <Up>              cursor up key
--        - <C-LeftMouse>     Control- left mouse click
--        - <S-F11>           Shifted function key 11
--        - <M-a>             Meta- a  ('a' with bit 8 set)
--        - <M-A>             Meta- A  ('A' with bit 8 set)
--
--    The <> notation uses <lt> to escape the special meaning of key names.  Using a
--    backslash also works, but only when 'cpoptions' does not include the 'B' flag.
--
--    Examples for mapping CTRL-H to the six characters "<Home>": >vim
--            :imap <C-H> \<Home>
--            :imap <C-H> <lt>Home>
--    The first one only works when the 'B' flag is not in 'cpoptions'.  The second
--    one always works.
--    To get a literal "<lt>" in a mapping: >vim
--            :map <C-L> <lt>lt>
--
--    The notation can be used in a double quoted strings, using "\<" at the start,
--    e.g. "\<C-Space>".  This results in a special key code.  To convert this back
--    to readable text use `keytrans()`.
--
--
-- ]--

-- ──────────────────────────────────────────────────────────────
--  switch_case  — toggle camelCase ↔ snake_case under cursor
-- ──────────────────────────────────────────────────────────────

--[[
--
--1.7 WHAT KEYS TO MAP					*map-which-keys*

If you are going to map something, you will need to choose which key(s) to use
for the {lhs}.  You will have to avoid keys that are used for Vim commands,
otherwise you would not be able to use those commands anymore.  Here are a few
suggestions:
- Function keys <F2>, <F3>, etc..  Also the shifted function keys <S-F1>,
  <S-F2>, etc.  Note that <F1> is already used for the help command.
- Meta-keys (with the ALT key pressed).  Depending on your keyboard accented
  characters may be used as well. |:map-alt-keys|
- Use the '_' or ',' character and then any other character.  The "_" and ","
  commands do exist in Vim (see |_| and |,|), but you probably never use them.
- Use a key that is a synonym for another command.  For example: CTRL-P and
  CTRL-N.  Use an extra character to allow more mappings.
- The key defined by <Leader> and one or more other keys.  This is especially
  useful in scripts. |mapleader|

See the file "index" for keys that are not used and thus can be mapped without
losing any builtin function.  You can also use ":help {key}^D" to find out if
a key is used for some command.  ({key} is the specific key you want to find
out about, ^D is CTRL-D).
--
--]]
VimRc.keymap_clues = {
  { mode = 'n', keys = '<Leader>b', desc = '+Buffer' },
  { mode = 'n', keys = '<Leader>e', desc = '+Explore/Edit' },
  { mode = 'n', keys = '<Leader>f', desc = '+Find' },
  { mode = 'n', keys = '<Leader>g', desc = '+Git' },
  { mode = 'n', keys = '<Leader>l', desc = '+Language' },
  { mode = 'n', keys = '<Leader>n', desc = '+Notifications' },
  { mode = 'n', keys = '<Leader>o', desc = '+Obsidian' },
  { mode = 'n', keys = '<Leader>s', desc = '+Session' },
  { mode = 'n', keys = '<Leader>x', desc = '+Extra' },
  { mode = 'n', keys = '<Leader>v', desc = '+Visits' },

  { mode = 'x', keys = '<Leader>g', desc = '+Git' },
  { mode = 'x', keys = '<Leader>l', desc = '+Language' },
}
VimRc.map({ lhs = 'q', rhs = '<nop>' }, { noremap = true })
VimRc.map({ mode = 'v', lhs = '<', rhs = '<gv' }, { noremap = true })
VimRc.map({ mode = 'v', lhs = '>', rhs = '>gv' }, { noremap = true })
VimRc.map({ mode = { 'n', 'x' }, lhs = '<Down>', rhs = 'gj' }, 'Navigate down (visual line)')
VimRc.map({ mode = { 'n', 'x' }, lhs = '<Up>', rhs = 'gk' }, 'Navigate down (visual line)')
VimRc.map({ mode = { 'n', 'x' }, lhs = '<Down>', rhs = [[v:count == 0 ? 'gj' : 'j']] }, { expr = true })
VimRc.map({ mode = { 'n', 'x' }, lhs = '<Up>', rhs = [[v:count == 0 ? 'gk' : 'k']] }, { expr = true })

-- Add empty lines before and after cursor line supporting dot-repeat
VimRc.put_empty_line = function(put_above)
  -- This has a typical workflow for enabling dot-repeat:
  -- - On first call it sets `operatorfunc`, caches data, and calls
  --   `operatorfunc` on current cursor position.
  -- - On second call it performs task: puts `v:count1` empty lines
  --   above/below current line.
  if type(put_above) == 'boolean' then
    vim.o.operatorfunc = 'v:lua.VimRc.put_empty_line'
    VimRc.cache_empty_line = { put_above = put_above }
    return 'g@l'
  end

  local target_line = vim.fn.line '.' - (VimRc.cache_empty_line.put_above and 1 or 0)
  vim.fn.append(target_line, vim.fn['repeat']({ '' }, vim.v.count1))
end

VimRc.map({ lhs = 'gO', rhs = 'v:lua.MiniBasics.put_empty_line(v:true)' }, { expr = true, desc = 'Put empty line above' })
VimRc.map({ lhs = 'go', rhs = 'v:lua.MiniBasics.put_empty_line(v:false)' }, { expr = true, desc = 'Put empty line below' })
-- Reselect latest changed, put, or yanked text
VimRc.map({ lhs = 'gV', rhs = '"g`[" . strpart(getregtype(), 0, 1) . "g`]"' }, { expr = true, replace_keycodes = false, desc = 'Visually select changed text' })
-- Search inside visually highlighted text. Use `silent = false` for it to
-- make effect immediately.
VimRc.map({ mode = 'x', lhs = 'g/', rhs = '<esc>/\\%V' }, { silent = false, desc = 'Search inside visual selection' })
VimRc.map({ lhs = '<C-s>', rhs = '<Cmd>silent! update | redraw<CR>' }, { noremap = true })
VimRc.map({ mode = { 'x', 'i' }, lhs = '<C-s>', rhs = '<Esc><Cmd>silent! update | redraw<CR>' }, { noremap = true })
VimRc.map({ lhs = '<C-q>', rhs = '<Cmd>q<CR>' }, { noremap = true })
VimRc.map({ lhs = '<M-q>', rhs = '<Cmd>qall!<CR>' }, { desc = 'Quit all!', noremap = true })
VimRc.map({ lhs = '<C-Left>', rhs = '<C-w>h' }, 'Focus window left')
VimRc.map({ lhs = '<C-Right>', rhs = '<C-w>l' }, 'Focus window right')
VimRc.map({ lhs = '<C-Up>', rhs = '<C-w>k' }, 'Focus window up')
VimRc.map({ lhs = '<C-Down>', rhs = '<C-w>j' }, 'Focus window up')

---@param key string
---@param keycmd string|fun()
---@param desc string
local nmap_leader = function(key, keycmd, desc)
  VimRc.map({ mode = 'n', lhs = '<leader>' .. key, rhs = keycmd }, { desc = desc })
end
nmap_leader('ba', '<Cmd>b#<CR>', 'Alternate')
nmap_leader('bd', '<Cmd>lua MiniBufremove.delete()<CR>', 'Delete')
nmap_leader('bD', '<Cmd>lua MiniBufremove.delete(0, true)<CR>', 'Delete!')
nmap_leader('bs', function()
  vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(true, true))
end, 'Scratch')
nmap_leader('bw', '<Cmd>lua MiniBufremove.wipeout()<CR>', 'Wipeout')
nmap_leader('bW', '<Cmd>lua MiniBufremove.wipeout(0, true)<CR>', 'Wipeout!')

local explore_quickfix = function()
  vim.cmd(vim.fn.getqflist({ winid = true }).winid ~= 0 and 'cclose' or 'copen')
end
local explore_locations = function()
  vim.cmd(vim.fn.getloclist(0, { winid = true }).winid ~= 0 and 'lclose' or 'lopen')
end
nmap_leader('eq', explore_quickfix, 'Quickfix list')
nmap_leader('eQ', explore_locations, 'Location list')
-- s is for 'Session'. Common usage:
-- - `<Leader>sn` - start new session
-- - `<Leader>sr` - read previously started session
-- - `<Leader>sR` - restart Neovim preserving current session
local session_new = 'vim.ui.input({ prompt = "Session name: " }, MiniSessions.write)'

nmap_leader('sd', '<Cmd>lua MiniSessions.select("delete")<CR>', 'Delete')
nmap_leader('sn', '<Cmd>lua ' .. session_new .. '<CR>', 'New')
VimRc.map({ lhs = '<M-r>', rhs = '<Cmd>lua MiniSessions.restart()<CR>' }, 'Restart')
nmap_leader('sr', '<Cmd>lua MiniSessions.select("read")<CR>', 'Read')
nmap_leader('ss', '<Cmd>lua MiniSessions.write()<CR>', 'Write current')
-- map('<M-r>', '<Cmd>restart<CR>', nil, { desc = 'Restart', noremap = true })

-- v is for 'Visits'. Common usage:
-- - `<Leader>vv` - add    "core" label to current file.
-- - `<Leader>vV` - remove "core" label to current file.
-- - `<Leader>vc` - pick among all files with "core" label.
local make_pick_core = function(cwd, desc)
  return function()
    local sort_latest = MiniVisits.gen_sort.default { recency_weight = 1 }
    local local_opts = { cwd = cwd, filter = 'core', sort = sort_latest }
    MiniExtra.pickers.visit_paths(local_opts, { source = { name = desc } })
  end
end

nmap_leader('vc', make_pick_core('', 'Core visits (all)'), 'Core visits (all)')
nmap_leader('vC', make_pick_core(nil, 'Core visits (cwd)'), 'Core visits (cwd)')
nmap_leader('vv', '<Cmd>lua MiniVisits.add_label("core")<CR>', 'Add "core" label')
nmap_leader('vV', '<Cmd>lua MiniVisits.remove_label("core")<CR>', 'Remove "core" label')
nmap_leader('vl', '<Cmd>lua MiniVisits.add_label()<CR>', 'Add label')
nmap_leader('vL', '<Cmd>lua MiniVisits.remove_label()<CR>', 'Remove label')
