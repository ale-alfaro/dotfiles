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

---@param mode (string|string[])?
---@param lhs string
---@param rhs string|fun(args:table)
----@param opts vim.keymap.set.Opts?
local function map(lhs, rhs, mode, opts)
  vim.validate('mode', mode, { 'string', 'table' }, true)
  vim.validate('lhs', lhs, 'string')
  vim.validate('rhs', rhs, { 'string', 'function' })
  vim.validate('opts', opts, 'table', true)
  opts = opts or {}
  mode = mode or 'n'
  vim.keymap.set(mode, lhs, rhs, opts)
end
local nmap_leader = function(key, cmd, desc)
  map('<leader>' .. key, cmd, { desc = desc })
end
map('q', '<nop>', nil, { noremap = true })
map('j', 'gj', { 'n', 'x' }, { desc = 'Navigate down (visual line)' })
map('k', 'gk', { 'n', 'x' }, { desc = 'Navigate up (visual line)' })
map('<Down>', 'gj', { 'n', 'x' }, { desc = 'Navigate down (visual line)' })
map('gk', '<Up>', { 'n', 'x' }, { desc = 'Navigate up (visual line)' })
map('<M-Up>', '<C-o>:move -2<cr>', 'i', { desc = 'Move Line Up' })
map('<M-Down>', '<C-o>:move +1<cr>', 'i', { desc = 'Move Line Down' })
map('<C-s>', '<Cmd>silent! update | redraw<CR>', nil, { desc = 'Save', noremap = true })
map('<C-s>', '<Esc><Cmd>silent! update | redraw<CR>', { 'x', 'i' }, { desc = 'Save and go to Normal mode', noremap = true })
map('<M-r>', '<Cmd>restart<CR>', nil, { desc = 'Restart', noremap = true })
map('<C-q>', '<Cmd>q<CR>', nil, { desc = 'Quit', noremap = true })

-- Misc
map('<leader>so', '<Cmd>source %<CR>', nil, { noremap = true, desc = 'Source Current buffer' })
map('<', '<gv', 'v')
map('>', '>gv', 'v')
map('<C-Left>', '<C-w>h', nil, { desc = 'Focus window left' })
map('<C-Right>', '<C-w>l', nil, { desc = 'Focus window right' })
map('<C-Up>', '<C-w>k', nil, { desc = 'Focus window up' })
map('<C-Down>', '<C-w>j', nil, { desc = 'Focus window up' })
