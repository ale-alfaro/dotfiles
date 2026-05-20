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
  keys = {
    { '>', "<cmd>lua require('quicker').expand()<CR>", desc = 'Expand quickfix content' },
    { '<', "<cmd>lua require('quicker').collapse()<CR>", desc = 'Collapse quickfix content' },
    {
      '<localleader>-',
      function()
        require('quicker').expand { after = 0, before = 3, add_to_existing = true }
      end,
      desc = 'Expand/Collapse quickfix content toggle',
    },
    {
      '<localleader>+',
      function()
        require('quicker').expand { after = 3, before = 0, add_to_existing = true }
      end,
      desc = 'Expand/Collapse quickfix content toggle',
    },
    {
      '<localleader>r',
      require('quicker').refresh,
      desc = 'Refresh quickfix content',
    },
  },
}
