return {
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
    'nvim-neo-tree/neo-tree.nvim',
    -- enabled = false,
    opts = function(_, opts)
      opts.window = {

        mappings = {
          ['l'] = 'open',
          ['h'] = 'close_node',
          ['<space>'] = 'none',
          ['Y'] = {
            function(state)
              local node = state.tree:get_node()
              local path = node:get_id()
              vim.fn.setreg('+', path, 'c')
            end,
            desc = 'Copy Path to Clipboard',
          },
          -- ['<cr>'] = 'toggle_node',
          -- ['H'] = 'navigate_up',
          ['O'] = {
            function(state)
              require('lazy.util').open(state.tree:get_node().path, { system = true })
            end,
            desc = 'Open with System Application',
          },
          ['P'] = { 'toggle_preview', config = { use_float = false } },
        },
      }
      opts.filtered_items = {
        visible = false, -- when true, they will just be displayed differently than normal items
        force_visible_in_empty_folder = false, -- when true, hidden files will be shown if the root folder is otherwise empty
        children_inherit_highlights = true, -- whether children of filtered parents should inherit their parent's highlight group
        show_hidden_count = true, -- when true, the number of hidden items in each folder will be shown as the last entry
        hide_dotfiles = false,
        hide_gitignored = true,
        hide_hidden = true, -- only works on Windows for hidden files/directories
        hide_by_name = {
          '.DS_Store',
          'thumbs.db',
          --"node_modules",
        },
        hide_by_pattern = { -- uses glob style patterns
          --"*.meta",
          --"*/src/*/tsconfig.json"
        },
        always_show = { -- remains visible even if other settings would normally hide it
          --".gitignored",
        },
        always_show_by_pattern = { -- uses glob style patterns
          '.env*',
        },
        never_show = { -- remains hidden even if visible is toggled to true, this overrides always_show
          '.DS_Store',
          --"thumbs.db"
        },
        never_show_by_pattern = { -- uses glob style patterns
          --".null-ls_*",
        },
      }
    end,
  },
}
