require 'plugin.treesitter'
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

local block_compltype = { shellcmd = true }

local mini_cmdline = require 'mini.cmdline'
-- mini_cmdline.setup()
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
    -- predicate = function()
    --   return not block_compltype[vim.fn.getcmdcompltype()] -- MiniCmdline.default_autocomplete_predicate
    -- end,
  },

  -- Autocorrection: adjust non-existing words (commands, options, etc.)
  autocorrect = {
    enable = true,

    -- Custom autocorrection rule
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
      statuscolumn = function(data)
        local n, l, r = vim.v.lnum, data.left, data.right
        local s = n == l and (n == r and '* ' or '< ') or n == r and '> ' or ''
        -- Needs explicit highlighting via `:h 'statusline'` syntax
        return '%#MiniCmdlinePeekSign#' .. s
      end,
    },
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

require('mini.snippets').setup()
local rhs = function()
  MiniSnippets.expand { match = false }
end
vim.keymap.set('i', '<C-Space>', rhs, { desc = 'Expand all' })
require 'plugin.mini-etc'
