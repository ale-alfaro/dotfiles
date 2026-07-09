VimRc.later(function()
  require('mini.extra').setup()
end)

-- Session management. A thin wrapper around `:h mksession` that consistently
-- manages session files. Example usage:
-- - `<Leader>sn` - start new session
-- - `<Leader>sr` - read previously started session
-- - `<Leader>sd` - delete previously started session
VimRc.now(function()
  require('mini.sessions').setup()
  VimRc.map({ lhs = '<M-r>', rhs = '<Cmd>lua MiniSessions.restart()<CR>' }, 'Restart')
end)

VimRc.later(function()
  require('mini.visits').setup()
  -- v is for 'Visits'. Common usage:
  -- - `<Leader>vv` - add    "core" label to current file.
  -- - `<Leader>vV` - remove "core" label to current file.
  -- - `<Leader>vc` - pick among all files with "core" label.
  local make_pick_core = function(cwd, desc)
    return function()
      local sort_latest = MiniVisits.gen_sort.default { recency_weight = 1 }
      local local_opts = { cwd = cwd, filter = 'core', sort = sort_latest }
      require('mini.extras').pickers.visit_paths(local_opts, { source = { name = desc } })
    end
  end
  -- VimRc.later(function()
  --   require('mini.visits').setup()
  -- end)
  -- s is for 'Session'. Common usage:
  -- - `<Leader>sn` - start new session
  -- - `<Leader>sr` - read previously started session
  -- - `<Leader>sR` - restart Neovim preserving current session
  local session_new = 'vim.ui.input({ prompt = "Session name: " }, MiniSessions.write)'

  local persist_keys = {
    { 'n', '<Cmd>lua ' .. session_new .. '<CR>', 'New Sesh' },
    { 'd', '<Cmd>lua MiniSessions.select("delete")<CR>', 'Delete Sesh' },
    { 's', '<Cmd>lua MiniSessions.write()<CR>', 'Write Sesh' },
    { 'r', '<Cmd>lua MiniSessions.select("read")<CR>', 'Read Sesh' },
    { 'c', make_pick_core('', 'Core visits (all)'), 'Core visits (all)' },
    { 'C', make_pick_core(nil, 'Core visits (cwd)'), 'Core visits (cwd)' },
    { 'v', '<Cmd>lua MiniVisits.add_label("core")<CR>', 'Add "core" label' },
    { 'V', '<Cmd>lua MiniVisits.remove_label("core")<CR>', 'Remove "core" label' },
    { 'l', '<Cmd>lua MiniVisits.add_label()<CR>', 'Add label' },
    { 'L', '<Cmd>lua MiniVisits.remove_label()<CR>', 'Remove label' },
  }
  for _, key in ipairs(persist_keys) do
    vim.keymap.set('n', '<leader>p' .. key[1], key[2], { desc = key[3] })
  end
  VimRc.keymap_clues[#VimRc.keymap_clues + 1] = { mode = 'n', keys = '<Leader>p', desc = '+Persist' }
end)
-- local builtin_textobjects = {
--   -- Use balanced pair for brackets. Use opening ones to possibly remove edge
--   -- whitespace from `i` textobject.
--   ['('] = { '%b()', '^.%s*().-()%s*.$' },
--   [')'] = { '%b()', '^.().*().$' },
--   ['['] = { '%b[]', '^.%s*().-()%s*.$' },
--   [']'] = { '%b[]', '^.().*().$' },
--   ['{'] = { '%b{}', '^.%s*().-()%s*.$' }%,
--   ['}'] = { '%b{}', '^.().*().$' },
--   ['<'] = { '%b<>', '^.%s*().-()%s*.$' },
--   ['>'] = { '%b<>', '^.().*().$' },
--   -- Use special "same balanced" pattern to select quotes in pairs
--   ["'"] = { "%b''", '^.().*().$' },
--   ['"'] = { '%b""', '^.().*().$' },
--   ['`'] = { '%b``', '^.().*().$' },
--   -- Derived from user prompt
--   ['?'] = MiniAi.gen_spec.user_prompt(),
--   -- Argument
--   ['a'] = MiniAi.gen_spec.argument(),
--   -- Brackets
--   ['b'] = { { '%b()', '%b[]', '%b{}' }, '^.().*().$' },
--   -- Function call
--   ['f'] = MiniAi.gen_spec.function_call(),
--   -- Tag
--   ['t'] = { '<(%w-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' },
--   -- Quotes
--   ['q'] = { { "%b''", '%b""', '%b``' }, '^.().*().$' },
--

-- Extend and create a/i textobjects, like `:h a(`, `:h a'`, and more).
-- Contains not only `a` and `i` type of textobjects, but also their "next" and
-- "last" variants that will explicitly search for textobjects after and before
-- cursor. Example usage:
-- - `ci)` - *c*hange *i*inside parenthesis (`)`)
-- - `di(` - *d*elete *i*inside padded parenthesis (`(`)
-- - `yaq` - *y*ank *a*round *q*uote (any of "", '', or ``)
-- - `vif` - *v*isually select *i*inside *f*unction call
-- - `cina` - *c*hange *i*nside *n*ext *a*rgument
-- - `valaala` - *v*isually select *a*round *l*ast (i.e. previous) *a*rgument
--   and then again reselect *a*round new *l*ast *a*rgument
--
-- See also:
-- - `:h text-objects` - general info about what textobjects are
-- - `:h MiniAi-builtin-textobjects` - list of all supported textobjects
-- - `:h MiniAi-textobject-specification` - examples of custom textobjects
VimRc.later(function()
  local ai = require 'mini.ai'
  ai.setup {
    custom_textobjects = {
      D = MiniExtra.gen_ai_spec.diagnostic(),
      L = MiniExtra.gen_ai_spec.line(),
      F = ai.gen_spec.treesitter { a = '@function.outer', i = '@function.inner' },
      c = ai.gen_spec.treesitter {
        a = { '@conditional.outer', '@loop.outer' },
        i = { '@conditional.inner', '@loop.inner' },
      },
      f = ai.gen_spec.function_call { name_pattern = '[%w_%.%>%<]' },
      p = ai.gen_spec.user_prompt(),
      ['|'] = ai.gen_spec.pair('|', '|', { type = 'non-balanced' }),
    },
  }
end)

VimRc.later(function()
  require('mini.misc').setup()
  MiniMisc.setup_auto_root()
  MiniMisc.setup_termbg_sync()
  MiniMisc.setup_restore_cursor()
end)
-- Common configuration presets. Example usage:
-- - `<C-s>` in Insert mode - save and go to Normal mode
-- - `go` / `gO` - insert empty line before/after in Normal mode
-- - `gy` / `gp` - copy / paste from system clipboard
-- - `\` + key - toggle common options. Like `\h` toggles highlighting search.
-- - `<C-hjkl>` (four combos) - navigate between windows.
VimRc.later(function()
  require('mini.bufremove').setup()
end)
VimRc.later(function()
  require('mini.align').setup()
end)

VimRc.later(function()
  require('mini.bracketed').setup {
    comment = { suffix = '', options = {} },
    conflict = { suffix = 'c', options = {} },
  }
end)

VimRc.later(function()
  require('mini.comment').setup()
end)
VimRc.later(function()
  require('mini.indentscope').setup()
end)

VimRc.later(function()
  require('mini.move').setup {
    mappings = {
      left = '<M-left>',
      right = '<M-right>',
      down = '<M-down>',
      up = '<M-up>',

      line_left = '<M-S-left>',
      line_right = '<M-S-right>',
      line_down = '<M-S-down>',
      line_up = '<M-S-up>',
    },
  }
end)

VimRc.later(function()
  require('mini.jump').setup()
end)

-- Split and join arguments (regions inside brackets between allowed separators).
-- It uses Lua patterns to find arguments, which means it works in comments and
-- strings but can be not as accurate as tree-sitter based solutions.
-- Each action can be configured with hooks (like add/remove trailing comma).
-- Example usage:
-- - `gS` - toggle between joined (all in one line) and split (each on a separate
--   line and indented) arguments. It is dot-repeatable (see `:h .`).
--
-- See also:
-- - `:h MiniSplitjoin.gen_hook` - list of available hooks
VimRc.later(function()
  require('mini.splitjoin').setup()
end)

--
-- Example usage (this may feel intimidating at first, but after practice it
-- becomes second nature during text editing):
-- - `sdf`   - *s*urround *d*elete *f*unction call (like `f(var)` -> `var`)
-- - `srb[`  - *s*urround *r*eplace *b*racket (any of [], (), {}) with padded `[`
-- - `sf*`   - *s*urround *f*ind right part of `*` pair (like bold in markdown)
-- - `shf`   - *s*urround *h*ighlight current *f*unction call
-- - `srn{{` - *s*urround *r*eplace *n*ext curly bracket `{` with padded `{`
-- - `sdl'`  - *s*urround *d*elete *l*ast quote pair (`'`)
-- - `vaWsa<Space>` - *v*isually select *a*round *W*ORD and *s*urround *a*dd
--                    spaces (`<Space>`)
---
--- Regular mappings:
--- - `saiw?[[<CR>]]<CR>` - add (`sa`) for inner word (`iw`) interactive
---   surrounding (`?`): `[[` for left and `]]` for right.
--- - `2sdf` - delete (`sd`) second (`2`) surrounding function call (`f`).
--- - `sr)tdiv<CR>` - replace (`sr`) surrounding parenthesis (`)`) with tag
---   (`t`) with identifier 'div' (`div<CR>` in command line prompt).
--- - `sff` - find right (`sf`) part of surrounding function call (`f`).
--- - `sh}` - highlight (`sh`) for a brief period of time surrounding curly
---   brackets (`}`).
---
--- Extended mappings (temporary force "prev"/"next" search methods):
--- - `sdnf` - delete (`sd`) next (`n`) function call (`f`).
--- - `srlf(` - replace (`sr`) last (`l`) function call (`f`) with padded
---   bracket (`(`).
--- - `2sfnt` - find (`sf`) second (`2`) next (`n`) tag (`t`).
--- - `2shl}` - highlight (`sh`) last (`l`) second (`2`) curly bracket (`}`).
-- See also:
--- `Key` represents the surrounding identifier: single character which should
--  be typed after action mappings (see "Mappings" in |MiniSurround.config|).
--- `Name` is a description of surrounding.
--- `Example line` contains a string for which examples are constructed. The
--  `*` denotes the cursor position over `a` character.
--- `Delete` shows the result of typing `sd` followed by surrounding identifier.
--  It aims to demonstrate "input" surrounding which is also used in replace
--  with `sr` (surrounding id is typed first), highlight with `sh`, find with
--  `sf` and `sF`.
--- `Replace` shows the result of typing `sr!` followed by surrounding
--  identifier (with possible follow up from user). It aims to demonstrate
--  "output" surrounding which is also used in adding with `sa` (followed by
--  textobject/motion or in Visual mode).
--
--Example: typing `sd)` with cursor on `*` (covers `a` character) changes line
--`!( *a (bb) )!` into `! aa (bb) !`. Typing `sr!)` changes same initial line
--into `(( aa (bb) ))`.
-->
-- ┌───┬───────────────┬───────────────┬─────────────┬─────────────────┐
-- │Key│     Name      │  Example line │    Delete   │     Replace     │
-- ├───┴───────────────┴───────────────┴─────────────┴─────────────────┤
-- ├┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
-- │ ( │  Balanced ()  │ !( *a (bb) )! │  !aa (bb)!  │ ( ( aa (bb) ) ) │
-- │ [ │  Balanced []  │ ![ *a [bb] ]! │  !aa [bb]!  │ [ [ aa [bb] ] ] │
-- │ { │  Balanced {}  │ !{ *a {bb} }! │  !aa {bb}!  │ { { aa {bb} } } │
-- │ < │  Balanced <>  │ !< *a <bb> >! │  !aa <bb>!  │ < < aa <bb> > > │
-- ├┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
-- │ ) │  Balanced ()  │ !( *a (bb) )! │ ! aa (bb) ! │ (( aa (bb) ))   │
-- │ ] │  Balanced []  │ ![ *a [bb] ]! │ ! aa [bb] ! │ [[ aa [bb] ]]   │
-- │ } │  Balanced {}  │ !{ *a {bb} }! │ ! aa {bb} ! │ {{ aa {bb} }}   │
-- │ > │  Balanced <>  │ !< *a <bb> >! │ ! aa <bb> ! │ << aa <bb> >>   │
-- │ b │  Alias for    │ !( *a {bb} )! │ ! aa {bb} ! │ (( aa {bb} ))   │
-- │   │  ), ], or }   │               │             │                 │
-- ├┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
-- │ q │  Alias for    │ !'aa'*a'aa'!  │ !'aaaaaa'!  │ "'aa'aa'aa'"    │
-- │   │  ", ', or `   │               │             │                 │
-- ├┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
-- │ ? │  User prompt  │ !e * o!       │ ! a !       │ ee a oo         │
-- │   │(typed e and o)│               │             │                 │
-- ├┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
-- │ t │      Tag      │ !<x>*</x>!    │ !a!         │ <y><x>a</x></y> │
-- │   │               │               │             │ (typed y)       │
-- ├┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
-- │ f │ Function call │ !f(*a, bb)!   │ !aa, bb!    │ g(f(*a, bb))    │
-- │   │               │               │             │ (typed g)       │
-- ├┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
-- │   │    Default    │ !_a*a_!       │ !aaa!       │ __aaa__         │
-- │   │   (typed _)   │               │             │                 │
-- └┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┘
--
--
--                                               *MiniSurround-count-with-actions*
-- |[count]| is supported by all actions in the following ways:
--
-- * In add, two types of `[count]` is supported in Normal mode:
--  `[count1]sa[count2][textobject]`. The `[count1]` defines how many times
--  left and right parts of output surrounding will be repeated and `[count2]` is
--  used for textobject.
--  In Visual mode `[count]` is treated as `[count1]`.
--  Example: `2sa3aw)` and `v3aw2sa)` will result into textobject `3aw` being
--  surrounded by `((` and `))`.
--
--- In delete/replace/find/highlight `[count]` means "find n-th surrounding
--  and execute operator on it".
--  Example: `2sd)` on line `(a(b(c)b)a)` with cursor on `c` will result into
--  `(ab(c)ba)` (and not in `(abcba)` if it would have meant "delete n times").

--
VimRc.later(function()
  -- local surround = require 'mini.surround'
  -- local ts_input = surround.gen_spec.input.treesitter
  require('mini.surround').setup()
  --   custom_surroundings = {
  --     f = {
  --       input = ts_input({ outer = '@call.outer', inner = '@calll.inner' }, { use_nvim_treesitter = true }),
  --     },
  --   },
  -- }
end)

-- Highlight and remove trailspace. Temporarily stops highlighting in Insert mode
-- to reduce noise when typing. Example usage:
-- - `<Leader>ot` - trim all trailing whitespace in a buffer
VimRc.later(function()
  require('mini.trailspace').setup()
  require('mini.operators').setup {

    replace = {
      -- NOTE: Default `gr*` LSP mappings are removed
      prefix = 'go',

      -- Whether to reindent new text to match previous indent
      reindent_linewise = true,
    },
  }
end)

VimRc.later(function()
  require('mini.hipatterns').setup {
    highlighters = {
      fixme = require('mini.extra').gen_highlighter.words({ 'FIXME', 'Fixme', 'fixme' }, 'MiniHipatternsFixme'),
      hack = require('mini.extra').gen_highlighter.words({ 'HACK', 'Hack', 'hack' }, 'MiniHipatternsHack'),
      todo = require('mini.extra').gen_highlighter.words({ 'TODO', 'Todo', 'todo' }, 'MiniHipatternsTodo'),
      note = require('mini.extra').gen_highlighter.words({ 'NOTE', 'Note', 'note' }, 'MiniHipatternsNote'),
      hex_color = require('mini.hipatterns').gen_highlighter.hex_color(),
    },
  }
end)
