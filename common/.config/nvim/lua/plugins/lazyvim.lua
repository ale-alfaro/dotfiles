return {
  {
    'folke/snacks.nvim',
    opts = {
      explorer = { enabled = false },
      dashboard = { enabled = false },
    },
    keys = {
      { '<leader>e', false },
      { '<leader>fe', false },
      { '<leader>E', false },
      { '<leader>fE', false },
    },
  },
  {
    'folke/flash.nvim',
    enabled = false,
    keys = {
      { 's', mode = { 'n', 'x', 'o' }, false },
      { 'S', mode = { 'n', 'o', 'x' }, false },
      { 'r', mode = 'o', false },
      { 'R', mode = { 'o', 'x' }, false },
      { '<c-s>', mode = { 'c' }, false },
    },
  },
  {
    'folke/ts-comments.nvim',
    enabled = false,
  },
  {
    'folke/persistence.nvim',
    -- stylua: ignore
    -- keys = {
    --   { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
    --   { "<leader>qS", function() require("persistence").select() end,desc = "Select Session" },
    --   { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
    --   { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
    -- },
  },
  {
    'akinsho/bufferline.nvim',
    enabled = false,
    keys = {
      { '<leader>bp', false },
      { '<leader>bP', false },
      { '<leader>br', false },
      { '<leader>bl', false },
      { '<S-h>', false },
      { '<S-l>', false },
      { '[b', false },
      { ']b', false },
      { '[B', false },
      { ']B', false },
    },
  },
  {
    'folke/trouble.nvim',
    opts = { use_diagnostic_signs = true },
  },
  {
    'hrsh7th/nvim-cmp',
    dependencies = { 'hrsh7th/cmp-emoji' },
    opts = {
      auto_brackets = { 'python' },
    },
  },
}
