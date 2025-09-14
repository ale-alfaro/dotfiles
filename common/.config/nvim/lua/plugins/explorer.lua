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
    config = function(_, opts)
      local oil = require 'oil'
      opts.keymaps = {
        ['?'] = { 'actions.show_help', mode = 'n' },
        ['<CR>'] = 'actions.select',
        ['L'] = { 'actions.select', mode = 'n' },
        ['<C-p>'] = 'actions.preview',
        ['q'] = { 'actions.close', mode = 'n' },
        ['s'] = { oil.save, mode = 'n' },
        ['H'] = { 'actions.parent', mode = 'n' },
        ['<leader>:'] = {
          'actions.open_terminal',
          desc = 'Open the terminal with the current directory as an argument',
        },
        ['<leader>e'] = {
          'actions.open_external',
          desc = 'Open the current directory with external program',
        },
      }

      opts.options = {
        permanent_delete = false,
        use_as_default_explorer = true,
      }

      opts.skip_confirm_for_simple_edits = true
      opts.use_default_keymaps = false
      oil.setup(opts)
    end,
  },
}
