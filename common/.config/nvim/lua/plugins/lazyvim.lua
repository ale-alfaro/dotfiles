---@module "snacks"
return {
  {
    'folke/flash.nvim',
    keys = {
      { 's', mode = { 'n', 'x', 'o' }, false },
      -- { 'S', mode = { 'n', 'o', 'x' }, false },
      { 'r', mode = 'o', false },

      {
        'S',
        mode = { 'n', 'o', 'x' },
        function()
          require('flash').treesitter()
        end,
        desc = 'Flash Treesitter',
      },
      {
        'R',
        mode = { 'o', 'x' },
        function()
          require('flash').treesitter_search()
        end,
        desc = 'Treesitter Search',
      },
      { '<c-s>', mode = { 'c' }, false },
      -- Simulate nvim-treesitter incremental selection
      {
        '<c-space>',
        mode = { 'n', 'o', 'x' },
        function()
          require('flash').treesitter {
            actions = {
              ['<c-space>'] = 'next',
              ['<BS>'] = 'prev',
            },
          }
        end,
        desc = 'Treesitter Incremental Selection',
      },
    },
  },
  {
    'folke/trouble.nvim',
    opts = {
      use_diagnostic_signs = true,
      modes = {
        uv_qflist = {
          mode = 'qflist',
          win = { position = 'bottom', size = 10 },
          groups = {
            { 'filename', format = '{file_icon} {basename:Title} {count}' },
          },
        },

        uv_wspace_diags = {
          mode = 'diagnostics', -- inherit from diagnostics mode
          filter = {
            any = {
              buf = 0, -- current buffer
              {
                severity = vim.diagnostic.severity.ERROR, -- errors only
                -- limit to files in the current project
                function(item)
                  return item.filename:find((vim.loop or vim.uv).cwd(), 1, true)
                end,
              },
            },
          },
        },
      },
    },
  },
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = function(_, opts)
      opts = vim.tbl_deep_extend('force', opts or {}, {
        library = {
          { path = 'luvit-meta/library', words = { 'vim%.uv' } },
          { path = 'wezterm-types', mods = { 'wezterm' } },
          { path = 'folke/snacks.nvim', words = { 'Snacks' } },
          {
            path = 'nvim-lua/plenary.nvim',
            words = {
              'describe',
              'it',
              'pending',
              'before_each',
              'after_each',
              'clear',
              'assert.*',
            },
          },
        },
      })
      return opts
    end,
    dependencies = {
      { 'Bilal2453/luvit-meta' },
      { 'justinsgithub/wezterm-types' },
      { 'folke/snacks.nvim' },
    },
  },
}
