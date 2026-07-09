require('trouble').setup {
  focus = true, -- Focus the window when opened
  modes = {
    symbols = {
      ---@class trouble.Window.split
      win = { type = 'split', position = 'right', size = { width = 0.5, height = 0.0 } },
    },
  },
}

local config = require 'fzf-lua.config'
local actions = require('trouble.sources.fzf').actions
config.defaults.actions.files['ctrl-t'] = actions.open
require('quicker').setup {
  highlight = {
    -- Use treesitter highlighting
    treesitter = true,
    -- Use LSP semantic token highlighting
    lsp = true,
    -- Load the referenced buffers to apply more accurate highlights (may be slow)
    load_buffers = true,
  },
  follow = {
    -- When quickfix window is open, scroll to closest item to the cursor
    enabled = true,
  },
  -- How to trim the leading whitespace from results. Can be 'all', 'common', or false
  trim_leading_whitespace = 'all',
  -- Maximum width of the filename column
  max_filename_width = function()
    return math.floor(math.min(50, vim.o.columns / 3))
  end,
  -- How far the header should extend to the right
  header_length = function(type, start_col)
    return vim.o.columns - start_col
  end,
  keys = {
    { '>', "<cmd>lua require('quicker').expand()<CR>", desc = 'Expand quickfix content' },
    { '<', "<cmd>lua require('quicker').collapse()<CR>", desc = 'Collapse quickfix content' },
    {
      '-',
      "<Cmd>lua require('quicker').expand { after = 0, before = 3, add_to_existing = true }<CR>",
      desc = 'Expand/Collapse quickfix content toggle',
    },
    {
      '+',
      "<Cmd>lua require('quicker').expand { after = 3, before = -, add_to_existing = true }<CR>",
      desc = 'Expand/Collapse quickfix content toggle',
    },
    {
      '<leader>r',
      "<cmd>lua require('quicker').refresh()<CR>",
      desc = 'Refresh quickfix content',
    },
  },
}
