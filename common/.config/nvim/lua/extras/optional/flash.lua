---@module 'flash'
-- Jump around with search labels
-- https://github.com/folke/flash.nvim
---@type  VimPackPlugin
return {
  name = 'flash',
  plugin = _G.plug_spec { 'folke/flash.nvim' },
  ---@type Flash.Config
  opts = {
    labels = 'asdfqwerzxcv', -- Limit labels to left side of the keyboard
    modes = {
      char = {
        char_actions = function()
          return {
            [';'] = 'next',
            ['F'] = 'left',
            ['f'] = 'right',
            ['T'] = 'left',
            ['t'] = 'right',
          }
        end,
        keys = { 'f', 'F', 't', 'T', ';' },
        highlight = {
          backdrop = false,
        },
        jump_labels = false,
      },
      search = {
        enabled = false,
      },
    },
    prompt = {
      win_config = {
        border = 'none',
        -- Place the prompt above the statusline.
        row = -3,
      },
    },
    jump = { enabled = false },
  },
  -- stylua: ignore
  keys = {
    { mode = { 'n', 'o', 'x' }, lhs = 'o',     rhs = function() require('extras.optional.flash').treesitter() end,        opts = { desc = 'Flash Treesitter' } },
    { mode = 'c',               lhs = '<c-s>', rhs = function() require('extras.optional.flash').toggle() end,            opts = { desc = 'Flash Toggle' } },
    { mode = { 'n', 'o', 'x' }, lhs = '<c-space>', rhs = function() require('extras.optional.flash').treesitter { actions = { ['<c-space>'] = 'next', ['<BS>'] = 'prev', }, } end, { desc = 'Treesitter Incremental Selection' } },
  }
,
}
