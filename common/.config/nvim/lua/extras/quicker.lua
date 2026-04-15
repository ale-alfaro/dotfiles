---@class QuickerCtxLineNoTweakArgs
---@field lineno integer
---@field add_to_existing boolean
---
---
---@class QuickerCtxLineNoTweakArgs
---@field before QuickerCtxLineNoTweakArgs
---@field after QuickerCtxLineNoTweakArgs
---
local qf_toggle_expand = function()
  vim.ui.select({ '5', '10', '15', '20', '25' }, { prompt = 'Expand by how many lines: ' }, function(lines)
    local lineno = tonumber(lines)
    if type(lineno) ~= 'number' then
      error 'Line number must be an error'
    end
    require('quicker').toggle_expand { before = lineno, after = lineno, add_to_existing = true }
  end)
end
-- Improved quickfix UI.
---@return VimPackPlugin
VimRc.pack_add {
  name = 'quicker',
  plugin = _G.plug_spec { 'stevearc/quicker.nvim', 'folke/trouble.nvim' },
  config = function()
    -- Trouble
  end,
  keys = {

    { lhs = '<leader>xd', rhs = '<cmd>Trouble diagnostics toggle filter.severity=2<cr>', opts = { desc = 'Diagnostics (Trouble)' } },
    { lhs = '<leader>xb', rhs = '<cmd>Trouble diagnostics toggle filter.buf=0 filter.severity=2<cr>', opts = { desc = 'Buffer Diagnostics (Trouble)' } },
    { lhs = '<leader>xs', rhs = '<cmd>Trouble symbols toggle<cr>', opts = { desc = 'Symbols (Trouble)' } },
    {
      lhs = '<leader>xl',
      rhs = '<cmd>Trouble lsp toggle<cr>',
      opts = { desc = 'LSP references/definitions  (Trouble)' },
    },
  },
  {
    lhs = '<leader>xq',
    rhs = function()
      local quicker = require 'quicker'

      if quicker.is_open() then
        quicker.close()
      else
        vim.diagnostic.setqflist()
      end
    end,
    opts = { desc = 'Toggle diagnostics (quicker)' },
  },
  { prefix = '<leader>x', group = 'QuickFix' },
}
