-- Common configuration presets. Example usage:
-- - `<C-s>` in Insert mode - save and go to Normal mode
-- - `go` / `gO` - insert empty line before/after in Normal mode
-- - `gy` / `gp` - copy / paste from system clipboard
-- - `\` + key - toggle common options. Like `\h` toggles highlighting search.
-- - `<C-hjkl>` (four combos) - navigate between windows.
require('mini.basics').setup {
  -- Options. Set field to `false` to disable.
  options = {
    -- Basic options ('number', 'ignorecase', and many more)
    basic = true,

    -- Extra UI features ('winblend', 'listchars', 'pumheight', ...)
    extra_ui = true,

    -- Presets for window borders ('single', 'double', ...)
    -- Default 'auto' infers from 'winborder' option
    win_borders = 'auto',
  },
  mappings = {

    -- Basic mappings (better 'jk', save with Ctrl+S, ...)
    basic = true,

    -- Prefix for mappings that toggle common options ('wrap', 'spell', ...).
    -- Supply empty string to not create these mappings.
    option_toggle_prefix = '',
    -- Create `<C-hjkl>` mappings for window navigation
    windows = true,
    -- Create `<M-hjkl>` mappings for navigation in Insert and Command modes
    move_with_alt = false,
  },

  autocommands = {
    -- Basic autocommands (highlight on yank, start Insert in terminal, ...)
    basic = true,

    -- Set 'relativenumber' only in linewise and blockwise Visual mode
    relnum_in_visual_mode = false,
  },
}

-- Miscellaneous small but useful functions. Example usage:
-- - `<Leader>oz` - toggle between "zoomed" and regular view of current buffer
-- - `<Leader>or` - resize window to its "editable width"
-- - `:lua put_text(vim.lsp.get_clients())` - put output of a function below
--   cursor in current buffer. Useful for a detailed exploration.
-- - `:lua put(MiniMisc.stat_summary(MiniMisc.bench_time(f, 100)))` - run
--   function `f` 100 times and report statistical summary of execution times
--
-- Uses `now()` for `setup_xxx()` to work when started like `nvim -- path/to/file`
-- Makes `:h MiniMisc.put()` and `:h MiniMisc.put_text()` public
local ok, misc = pcall(require, 'mini.misc')
if ok then
  misc.setup()
  -- Change current working directory based on the current file path. It
  -- searches up the file tree until the first root marker ('.git' or 'Makefile')
  -- and sets their parent directory as a current directory.
  -- This is helpful when simultaneously dealing with files from several projects.

  -- Restore latest cursor position on file open
  misc.setup_restore_cursor()

  -- Synchronize terminal emulator background with Neovim's background to remove
  -- possibly different color padding around Neovim instance
  misc.setup_termbg_sync()
end

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

local gen_ai_spec = require('mini.extra').gen_ai_spec

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
-- }

local spec_treesitter = require('mini.ai').gen_spec.treesitter
local spec_user_prompt = require('mini.ai').gen_spec.user_prompt
local spec_pair = require('mini.ai').gen_spec.pair
local spec_func = require('mini.ai').gen_spec.function_call
require('mini.ai').setup {
  custom_textobjects = {
    B = gen_ai_spec.buffer(),
    D = gen_ai_spec.diagnostic(),
    I = gen_ai_spec.indent(),
    L = gen_ai_spec.line(),
    N = gen_ai_spec.number(),
    F = spec_treesitter { a = '@function.outer', i = '@function.inner' },
    o = spec_treesitter {
      a = { '@conditional.outer', '@loop.outer' },
      i = { '@conditional.inner', '@loop.inner' },
    },
    f = spec_func { name_pattern = '[%w_%.%>%<]' },
    p = spec_user_prompt(),
    ['|'] = spec_pair('|', '|', { type = 'non-balanced' }),
  },
}

-- Align text interactively. Example usage:
-- - `gaip,` - `ga` (align operator) *i*nside *p*aragraph by comma
-- - `gAip` - start interactive alignment on the paragraph. Choose how to
--   split, justify, and merge string parts. Press `<CR>` to make it permanent,
--   press `<Esc>` to go back to initial state.
--
-- See also:
-- - `:h MiniAlign-example` - hands-on list of examples to practice aligning
-- - `:h MiniAlign.gen_step` - list of support step customizations
-- - `:h MiniAlign-algorithm` - how alignment is done on algorithmic level
require('mini.align').setup()

-- Animate common Neovim actions. Like cursor movement, scroll, window resize,
-- window open, window close. Animations are done based on Neovim events and
-- don't require custom mappings.
--
-- It is not enabled by default because its effects are a matter of taste.
-- Also scroll and resize have some unwanted side effects (see `:h mini.animate`).
-- Uncomment next line (use `gcc`) to enable.
-- later(function() require('mini.animate').setup() end)

-- Go forward/backward with square brackets. Implements consistent sets of mappings
-- for selected targets (like buffers, diagnostic, quickfix list entries, etc.).
-- Example usage:
-- - `]b` - go to next buffer
-- - `[j` - go to previous jump inside current buffer
-- - `[Q` - go to first entry of quickfix list
-- - `]X` - go to last conflict marker in a buffer
--
-- See also:
-- - `:h MiniBracketed` - overall mapping design and list of targets
require('mini.bracketed').setup()

-- Remove buffers. Opened files occupy space in tabline and buffer picker.
-- When not needed, they can be removed. Example usage:
-- - `<Leader>bw` - completely wipeout current buffer (see `:h :bwipeout`)
-- - `<Leader>bW` - completely wipeout current buffer even if it has changes
-- - `<Leader>bd` - delete current buffer (see `:h :bdelete`)
require('mini.bufremove').setup()
KEYS.define {

  { lhs = '<leader>bb', rhs = '<cmd>b#<cr>', opts = { desc = 'Switch to Other Buffer' } },
  {
    lhs = '<leader>bs',
    rhs = function()
      vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(true, true))
    end,
    opts = { desc = 'Scratch Buffer' },
  },
  { lhs = '<leader>bd', rhs = '<Cmd>lua MiniBufremove.delete(0, true)<CR>', opts = { desc = 'Delete!' } },
  { lhs = '<leader>bD', rhs = '<cmd>:%bdelete|edit #|normal`<cr>', opts = { desc = 'Close all Other Buffers' } },
  { lhs = '<leader>bw', rhs = '<Cmd>lua MiniBufremove.wipeout()<CR>', opts = { desc = 'Wipeout' } },
  { lhs = '<leader>bW', rhs = '<Cmd>lua MiniBufremove.wipeout(0, true)<CR>', opts = { desc = 'Wipeout!' } },
}

-- Comment lines. Provides functionality to work with commented lines.
-- Uses `:h 'commentstring'` option to infer comment structure.
-- Example usage:
-- - `gcip` - toggle comment (`gc`) *i*inside *p*aragraph
-- - `vapgc` - *v*isually select *a*round *p*aragraph and toggle comment (`gc`)
-- - `gcgc` - uncomment (`gc`, operator) comment block at cursor (`gc`, textobject)
--
-- The built-in `:h commenting` is based on 'mini.comment'. Yet this module is
-- still enabled as it provides more customization opportunities.
require('mini.comment').setup()

-- Visualize and work with indent scope. It visualizes indent scope "at cursor"
-- with animated vertical line. Provides relevant motions and textobjects.
-- Example usage:
-- - `cii` - *c*hange *i*nside *i*ndent scope
-- - `Vaiai` - *V*isually select *a*round *i*ndent scope and then again
--   reselect *a*round new *i*indent scope
-- - `[i` / `]i` - navigate to scope's top / bottom
--
-- See also:
-- - `:h MiniIndentscope.gen_animation` - available animation rules
require('mini.indentscope').setup()

require('mini.keymap').setup()
-- Navigate 'mini.completion' menu with `<Tab>` /  `<S-Tab>`
MiniKeymap.map_multistep('i', '<Tab>', { 'pmenu_next' })
MiniKeymap.map_multistep('i', '<S-Tab>', { 'pmenu_prev' })
-- On `<CR>` try to accept current completion item, fall back to accounting
-- Move any selection in any direction. Example usage in Normal mode:
-- - `<M-j>`/`<M-k>` - move current line down / up
-- - `<M-h>`/`<M-l>` - decrease / increase indent of current line
--
-- Example usage in Visual mode:
-- - `<M-h>`/`<M-j>`/`<M-k>`/`<M-l>` - move selection left/down/up/right
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
    dim = true,

    -- How many steps ahead to show. Set to big number to show all steps.
    n_steps_ahead = 5,
  },

  -- Which lines are used for computing spots
  allowed_lines = {
    blank = false, -- Blank line (not sent to spotter even if `true`)
    cursor_before = true, -- Lines before cursor line
    cursor_at = true, -- Cursor line
    cursor_after = true, -- Lines after cursor line
    fold = false, -- Start of fold (not sent to spotter even if `true`)
  },

  -- Which windows from current tabpage are used for visible lines
  -- allowed_windows = {
  --   current = true,
  --   not_current = true,
  -- },
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
vim.api.nvim_create_user_command('JumpC', function()
  MiniJump2d.start(MiniJump2d.builtin_opts.single_character)
end, { desc = 'Jump to single char' })
vim.api.nvim_create_user_command('JumpW', function()
  MiniJump2d.start(MiniJump2d.builtin_opts.word_start)
end, { desc = 'Jump to Word Start' })

vim.api.nvim_create_user_command('JumpL', function()
  MiniJump2d.start(MiniJump2d.builtin_opts.line_start)
end, { desc = 'Jump to Line Start' })
vim.api.nvim_create_user_command('JumpQ', function()
  MiniJump2d.start(MiniJump2d.builtin_opts.query)
end, { desc = 'Jump to Query' })
-- Text edit operators. All operators have mappings for:
-- - Regular operator (waits for motion/textobject to use)
-- - Current line action (repeat second character of operator to activate)
-- - Act on visual selection (type operator in Visual mode)
--
-- Example usage:
-- - `griw` - replace (`gr`) *i*inside *w*ord
-- - `gmm` - multiple/duplicate (`gm`) current line (extra `m`)
-- - `vipgs` - *v*isually select *i*nside *p*aragraph and sort it (`gs`)
-- - `gxiww.` - exchange (`gx`) *i*nside *w*ord with next word (`w` to navigate
--   to it and `.` to repeat exchange operator)
-- - `g==` - execute current line as Lua code and replace with its output.
--   For example, typing `g==` over line `vim.lsp.get_clients()` shows
--   information about all available LSP clients.
--
-- See also:
-- - `:h MiniOperators-mappings` - overview of how mappings are created
-- - `:h MiniOperators-overview` - overview of present operators
require('mini.operators').setup { replace = { prefix = 'cr' } }

-- Create mappings for swapping adjacent arguments. Notes:
-- - Relies on `a` argument textobject from 'mini.ai'.
-- - It is not 100% reliable, but mostly works.
-- - It overrides `:h (` and `:h )`.
-- Explanation: `gx`-`ia`-`gx`-`ila` <=> exchange current and last argument
-- Usage: when on `a` in `(aa, bb)` press `)` followed by `(`.
KEYS.define {
  { lhs = '(', rhs = 'gxiagxila', opts = { remap = true, desc = 'Swap arg left' } },
  { lhs = ')', rhs = 'gxiagxina', opts = { remap = true, desc = 'Swap arg right' } },
}
-- Autopairs functionality. Insert pair when typing opening character and go over
-- right character if it is already to cursor's right. Also provides mappings for
-- `<CR>` and `<BS>` to perform extra actions when inside pair.
-- Example usage in Insert mode:
-- - `(` - insert "()" and put cursor between them
-- - `)` when there is ")" to the right - jump over ")" without inserting new one
-- - `<C-v>(` - always insert a single "(" literally. This is useful since
--   'mini.pairs' doesn't provide particularly smart behavior, like auto balancing
-- Create pairs not only in Insert, but also in Command line mode

-- require('mini.pairs').setup {
--   modes = { insert = true, command = true, terminal = false },
-- }

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
require('mini.splitjoin').setup()

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
require('mini.surround').setup {
  mappings = {
    add = 'gsa', -- Add surrounding in Normal and Visual modes
    delete = 'gsd', -- Delete surrounding
    find = 'gsf', -- Find surrounding (to the right)
    find_left = 'gsF', -- Find surrounding (to the left)
    highlight = 'gsh', -- Highlight surrounding
    replace = 'gsr', -- Replace surrounding
    update_n_lines = 'gsn', -- Update `n_lines`
  },
}

-- Completion and signature help. Implements async "two stage" autocompletion:
-- - Based on attached LSP servers that support completion.
-- - Fallback (based on built-in keyword completion) if there is no LSP candidates.
--
-- Example usage in Insert mode with attached LSP:
-- - Start typing text that should be recognized by LSP (like variable name).
-- - After 100ms a popup menu with candidates appears.
-- - Press `<Tab>` / `<S-Tab>` to navigate down/up the list. These are set up
--   in 'mini.keymap'. You can also use `<C-n>` / `<C-p>`.
-- - During navigation there is an info window to the right showing extra info
--   that the LSP server can provide about the candidate. It appears after the
--   candidate stays selected for 100ms. Use `<C-f>` / `<C-b>` to scroll it.
-- - Navigating to an entry also changes buffer text. If you are happy with it,
--   keep typing after it. To discard completion completely, press `<C-e>`.
-- - After pressing special trigger(s), usually `(`, a window appears that shows
--   the signature of the current function/method. It gets updated as you type
--   showing the currently active parameter.
--
-- Example usage in Insert mode without an attached LSP or in places not
-- supported by the LSP (like comments):
-- - Start typing a word that is present in current or opened buffers.
-- - After 100ms popup menu with candidates appears.
-- - Navigate with `<Tab>` / `<S-Tab>` or `<C-n>` / `<C-p>`. This also updates
--   buffer text. If happy with choice, keep typing. Stop with `<C-e>`.
--
-- It also works with snippet candidates provided by LSP server. Best experience
-- when paired with 'mini.snippets' (which is set up in this file).
-- Customize post-processing of LSP responses for a better user experience.
-- Don't show 'Text' suggestions (usually noisy) and show snippets last.
local process_items_opts = { kind_priority = { Text = -1, Snippet = 99 } }
local process_items = function(items, base)
  return MiniCompletion.default_process_items(items, base, process_items_opts)
end
require('mini.completion').setup {
  lsp_completion = {
    -- Without this config autocompletion is set up through `:h 'completefunc'`.
    -- Although not needed, setting up through `:h 'omnifunc'` is cleaner
    -- (sets up only when needed) and makes it possible to use `<C-u>`.
    source_func = 'omnifunc',
    auto_setup = false,
    process_items = process_items,
  },
}

-- Set 'omnifunc' for LSP completion only when needed.
local on_attach = function(ev)
  vim.bo[ev.buf].omnifunc = 'v:lua.MiniCompletion.completefunc_lsp'
end
vim.api.nvim_create_autocmd('LspAttach', { pattern = nil, callback = on_attach, desc = "Set 'omnifunc'" })
-- Advertise to servers that Neovim now supports certain set of completion and
-- signature features through 'mini.completion'.
-- Highlight and remove trailspace. Temporarily stops highlighting in Insert mode
-- to reduce noise when typing. Example usage:
-- - `<Leader>ot` - trim all trailing whitespace in a buffer
require('mini.trailspace').setup()

local rhs = function()
  MiniSnippets.expand { match = false }
end
vim.keymap.set('i', '<C-Space>', rhs, { desc = 'Expand all' })
