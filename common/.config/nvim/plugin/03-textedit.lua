local later = VimRc.later

-- Step two ===================================================================

-- Extra 'mini.nvim' functionality.
--
-- See also:
-- - `:h MiniExtra.pickers` - pickers. Most are mapped in `<Leader>f` group.
--   Calling `setup()` makes 'mini.pick' respect 'mini.extra' pickers.
-- - `:h MiniExtra.gen_ai_spec` - 'mini.ai' textobject specifications
-- - `:h MiniExtra.gen_highlighter` - 'mini.hipatterns' highlighters
later(function()
  require('mini.extra').setup()
end)

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

-- require('mini.extra').setup()

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
later(function()
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
later(function()
  local miniclue = require 'mini.clue'
  -- stylua: ignore
  miniclue.setup({
    -- Define which clues to show. By default shows only clues for custom mappings
    -- (uses `desc` field from the mapping; takes precedence over custom clue).
    clues = {
      -- This is defined in 'plugin/20_keymaps.lua' with Leader group descriptions
      { mode = { 'n', 'x' }, keys = '<leader>c', desc = '+change' },
      { mode = { 'n', 'x' }, keys = '<leader>f', desc = '+find' },
      { mode = 'n', keys = '<leader>b', desc = '+buffers' },
      { mode = 'n', keys = '<leader>d', desc = '+diff' },
      { mode = 'n', keys = '<leader>x', desc = '+eXtra' },
      { mode = 'n', keys = '[', desc = '+prev' },
      { mode = 'n', keys = ']', desc = '+next' },
      miniclue.gen_clues.builtin_completion(),
      miniclue.gen_clues.g(),
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
      { mode = { 'n', 'x' }, keys = '"' },        -- Registers
      { mode =   'n',        keys = '<C-w>' },    -- Window commands
      { mode = { 'n', 'x' }, keys = 's' },        -- `s` key (mini.surround, etc.)
      { mode = { 'n', 'x' }, keys = 'z' },        -- `z` key
    },

  })
end)

-- Command line tweaks. Improves command line editing with:
-- - Autocompletion. Basically an automated `:h cmdline-completion`.
-- - Autocorrection of words as-you-type. Like `:W`->`:w`, `:lau`->`:lua`, etc.
-- - Autopeek command range (like line number at the start) as-you-type.
later(function()
  local mini_cmdline = require 'mini.cmdline'
  mini_cmdline.setup {

    -- Autocompletion: show `:h 'wildmenu'` as you type
    autocomplete = {
      enable = true,

      -- Delay (in ms) after which to trigger completion
      -- Neovim>=0.12 is recommended for positive values
      delay = 100,

      -- Custom rule of when to trigger completion
      -- predicate = nil,

      -- Whether to map arrow keys for more consistent wildmenu behavior
      map_arrows = true,
      predicate = mini_cmdline.default_autocomplete_predicate,
      -- predicate = function()
      --   return not block_compltype[vim.fn.getcmdcompltype()] -- MiniCmdline.default_autocomplete_predicate
      -- end,
    },

    -- Autocorrection: adjust non-existing words (commands, options, etc.)
    autocorrect = {
      enable = true,

      -- Custom autocorrection rule
      predicate = mini_cmdline.default_autocorrect_func,
    },

    -- Autopeek: show command's target range in a floating window
    autopeek = {
      enable = true,

      -- Number of lines to show above and below range lines
      n_context = 5,

      -- Custom rule of when to show peek window
      predicate = mini_cmdline.default_autopeek_predicate,

      -- Window options
      window = {

        -- Function to render statuscolumn
        statuscolumn = mini_cmdline.default_autopeek_statuscolumn,
      },
    },
  }
end)

later(function()
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
later(function()
  require('mini.align').setup()
end)
later(function()
  require('mini.bracketed').setup()
end)
later(function()
  require('mini.bufremove').setup()
  local bufremove_keys = {

    { '<leader>bb', '<cmd>b#<cr>', { desc = 'Switch to Other Buffer' } },
    {
      '<leader>bs',
      function()
        vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(true, true))
      end,
      { desc = 'Scratch Buffer' },
    },
    { '<leader>bd', '<Cmd>lua MiniBufremove.delete(0, true)<CR>', { desc = 'Delete!' } },
    { '<leader>bD', '<cmd>:%bdelete|edit #|normal`<cr>', { desc = 'Close all Other Buffers' } },
    { '<leader>bw', '<Cmd>lua MiniBufremove.wipeout()<CR>', { desc = 'Wipeout' } },
    { '<leader>bW', '<Cmd>lua MiniBufremove.wipeout(0, true)<CR>', { desc = 'Wipeout!' } },
  }
  for _, keymap in ipairs(bufremove_keys) do
    local lhs, rhs, opts = unpack(keymap)
    if type(lhs) == 'string' and (type(rhs) == 'string' or vim.is_callable(rhs)) and type(opts) == 'table' then
      vim.keymap.set('n', lhs, rhs, opts)
    end
  end
end)

later(function()
  require('mini.comment').setup()
end)
later(function()
  require('mini.indentscope').setup()
end)
later(function()
  require('mini.operators').setup { replace = { prefix = 'cr' } }
  vim.keymap.set('n', 'g(', 'gxiagxila', { remap = true, desc = 'Swap arg left' })
  vim.keymap.set('n', 'g)', 'gxiagxina', { remap = true, desc = 'Swap arg right' })
end)

later(function()
  require('mini.move').setup {
    mappings = {
      left = '<S-left>',
      right = '<S-right>',
      down = '<S-down>',
      up = '<S-up>',

      line_left = '<S-left>',
      line_right = '<S-right>',
      line_down = '<S-down>',
      line_up = '<S-up>',
    },
  }
end)

later(function()
  require('mini.jump').setup {

    -- Module mappings. Use `''` (empty string) to disable one.
    mappings = {
      forward = 'f',
      backward = 'F',
      forward_till = 't',
      backward_till = 'T',
      repeat_jump = ';',
    },

    -- Delay values (in ms) for different functionalities. Set any of them to
    -- a very big number (like 10^7) to virtually disable.
    delay = {
      -- Delay between jump and highlighting all possible jumps
      highlight = 250,

      -- Delay between jump and automatic stop if idle (no jump is done)
      idle_stop = 10000000,
    },

    -- Whether to disable showing non-error feedback
    -- This also affects (purely informational) helper messages shown after
    -- idle time if user input is required.
    silent = false,
  }
end)

later(function()
  require('mini.jump2d').setup {
    -- Function producing jump spots (byte indexed) for a particular line.
    -- For more information see |MiniJump2d.start()|.
    -- If `nil` (default) - use |MiniJump2d.default_spotter()|
    spotter = nil,

    -- Characters used for labels of jump spots (in supplied order)
    labels = 'abcdefghijklmnopqrstuvwxyz',

    -- Options for visual effects
    view = {
      -- Whether to dim lines with at least one jump spot
      dim = false,

      -- How many steps ahead to show. Set to big number to show all steps.
      n_steps_ahead = 5,
    },

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
    --
    -- -- Functions to be executed at certain events
    -- hooks = {
    --   before_start = nil, -- Before jump start
    --   after_jump = nil, -- After jump was actually done
    -- },

    -- Module mappings. Use `''` (empty string) to disable one.
    mappings = {
      start_jumping = '<CR>',
    },

    -- Whether to disable showing non-error feedback
    -- This also affects (purely informational) helper messages shown after
    -- idle time if user input is required.
    silent = false,
  }
end)
later(function()
  require('mini.keymap').setup()
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
later(function()
  require('mini.splitjoin').setup()
end)

-- Surround actions: add/delete/replace/find/highlight. Working with surroundings
-- is surprisingly common: surround word with quotes, replace `)` with `]`, etc.
-- This module comes with many built-in surroundings, each identified by a single
-- character. It searches only for surrounding that covers cursor and comes with
-- a special "next" / "last" versions of actions to search forward or backward
-- (just like 'mini.ai'). All text editing actions are dot-repeatable (see `:h .`).
--
-- Example usage (this may feel intimidating at first, but after practice it
-- becomes second nature during text editing):
-- - `saiw)` - *s*urround *a*dd for *i*nside *w*ord parenthesis (`)`)
-- - `sdf`   - *s*urround *d*elete *f*unction call (like `f(var)` -> `var`)
-- - `srb[`  - *s*urround *r*eplace *b*racket (any of [], (), {}) with padded `[`
-- - `sf*`   - *s*urround *f*ind right part of `*` pair (like bold in markdown)
-- - `shf`   - *s*urround *h*ighlight current *f*unction call
-- - `srn{{` - *s*urround *r*eplace *n*ext curly bracket `{` with padded `{`
-- - `sdl'`  - *s*urround *d*elete *l*ast quote pair (`'`)
-- - `vaWsa<Space>` - *v*isually select *a*round *W*ORD and *s*urround *a*dd
--                    spaces (`<Space>`)
--
-- See also:
-- - `:h MiniSurround-builtin-surroundings` - list of all supported surroundings
-- - `:h MiniSurround-surrounding-specification` - examples of custom surroundings
-- - `:h MiniSurround-vim-surround-config` - alternative set of action mappings
later(function()
  require('mini.surround').setup {
    mappings = {
      add = 'sa', -- Add surrounding in Normal and Visual modes
      delete = 'sd', -- Delete surrounding
      find = 'sf', -- Find surrounding (to the right)
      find_left = 'sF', -- Find surrounding (to the left)
      replace = 'sr', -- Replace surrounding
      update_n_lines = 'sn', -- Update `n_lines`
    },
  }
end)

-- Highlight and remove trailspace. Temporarily stops highlighting in Insert mode
-- to reduce noise when typing. Example usage:
-- - `<Leader>ot` - trim all trailing whitespace in a buffer
later(function()
  require('mini.trailspace').setup()
end)
