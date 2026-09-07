require('trouble').setup {
  focus = true, -- Focus the window when opened
  -- Key mappings can be set to the name of a builtin action,
  -- or you can define your own custom action.
  ---@type table<string, trouble.Action.spec|false>
  keys = {
    ['?'] = 'help',
    ['<localleader>r'] = 'refresh',
    ['<localleader>R'] = 'toggle_refresh',
    q = 'close',
    o = 'jump_close',
    ['<esc>'] = 'cancel',
    ['<cr>'] = 'jump_close',
    ['<c-s>'] = 'jump_split',
    ['<c-v>'] = 'jump_vsplit',
    -- go down to next item (accepts count)
    -- j = "next",
    ['}'] = 'next',
    [']]'] = 'next',
    -- go up to prev item (accepts count)
    -- k = "prev",
    ['{'] = 'prev',
    ['[['] = 'prev',
    dd = 'delete',
    d = { action = 'delete', mode = 'v' },
    ['<localleader>i'] = 'inspect',
    p = 'preview',
    P = 'toggle_preview',
    zo = 'fold_open',
    zO = 'fold_open_recursive',
    zc = 'fold_close',
    zC = 'fold_close_recursive',
    za = 'fold_toggle',
    zA = 'fold_toggle_recursive',
    zm = 'fold_more',
    zM = 'fold_close_all',
    zr = 'fold_reduce',
    zR = 'fold_open_all',
    zx = 'fold_update',
    zX = 'fold_update_all',
    zn = 'fold_disable',
    zN = 'fold_enable',
    zi = 'fold_toggle_enable',
    ['<localleader>b'] = { -- example of a custom action that toggles the active view filter
      action = function(view)
        view:filter({ buf = 0 }, { toggle = true })
      end,
      desc = 'Toggle Current Buffer Filter',
    },
    ['<localleader>s'] = { -- example of a custom action that toggles the severity
      action = function(view)
        local f = view:get_filter 'severity'
        local severity = ((f and f.filter.severity or 0) + 1) % 5
        view:filter({ severity = severity }, {
          id = 'severity',
          template = '{hl:Title}Filter:{hl} {severity}',
          del = severity == 0,
        })
      end,
      desc = 'Toggle Severity Filter',
    },
  },
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
      '<localleader>r',
      "<cmd>lua require('quicker').refresh()<CR>",
      desc = 'Refresh quickfix content',
    },
  },
}
