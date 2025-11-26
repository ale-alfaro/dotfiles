---@type VimPackPlugin
-- Improved quickfix UI.
return {
  name = 'quicker',
  plugin = _G.plug_spec { 'stevearc/quicker.nvim', 'folke/trouble.nvim' },
  config = function()
    require('quicker').setup {
      borders = {
        -- Thinner separator.
        vert = VimRc.icons.misc.vertical_bar,
      },
    }
    -- Trouble
    require('trouble').setup {
      focus = false, -- Focus the window when opened
      modes = {
        lsp = {
          win = { position = 'right' },
        },
      },
    }

    local config = require 'fzf-lua.config'
    local actions = require('trouble.sources.fzf').actions
    config.defaults.actions.files['ctrl-t'] = actions.open
    _G.keymaps_define {
      {
        lhs = '>',
        rhs = function()
          require('quicker').expand { before = 2, after = 2, add_to_existing = true }
        end,
        desc = 'Expand context',
      },
      {
        lhs = '<',
        rhs = function()
          require('quicker').collapse()
        end,
        desc = 'Collapse context',
      },
      { lhs = '[q', rhs = vim.cmd.cprev, opts = { desc = 'Previous Quickfix' } },
      { lhs = ']q', rhs = vim.cmd.cnext, opts = { desc = 'Next Quickfix' } },
    }
  end,
  keys = {
    { lhs = '<leader>xD', rhs = '<cmd>Trouble diagnostics toggle<cr>', opts = { desc = 'Diagnostics (Trouble)' } },
    { lhs = '<leader>xb', rhs = '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', opts = { desc = 'Buffer Diagnostics (Trouble)' } },
    { lhs = '<leader>xs', rhs = '<cmd>Trouble symbols toggle<cr>', opts = { desc = 'Symbols (Trouble)' } },
    { lhs = '<leader>xS', rhs = '<cmd>Trouble lsp toggle<cr>', opts = { desc = 'LSP references/definitions  (Trouble)' } },
    { lhs = '<leader>xL', rhs = '<cmd>Trouble loclist toggle<cr>', opts = { desc = 'Location List (Trouble)' } },
    { lhs = '<leader>xQ', rhs = '<cmd>Trouble qflist toggle<cr>', opts = { desc = 'Quickfix List (Trouble)' } },
    {
      lhs = '<leader>xq',
      rhs = function()
        require('quicker').toggle()
      end,
      opts = { desc = 'Toggle quickfix' },
    },
    {
      lhs = '<leader>xl',
      rhs = function()
        require('quicker').toggle { loclist = true }
      end,
      opts = { desc = 'Toggle loclist list' },
    },
    {
      lhs = '<leader>xd',
      rhs = function()
        local quicker = require 'quicker'

        if quicker.is_open() then
          quicker.close()
        else
          vim.diagnostic.setqflist()
        end
      end,
      opts = { desc = 'Toggle diagnostics' },
    },
  },
  { prefix = '<leader>x', group = 'QuickFix' },
}
