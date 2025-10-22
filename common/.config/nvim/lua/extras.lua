vim.pack.add(_G.plug_spec {
  'folke/flash.nvim',
  'folke/trouble.nvim',
})

-- Flash
--
require('flash').setup {
  jump = { nohlsearch = true },
  prompt = {
    win_config = {
      border = 'none',
      -- Place the prompt above the statusline.
      row = -3,
    },
  },
  search = {
    exclude = {
      'flash_prompt',
      'qf',
      function(win)
        -- Non-focusable windows.
        return not vim.api.nvim_win_get_config(win).focusable
      end,
    },
  },
  modes = {
    -- Enable flash when searching with ? or /
    search = { enabled = false },
  },
}
-- stylua: ignore start
_G.keymaps_define({
  { mode = {'n' ,'o', 'x'}, lhs = 'S', rhs = function() require('flash').treesitter() end, { desc = 'Flash Treesitter' }},
  { mode = 'o', lhs = 'r', rhs = function() require('flash').treesitter_search()end, { desc = 'Treesitter Search' }},
  { mode = 'o', lhs = 'R', rhs = function()require('flash').remote() end, { desc = 'Remote Flash' }},
  { mode = 'c',  lhs = '<c-s>', rhs = function() require('flash').toggle()end , { desc = 'Flash Toggle' }},
  { mode = { 'n', 'o', 'x' }, lhs =  '<c-space>', rhs = function()
  require('flash').treesitter {
    actions = {
      ['<c-space>'] = 'next',
      ['<BS>'] = 'prev',
    },
  }
end, { desc = 'Treesitter Incremental Selection' }}})

-- Trouble
require('trouble').setup {

  focus = false, -- Focus the window when opened
  modes = {
    lsp = {
      win = { position = 'right' },
    },
  },
}
_G.keymaps_define({
  { lhs = '<leader>xx', rhs = '<cmd>Trouble diagnostics toggle<cr>', { desc = 'Diagnostics (Trouble)' }},
  { lhs = '<leader>xX', rhs = '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', { desc = 'Buffer Diagnostics (Trouble)' }},
  { lhs = '<leader>cs', rhs = '<cmd>Trouble symbols toggle<cr>', { desc = 'Symbols (Trouble)' }},
  { lhs = '<leader>xS', rhs = '<cmd>Trouble lsp toggle<cr>', { desc = 'LSP references/definitions/... (Trouble)' }},
  { lhs = '<leader>xL', rhs = '<cmd>Trouble loclist toggle<cr>', { desc = 'Location List (Trouble)' }},
  { lhs = '<leader>xQ', rhs = '<cmd>Trouble qflist toggle<cr>', { desc = 'Quickfix List (Trouble)' }},
})

local config = require("fzf-lua.config")
local actions = require("trouble.sources.fzf").actions
config.defaults.actions.files["ctrl-t"] = actions.open
-- stylua: ignore end
require 'plugin.codecompanion'
