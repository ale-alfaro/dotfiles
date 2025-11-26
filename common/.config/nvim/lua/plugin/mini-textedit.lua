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

require('mini.extra').setup()

local function mini_ai_buffer(ai_type)
  local start_line, end_line = 1, vim.fn.line '$'
  if ai_type == 'i' then
    -- Skip first and last blank lines for `i` textobject
    local first_nonblank, last_nonblank = vim.fn.nextnonblank(start_line), vim.fn.prevnonblank(end_line)
    -- Do nothing for buffer with all blanks
    if first_nonblank == 0 or last_nonblank == 0 then
      return { from = { line = start_line, col = 1 } }
    end
    start_line, end_line = first_nonblank, last_nonblank
  end

  local to_col = math.max(vim.fn.getline(end_line):len(), 1)
  return { from = { line = start_line, col = 1 }, to = { line = end_line, col = to_col } }
end
local gen_ai_spec = require('mini.extra').gen_ai_spec
local ai = require 'mini.ai'
local mini_ai_opts = {
  n_lines = 500,
  custom_textobjects = {

    -- Make `aB` / `iB` act on around/inside whole *b*uffer
    B = gen_ai_spec.buffer(),

    o = ai.gen_spec.treesitter { -- code block
      a = { '@block.outer', '@conditional.outer', '@loop.outer' },
      i = { '@block.inner', '@conditional.inner', '@loop.inner' },
    },
    -- For more complicated textobjects that require structural awareness,
    -- use tree-sitter. This example makes `aF`/`iF` mean around/inside function
    -- definition (not call). See `:h MiniAi.gen_spec.treesitter()` for details.
    F = ai.gen_spec.treesitter { a = '@function.outer', i = '@function.inner' },
    c = ai.gen_spec.treesitter { a = '@class.outer', i = '@class.inner' }, -- class
    t = { '<([%p%w]-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' }, -- tags
    d = { '%f[%d]%d+' }, -- digits
    e = { -- Word with case
      { '%u[%l%d]+%f[^%l%d]', '%f[%S][%l%d]+%f[^%l%d]', '%f[%P][%l%d]+%f[^%l%d]', '^[%l%d]+%f[^%l%d]' },
      '^().*()$',
    },
    g = mini_ai_buffer, -- buffer
    U = ai.gen_spec.function_call { name_pattern = '[%w_]' }, -- without dot in function name
  },
  -- 'mini.ai' by default mostly mimics built-in search behavior: first try
  -- to find textobject covering cursor, then try to find to the right.
  -- Although this works in most cases, some are confusing. It is more robust to
  -- always try to search only covering textobject and explicitly ask to search
  -- for next (`an`/`in`) or last (`an`/`il`).
  -- Try this. If you don't like it - delete next line and this comment.
  search_method = 'cover_or_nearest',
}
ai.setup(mini_ai_opts)
local objects = {
  { ' ', desc = 'whitespace' },
  { '"', desc = '" string' },
  { "'", desc = "' string" },
  { '(', desc = '() block' },
  { ')', desc = '() block with ws' },
  { '<', desc = '<> block' },
  { '>', desc = '<> block with ws' },
  { '?', desc = 'user prompt' },
  { 'U', desc = 'use/call without dot' },
  { '[', desc = '[] block' },
  { ']', desc = '[] block with ws' },
  { '_', desc = 'underscore' },
  { '`', desc = '` string' },
  { 'a', desc = 'argument' },
  { 'b', desc = ')]} block' },
  { 'c', desc = 'class' },
  { 'd', desc = 'digit(s)' },
  { 'e', desc = 'CamelCase / snake_case' },
  { 'f', desc = 'function' },
  { 'g', desc = 'entire file' },
  { 'i', desc = 'indent' },
  { 'o', desc = 'block, conditional, loop' },
  { 'q', desc = 'quote `"\'' },
  { 't', desc = 'tag' },
  { 'u', desc = 'use/call' },
  { '{', desc = '{} block' },
  { '}', desc = '{} with ws' },
}

local ret = { mode = { 'o', 'x' } }
local mappings = {
  around = 'a',
  inside = 'i',
  around_next = 'an',
  inside_next = 'in',
  around_last = 'al',
  inside_last = 'il',
}
mappings.goto_left = nil
mappings.goto_right = nil

for name, prefix in pairs(mappings) do
  name = name:gsub('^around_', ''):gsub('^inside_', '')
  ret[#ret + 1] = { prefix, group = name }
  for _, obj in ipairs(objects) do
    local desc = obj.desc
    if prefix:sub(1, 1) == 'i' then
      desc = desc:gsub(' with ws', '')
    end
    ret[#ret + 1] = { prefix .. obj[1], desc = obj.desc }
  end
end
require('which-key').add(ret, { notify = false })

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
_G.keymaps_define {
  { lhs = '<leader>bd', rhs = '<Cmd>lua MiniBufremove.delete()<CR>', opts = { desc = 'Delete' } },
  { lhs = '<leader>bD', rhs = '<Cmd>lua MiniBufremove.delete(0, true)<CR>', opts = { desc = 'Delete!' } },
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

-- Move any selection in any direction. Example usage in Normal mode:
-- - `<M-j>`/`<M-k>` - move current line down / up
-- - `<M-h>`/`<M-l>` - decrease / increase indent of current line
--
-- Example usage in Visual mode:
-- - `<M-h>`/`<M-j>`/`<M-k>`/`<M-l>` - move selection left/down/up/right
require('mini.move').setup()

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
_G.keymaps_define {
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

require('mini.pairs').setup {
  modes = { insert = true, command = true, terminal = false },
}

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

-- Highlight and remove trailspace. Temporarily stops highlighting in Insert mode
-- to reduce noise when typing. Example usage:
-- - `<Leader>ot` - trim all trailing whitespace in a buffer
require('mini.trailspace').setup()
