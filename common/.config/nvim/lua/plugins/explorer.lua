return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    enabled = false,
    opts = {
      filesystem = {
        hijack_netrw_behavior = 'false',
      },
    },
  },
  {
    'echasnovski/mini.files',
    keys = {
      {
        '\\',
        function()
          require('mini.files').open(vim.api.nvim_buf_get_name(0), true)
        end,
        desc = 'Open mini.files (Directory of Current File)',
      },
      {
        '<leader>\\',
        function()
          require('mini.files').open(vim.uv.cwd(), true)
        end,
        desc = 'Open mini.files (cwd)',
      },
    },
    opts = function(_, opts)
      opts.options = {
        permanent_delete = false,
        use_as_default_explorer = false,
      }
      opts.mappings = {
        close = 'q',
        go_in = 'l',
        go_in_plus = 'L',
        go_out = 'H',
        go_out_plus = '<Left>',
        mark_goto = 'g',
        mark_set = 'm',
        reset = '<BS>',
        reveal_cwd = '.',
        show_help = '?',
        synchronize = 's',
        trim_left = '<',
        trim_right = '>',
      }
    end,
  },
  {
    'stevearc/oil.nvim',
    lazy = false,
    keys = {
      { '<leader>e', '<cmd>vs +Oil<cr>', desc = 'Open oil in sidebar' },
    },
    opts = {
      options = {
        permanent_delete = false,
        use_as_default_explorer = false,
      },
    },
  },
}
