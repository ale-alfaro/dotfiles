return {
  {
    'benomahony/uv.nvim',
    ft = { 'python' },
    dependencies = { 'folke/snacks.nvim' },
    opts = {
      picker_integration = true,
    },
  },
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/neotest-plenary',
      'nvim-neotest/neotest-go',
      'nvim-neotest/nvim-nio',
    },
    keys = {
      -- Run nearest tests
      vim.keymap.set('n', '<leader>R', function()
        require('neotest').run.run()
      end, { desc = 'Run nearest tests' }),
      -- Run tests in file
      vim.keymap.set('n', '<leader>F', function()
        require('neotest').run.run(vim.fn.expand '%')
      end, { desc = 'Run tests in file' }),
    },
    opts = {
      -- Can be a list of adapters like what neotest expects,
      -- or a list of adapter names,
      -- or a table of adapter names, mapped to adapter configs.
      -- The adapter will then be automatically loaded with the config.
      -- adapters = {
      --   'neotest-plenary',
      --   'neotest-go',
      --   'neotest-python',
      -- },
      -- Example for loading neotest-golang with a custom config
      adapters = {
        -- ["neotest-golang"] = {
        --   go_test_args = { "-v", "-race", "-count=1", "-timeout=60s" },
        --   dap_go_enabled = true,
        -- },
        ['neotest-python'] = {
          -- Extra arguments for nvim-dap configuration
          -- See https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for values
          dap = { justMyCode = false },
          -- Command line arguments for runner
          -- Can also be a function to return dynamic values
          args = { '--log-level', 'DEBUG' },
          -- Runner to use. Will use pytest if available by default.
          -- Can be a function to return dynamic value.
          runner = 'pytest',
          -- runner = function() end,
          -- Custom python path for the runner.
          -- Can be a string or a list of strings.
          -- Can also be a function to return dynamic value.
          -- If not provided, the path will be inferred by checking for
          -- virtual envs in the local directory and for Pipenev/Poetry configs
          python = function()
            return vim.fn.expand '$UV_PYTHON'
            -- uvx python find
          end,
          -- Returns if a given file path is a test file.
          -- NB: This function is called a lot so don't perform any heavy tasks within it.
          -- is_test_file = function(file_path)
          -- end,
          -- !!EXPERIMENTAL!! Enable shelling out to `pytest` to discover test
          -- instances for files containing a parametrize mark (default: false)
          pytest_discover_instances = true,
        },
      },
      status = { virtual_text = true },
      output = { open_on_run = true },
      summary = { open_on_run = true },
    },
  },
  {
    'mrjones2014/smart-splits.nvim',
    lazy = false,
    -- init = function()
    --   vim.g.smart_splits_multiplexer_integration = 'wezterm'
    -- end,
    opts = {
      -- Ignored buffer types (only while resizing)
      ignored_buftypes = {
        'snacks_picker_list',
        'codecompanion',
      },
      -- Ignored filetypes (only while resizing)
      ignored_filetypes = { 'snacks_picker_list', 'codecompanion' },
      -- the default number of lines/columns to resize by at a time
      --   -- for example `10<A-h>` will `resize_left` by `(10 * config.default_amount)`
      default_amount = 3,
      -- when moving cursor between splits left or right,
      -- place the cursor on the same row of the *screen*
      -- regardless of line numbers. False by default.
      -- Can be overridden via function parameter, see Usage.
      move_cursor_same_row = true,
    },
    -- stylua: ignore
    keys = {
    --   -- resizing splits
      {'<A-h>', function() require('smart-splits').resize_left()  end, desc = 'Resize left'},
      {'<A-j>', function() require('smart-splits').resize_down()  end, desc = 'Resize down'},
      {'<A-k>', function() require('smart-splits').resize_up()    end, desc = 'Resize up'},
      {'<A-l>', function() require('smart-splits').resize_right() end, desc = 'Resize right'},
    --   -- moving between splits
      {'<C-h>', function() require('smart-splits').move_cursor_left()  end, desc = 'Move window left'},
      {'<C-j>', function() require('smart-splits').move_cursor_down()  end, desc = 'Move window down'},
      {'<C-k>', function() require('smart-splits').move_cursor_up()    end, desc = 'Move window up'},
      {'<C-l>', function() require('smart-splits').move_cursor_right() end, desc = 'Move window right'},
    --   -- swapping buffers between windows
      {'<leader><leader>h', function() require('smart-splits').swap_buf_left()  end, desc = 'Swap buffer left'},
      {'<leader><leader>j', function() require('smart-splits').swap_buf_down()  end, desc = 'Swap buffer down'},
      {'<leader><leader>k', function() require('smart-splits').swap_buf_up()    end, desc = 'Swap buffer up'},
      {'<leader><leader>l', function() require('smart-splits').swap_buf_right() end, desc = 'Swap buffer right'},
      },
  },
}
