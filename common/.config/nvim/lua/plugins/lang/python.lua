---@module "lazyvim"
---
---

local function set_python_path(command)
  local path = command.args
  local clients = vim.lsp.get_clients {
    bufnr = vim.api.nvim_get_current_buf(),
    name = 'basedpyright',
  }
  for _, client in ipairs(clients) do
    if client.settings then
      client.settings.python = vim.tbl_deep_extend('force', client.settings.python or {}, { pythonPath = path })
    else
      client.config.settings = vim.tbl_deep_extend('force', client.config.settings, { python = { pythonPath = path } })
    end
    client:notify('workspace/didChangeConfiguration', { settings = nil })
  end
end

return {
  {
    'nvim-treesitter/nvim-treesitter',
    opts = { ensure_installed = { 'ninja', 'rst' } },
  },
  {
    'neovim/nvim-lspconfig',
    opts = function(_, opts)
      -- opts.servers = python_lsp_config
      vim.lsp.config.ruff = {

        -- enabled = true,
        -- ft = 'python',
        root_markers = {
          'uv.lock',
          'pyproject.lock',
        },
        cmd = { 'ruff', 'server' },
        settings = {

          ruff = {
            init_options = {
              settings = {
                logLevel = 'error',
                -- fixAll = true,
                lint = {
                  -- preview = true,
                },
                formatter = {
                  -- preview = true,
                  backend = 'uv',
                },
                exclude = { '**/build/**' },
              },
            },
            -- keys = {
            --   {
            --     '<leader>co',
            --     LazyVim.lsp.action['source.organizeImports'],
            --     desc = 'Organize Imports',
            --   },
            -- },
          },
        },

        -- on_attach = function(client, bufnr)
        --   -- Disable hover in favor of Pyright
        --   client.server_capabilities.hoverProvider = false
        -- end,
      }
      -- vim.lsp.config.pyright = {
      --   enabled = false,
      --   cmd = { 'pyright-langserver', '--stdio' },
      --   filetypes = { 'python' },
      --   root_markers = {
      --     'pyproject.toml',
      --     'uv.lock',
      --     'pyproject.lock',
      --   },
      --   settings = {
      --     python = {
      --       analysis = {
      --         ignore = { '*' }, -- Disable for ruff lsp
      --         autoSearchPaths = true,
      --         useLibraryCodeForTypes = true,
      --         diagnosticMode = 'openFilesOnly',
      --       },
      --     },
      --     pyright = {
      --       disableOrganizeImports = true,
      --     },
      --   },
      --   -- on_attach = function(client, bufnr)
      --   --   vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightSetPythonPath', set_python_path, {
      --   --     desc = 'Reconfigure pyright with the provided python path',
      --   --     nargs = 1,
      --   --     complete = 'file',
      --   --   })
      --   -- end,
      -- }

      vim.lsp.config.basedpyright = {
        cmd = { 'basedpyright-langserver', '--stdio' },
        filetypes = { 'python' },
        root_markers = {
          'pyproject.toml',
          'uv.lock',
          'pyproject.lock',
        },
        settings = {
          basedpyright = {
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = 'openFilesOnly',
            },
          },
        },
        on_attach = function(client, bufnr)
          vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightOrganizeImports', function()
            local params = {
              command = 'basedpyright.organizeimports',
              arguments = { vim.uri_from_bufnr(bufnr) },
            }

            -- Using client.request() directly because "basedpyright.organizeimports" is private
            -- (not advertised via capabilities), which client:exec_cmd() refuses to call.
            -- https://github.com/neovim/neovim/blob/c333d64663d3b6e0dd9aa440e433d346af4a3d81/runtime/lua/vim/lsp/client.lua#L1024-L1030
            client.request('workspace/executeCommand', params, nil, bufnr)
          end, {
            desc = 'Organize Imports',
          })

          vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightSetPythonPath', set_python_path, {
            desc = 'Reconfigure basedpyright with the provided python path',
            nargs = 1,
            complete = 'file',
          })
        end,
      }
      vim.lsp.enable('basedpyright', true)
    end,
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
    'mfussenegger/nvim-dap-python',
    dependencies = { 'mfussenegger/nvim-dap' },
      -- stylua: ignore
      keys = {
        { "<leader>dPt", function() require('dap-python').test_method() end, desc = "Debug Method", ft = "python" },
        { "<leader>dPc", function() require('dap-python').test_class() end, desc = "Debug Class", ft = "python" },
      },
    config = true,
  },

  {
    'benomahony/uv.nvim',
    ft = 'python',
    dependencies = { 'folke/snacks.nvim' },
    opts = {
      -- Auto-activate virtual environments when found
      auto_activate_venv = true,
      notify_activate_venv = true,

      -- Auto commands for directory changes
      auto_commands = true,

      -- Integration with snacks picker
      picker_integration = true,

      -- Keymaps to register (set to false to disable)
      keymaps = {
        prefix = '<leader>x', -- Main prefix for uv commands
        commands = true, -- Show uv commands menu (<leader>x)
        run_file = true, -- Run current file (<leader>xr)
        run_selection = true, -- Run selected code (<leader>xs)
        run_function = true, -- Run function (<leader>xf)
        venv = true, -- Environment management (<leader>xe)
        init = true, -- Initialize uv project (<leader>xi)
        add = true, -- Add a package (<leader>xa)
        remove = true, -- Remove a package (<leader>xd)
        sync = true, -- Sync packages (<leader>xc)
        sync_all = true, -- Sync all packages, extras and groups (<leader>xC)
      },

      -- Execution options
      execution = {
        -- Python run command template
        run_command = 'uv run python',

        -- Show output in notifications
        notify_output = true,

        -- Notification timeout in ms
        notification_timeout = 10000,
      },
    },
  },

  -- {
  --   'linux-cultist/venv-selector.nvim',
  --   cmd = 'VenvSelect',
  --   dependencies = {
  --     'neovim/nvim-lspconfig',
  --   },
  --   ft = 'python', -- Load when opening Python files
  --   keys = {
  --     { '<leader>cv', '<cmd>VenvSelect<cr>', desc = 'Select VirtualEnv', ft = 'python' },
  --   },
  --   config = function(_, opts)
  --     require('venv-selector').setup {
  --       options = {
  --         on_venv_activate_callback = nil, -- callback function for after a venv activates
  --         enable_default_searches = false, -- switches all default searches on/off
  --         enable_cached_venvs = false, -- use cached venvs that are activated automatically when a python file is registered with the LSP.
  --         cached_venv_automatic_activation = false, -- if set to false, the VenvSelectCached command becomes available to manually activate them.
  --         activate_venv_in_terminal = true, -- activate the selected python interpreter in terminal windows opened from neovim
  --         set_environment_variables = true, -- sets VIRTUAL_ENV or CONDA_PREFIX environment variables
  --         notify_user_on_venv_activation = true, -- notifies user on activation of the virtual env
  --         search_timeout = 5, -- if a search takes longer than this many seconds, stop it and alert the user
  --         debug = true, -- enables you to run the VenvSelectLog command to view debug logs
  --         -- fd_binary_name = M.find_fd_command_name(), -- plugin looks for `fd` or `fdfind` but you can set something else here
  --         require_lsp_activation = true, -- require activation of an lsp before setting env variables
  --         -- telescope viewer options
  --         on_telescope_result_callback = nil, -- callback function for modifying telescope results
  --         show_telescope_search_type = true, -- Shows which of the searches found which venv in telescope
  --         telescope_filter_type = 'substring', -- When you type something in telescope, filter by "substring" or "character"
  --         telescope_active_venv_color = '#00FF00', -- The color of the active venv in telescope
  --         picker = 'snacks', -- The picker to use. Valid options are "telescope", "fzf-lua", "snacks", "native", "mini-pick" or "auto"
  --         icon = '', -- The icon to use in the picker for each item
  --       },
  --       search = {
  --         virtualenvs = false,
  --         hatch = false,
  --         poetry = false,
  --         pyenv = false,
  --         pipenv = false,
  --         anaconda_envs = false,
  --         anaconda_base = false,
  --         miniconda_envs = false,
  --         miniconda_base = false,
  --         pipx = false,
  --         cwd = false,
  --         workspace = false,
  --         file = false,
  --         uv = {
  --           command = 'uv python find',
  --         },
  --       },
  --     }
  --   end,
  -- },
  {
    'hrsh7th/nvim-cmp',
    opts = function(_, opts)
      opts.auto_brackets = opts.auto_brackets or {}
      table.insert(opts.auto_brackets, 'python')
    end,
  },
}
