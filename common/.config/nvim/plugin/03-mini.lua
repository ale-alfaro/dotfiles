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
end)

VimRc.later(function()
  require('mini.visits').setup()
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

-- Show next key clues in a bottom right window. Requires explicit opt-in for
-- keys that act as clue trigger. Example usage:
-- - Press `<Leader>` and wait for 1 second. A window with information about
--   next available keys should appear.
-- - Press one of the listed keys. Window updates immediately to show information
--   about new next available keys. You can press `<BS>` to go back in key sequence.
-- - Press keys until they resolve into some mapping.
--
-- Note: it is designed to work in buffers for normal files. It doesn't work in
-- special buffers (like for 'mini.starter' or 'mini.files') to not conflict
-- with its local mappings.
--
-- See also:
-- - `:h MiniClue-examples` - examples of common setups
-- - `:h MiniClue.ensure_buf_triggers()` - use it to enable triggers in buffer
-- - `:h MiniClue.set_mapping_desc()` - change mapping description not from config
VimRc.later(function()
  local miniclue = require 'mini.clue'
  -- stylua: ignore
  miniclue.setup({
    -- Define which clues to show. By default shows only clues for custom mappings
    -- (uses `desc` field from the mapping; takes precedence over custom clue).
    clues = {
      -- This is defined in 'plugin/20_keymaps.lua' with Leader group descriptions
      VimRc.keymap_clues,
      miniclue.gen_clues.builtin_completion(),
      miniclue.gen_clues.g(),
      miniclue.gen_clues.marks(),
      miniclue.gen_clues.registers(),
      miniclue.gen_clues.square_brackets(),
      -- This creates a submode for window resize mappings. Try the following:
      -- - Press `<C-w>s` to make a window split.
      -- - Press `<C-w>+` to increase height. Clue window still shows clues as if
      --   `<C-w>` is pressed again. Keep pressing just `+` to increase height.
      --   Try pressing `-` to decrease height.
      -- - Stop submode either by `<Esc>` or by any key that is not in submode.
      miniclue.gen_clues.windows({ submode_resize = true }),
      miniclue.gen_clues.z(),
    },
    -- Explicitly opt-in for set of common keys to trigger clue window
    triggers = {
      { mode = { 'n', 'x' }, keys = '<Leader>' }, -- Leader triggers
      { mode =   'n',        keys = '\\' },       -- mini.basics
      { mode = { 'n', 'x' }, keys = '[' },        -- mini.bracketed
      { mode = { 'n', 'x' }, keys = ']' },
      { mode =   'i',        keys = '<C-x>' },    -- Built-in completion
      { mode = { 'n', 'x' }, keys = 'g' },        -- `g` key
      { mode = { 'n', 'x' }, keys = 'q' },        -- `g` key
      { mode = { 'n', 'x' }, keys = "'" },        -- Marks
      { mode = { 'n', 'x' }, keys = '`' },
      { mode = { 'n', 'x' }, keys = '"' },        -- Registers
      { mode = { 'i', 'c' }, keys = '<C-r>' },
      { mode =   'n',        keys = '<C-w>' },    -- Window commands
      { mode = { 'n', 'x' }, keys = 's' },        -- `s` key (mini.surround, etc.)
      { mode = { 'n', 'x' }, keys = 'z' },        -- `z` key
    },

  })
end)
---@class CmdLineState
---@field line string vim.fn.getcmdline
---@field pos string vim.fn.getcmdpos
---@field prev_line string vim.fn.getcmdline
---@field prev_pos string vim.fn.getcmdpos
---
---@class CmdLineInfo
---@field complpat string  vim.fn.getcmdcomplpat completion pattern
---@field compltype string vim.fn.getcmdcompltype completion type

local block_compltype = { 'shellcmd' }
-- Command line tweaks. Improves command line editing with:
-- - Autocompletion. Basically an automated `:h cmdline-completion`.
-- - Autocorrection of words as-you-type. Like `:W`->`:w`, `:lau`->`:lua`, etc.
-- - Autopeek command range (like line number at the start) as-you-type.
VimRc.later(function()
  require('mini.cmdline').setup {
    autocomplete = {
      delay = 1000,
      ---@param state CmdLineState
      predicate = function(state, _opts)
        return (state.line:find '%a' ~= nil) and not block_compltype[vim.fn.getcmdcompltype()]
      end,
    },
    autocorrect = {},
  }
end)

VimRc.later(function()
  require('mini.misc').setup()
  MiniMisc.setup_auto_root { '.west', '.nvim', '.git' }
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
if not vim.o.diff then
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
    vim.keymap.set('n', 'o', '<nop>')
    require('mini.operators').setup { replace = { prefix = '' } }

    vim.keymap.set('n', 'g(', 'gxiagxila', { remap = true, desc = 'Swap arg left' })
    vim.keymap.set('n', 'g)', 'gxiagxina', { remap = true, desc = 'Swap arg right' })
  end)

  VimRc.later(function()
    require('mini.move').setup {
      mappings = {
        left = '<M-left>',
        right = '<M-right>',
        down = '<M-down>',
        up = '<M-up>',

        line_left = '<M-left>',
        line_right = '<M-right>',
        line_down = '<M-down>',
        line_up = '<M-up>',
      },
    }
  end)

  VimRc.later(function()
    require('mini.jump').setup()
  end)

  VimRc.later(function()
    -- Custom mapping
    vim.keymap.set({ 'n', 'i', 'x' }, 'J', '<Cmd>lua MiniJump2d.start(MiniJump2d.builtin_opts.line_start)<CR>')

    -- Inside `MiniJump2d.setup()` (make sure to use all defined options)
    local jump2d = require 'mini.jump2d'
    local jump_line_start = jump2d.builtin_opts.line_start
    jump2d.setup {
      spotter = jump_line_start.spotter,
      hooks = { after_jump = jump_line_start.hooks.after_jump },

      -- Which lines are used for computing spots
      allowed_lines = {
        blank = false, -- Blank line (not sent to spotter even if `true`)
        cursor_before = false, -- Lines before cursor line
        cursor_at = true, -- Cursor line
        cursor_after = true, -- Lines after cursor line
        fold = false, -- Start of fold (not sent to spotter even if `true`)
      },

      -- Which windows from current tabpage are used for visible lines
      allowed_windows = {
        current = true,
        not_current = false,
      },
    }
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
end
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
  local surround = require 'mini.surround'
  local ts_input = surround.gen_spec.input.treesitter
  surround.setup {
    custom_surroundings = {
      f = {
        input = ts_input({ outer = '@call.outer', inner = '@calll.inner' }, { use_nvim_treesitter = true }),
      },
    },
  }
end)

-- Highlight and remove trailspace. Temporarily stops highlighting in Insert mode
-- to reduce noise when typing. Example usage:
-- - `<Leader>ot` - trim all trailing whitespace in a buffer
VimRc.later(function()
  require('mini.trailspace').setup()
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
