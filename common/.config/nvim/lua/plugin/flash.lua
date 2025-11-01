-- Jump around with search labels
-- https://github.com/folke/flash.nvim
---@type  VimPackPlugin
return {
  name = 'flash',
  plugin = _G.plug("folke/flash.nvim"),
  opts = {
    labels = "asdfqwerzxcv", -- Limit labels to left side of the keyboard
    modes = {
      char = {
        char_actions = function()
          return {
            [";"] = "next",
            ["F"] = "left",
            ["f"] = "right",
            ["T"] = "left",
            ["t"] = "right",
          }
        end,
        keys = { "f", "F", "t", "T", ";" },
        highlight = {
          backdrop = false,
        },
        jump_labels = false,
      },
      search = {
        enabled = true,
      },
    },
    prompt = {
      win_config = {
        border = "none",
        -- Place the prompt above the statusline.
        row = -3,
      },
    },
    search = {
      wrap = true,
      exclude = {
        'flash_prompt',
        'qf',
        function(win)
          -- Non-focusable windows.
          return not vim.api.nvim_win_get_config(win).focusable
        end,
      },
    },
    jump = { nohlsearch = true },
  },
  keys = {
    { mode = { 'n', 'o', 'x' }, lhs = 'S',     rhs = function() require('flash').treesitter() end,        { desc = 'Flash Treesitter' } },
    { mode = 'o',               lhs = 'r',     rhs = function() require('flash').treesitter_search() end, { desc = 'Treesitter Search' } },
    { mode = 'o',               lhs = 'R',     rhs = function() require('flash').remote() end,            { desc = 'Remote Flash' } },
    { mode = 'c',               lhs = '<c-s>', rhs = function() require('flash').toggle() end,            { desc = 'Flash Toggle' } },
    {
      mode = { 'n', 'o', 'x' },
      lhs = '<c-space>',
      rhs = function()
        require('flash').treesitter {
          actions = {
            ['<c-space>'] = 'next',
            ['<BS>'] = 'prev',
          },
        }
      end,
      { desc = 'Treesitter Incremental Selection' }
    },
  }
}
