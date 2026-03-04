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

--[[
--
  CompletionItemKind = {
    Text = 1,
    Method = 2,
    Function = 3,
    Constructor = 4,
    Field = 5,
    Variable = 6,
    Class = 7,
    Interface = 8,
    Module = 9,
    Property = 10,
    Unit = 11,
    Value = 12,
    Enum = 13,
    Keyword = 14,
    Snippet = 15,
    Color = 16,
    File = 17,
    Reference = 18,
    Folder = 19,
    EnumMember = 20,
    Constant = 21,
    Struct = 22,
    Event = 23,
    Operator = 24,
    TypeParameter = 25,
  },

]]
--
local process_items_opts = { kind_priority = { Text = -1, Color = 99, File = 99, Folder = 99 } }
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

  mappings = {
    -- Force two-step/fallback completions
    force_twostep = '<C-Space>',
    force_fallback = '<A-Space>',

    -- Scroll info/signature window down/up. When overriding, check for
    -- conflicts with built-in keys for popup menu (like `<C-u>`/`<C-o>`
    -- for 'completefunc'/'omnifunc' source function; or `<C-n>`/`<C-p>`).
    scroll_down = '<C-f>',
    scroll_up = '<C-b>',
  },
}

local snippets = require 'mini.snippets'
local match_strict = function(snips)
  return snippets.default_match(snips, { pattern_fuzzy = '%S' })
end
snippets.setup {
  mappings = { expand = '', jump_next = '', jump_prev = '' },
  expand = { match = match_strict },
}

local expand_or_jump = function()
  local can_expand = #MiniSnippets.expand { insert = false } > 0
  if can_expand then
    vim.schedule(MiniSnippets.expand)
    return ''
  end
  local is_active = MiniSnippets.session.get() ~= nil
  if is_active then
    MiniSnippets.session.jump 'next'
    return ''
  end
  return '\t'
end
local jump_prev = function()
  MiniSnippets.session.jump 'prev'
end
vim.keymap.set('i', '<Tab>', expand_or_jump, { expr = true })
vim.keymap.set('i', '<S-Tab>', jump_prev)
vim.keymap.set('i', '<C-Space>', function()
  MiniSnippets.expand { match = false }
end, { desc = 'Expand all' })

-- Stop session immediately after jumping to final tabstop
local fin_stop = function(args)
  if args.data.tabstop_to == '0' then
    MiniSnippets.session.stop()
  end
end
vim.api.nvim_create_autocmd('User', { pattern = 'MiniSnippetsSessionJump', callback = fin_stop })
-- # Stop all sessions on Normal mode exit ~
-- Use |ModeChanged| and |MiniSnippets-events| events: >lua

local make_stop = function()
  vim.api.nvim_create_autocmd('ModeChanged', {
    pattern = '*:n',
    once = true,
    callback = function()
      while MiniSnippets.session.get() do
        MiniSnippets.session.stop()
      end
    end,
  })
end
vim.api.nvim_create_autocmd('User', { pattern = 'MiniSnippetsSessionStart', callback = make_stop })

require 'extras.mini-etc'
