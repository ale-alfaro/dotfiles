---@type VimPackPlugin
-- Improved quickfix UI.
return {
  name = 'quicker',
  plugin = _G.plug_spec { 'stevearc/quicker.nvim', 'folke/trouble.nvim' },
  config = function()
    require('quicker').setup {
      -- opts = {
      --   buflisted = false,
      --   number = false,
      --   relativenumber = false,
      --   signcolumn = "auto",
      --   winfixheight = true,
      --   wrap = false,
      -- },
      -- -- Set to false to disable the default options in `opts`
      -- use_default_opts = true,
      -- Keymaps to set for the quickfix buffer
      keys = {
        { '>', "<cmd>lua require('quicker').expand()<CR>", desc = 'Expand quickfix content' },
        { '<', "<cmd>lua require('quicker').collapse()<CR>", desc = 'Collapse quickfix content' },
      },
      -- Callback function to run any custom logic or keymaps for the quickfix buffer
      on_qf = function(bufnr) end,
      edit = {
        -- Enable editing the quickfix like a normal buffer
        enabled = true,
        -- Set to true to write buffers after applying edits.
        -- Set to "unmodified" to only write unmodified buffers.
        autosave = 'unmodified',
      },
    }
    -- Trouble
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
  end,
  keys = {
    { lhs = '<leader>xD', rhs = '<cmd>Trouble diagnostics toggle filter.severity=1<cr>', opts = { desc = 'Diagnostics (Trouble)' } },
    { lhs = '<leader>xb', rhs = '<cmd>Trouble diagnostics toggle filter.buf=0 filter.severity=2<cr>', opts = { desc = 'Buffer Diagnostics (Trouble)' } },
    { lhs = '<leader>xs', rhs = '<cmd>Trouble symbols toggle<cr>', opts = { desc = 'Symbols (Trouble)' } },
    { lhs = '<leader>xr', rhs = '<cmd>Trouble lsp toggle<cr>', opts = { desc = 'LSP references/definitions  (Trouble)' } },
    { lhs = '<leader>xL', rhs = '<cmd>Trouble loclist toggle<cr>', opts = { desc = 'Location List (Trouble)' } },
    { lhs = '<leader>xQ', rhs = '<cmd>Trouble qflist toggle<cr>', opts = { desc = 'Quickfix List (Trouble)' } },
    {
      lhs = '<leader>xq',
      rhs = function()
        require('quicker').toggle()
      end,
      opts = { desc = 'Toggle quickfix (quicker)' },
    },
    {
      lhs = '<leader>xl',
      rhs = function()
        require('quicker').toggle { loclist = true }
      end,
      opts = { desc = 'Toggle loclist list (quicker)' },
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
      opts = { desc = 'Toggle diagnostics (quicker)' },
    },
  },
  { prefix = '<leader>x', group = 'QuickFix' },
}
