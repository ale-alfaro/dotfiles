---@module "lazyvim"
---
---

return {
  {
    'nvim-treesitter/nvim-treesitter',
    opts = { ensure_installed = { 'ninja', 'rst' } },
  },
  {
    'neovim/nvim-lspconfig',
    opts = function(_, opts)
      opts.servers = {
        ruff = {
          root_markers = {
            'uv.lock',
            'pyproject.lock',
          },
          cmd = { 'ruff', 'server' },
          filetypes = { 'python' },
          settings = {},
          capabilities = {
            offsetEncoding = { 'utf-16' },
          },
          on_attach = function(client, bufnr)
            -- Disable hover in favor of Pyright
            client.server_capabilities.hoverProvider = false

            vim.keymap.set('n', '<leader>co', function()
              vim.lsp.buf.code_action {
                apply = true,
                context = {
                  only = { 'source.organizeImports' },
                  diagnostics = {},
                },
              }
            end, { desc = 'Ruff Organize Imports', buffer = true })
          end,
        },

        ty = {
          mason = false,
          filetypes = { 'python' },
          root_markers = {
            'uv.lock',
            'pyproject.lock',
          },
          cmd = { 'ty', 'server' },
          settings = {},
          capabilities = {
            offsetEncoding = { 'utf-16' },
          },
        },
        basedpyright = {
          mason = false,
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
                -- useLibraryCodeForTypes = true,
                diagnosticMode = 'off',
                typeCheckingMode = 'off', -- Set type-checking mode to off
              },
            },
          },
          capabilities = {
            offsetEncoding = { 'utf-16' },
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
          end,
        },
      }

      vim.lsp.config('ruff', {
        init_options = {
          settings = {
            args = {
              '--ignore',
              'F821',
              '--ignore',
              'E402',
              '--ignore',
              'E722',
              '--ignore',
              'E712',
            },
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
      })
      vim.lsp.enable 'ruff'

      vim.lsp.config('ty', {
        settings = {
          -- disableLanguageServices = true,
          diagnosticMode = 'workspace',
          experimental = {
            autoImport = true,
          },
        },
      })
      -- vim.lsp.enable 'ty'
      vim.lsp.enable 'basedpyright'
    end,
  },

  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/neotest-plenary',
      'nvim-neotest/neotest-python',
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
    dependencies = {
      'mfussenegger/nvim-dap-python',
      -- stylua: ignore
      keys = {
        { "<leader>dPt", function() require('dap-python').test_method() end, desc = "Debug Method", ft = "python" },
        { "<leader>dPc", function() require('dap-python').test_class() end, desc = "Debug Class", ft = "python" },
      },
      config = function()
        if vim.fn.has 'win32' == 1 then
          require('dap-python').setup(LazyVim.get_pkg_path('debugpy', '/venv/Scripts/pythonw.exe'))
        else
          require('dap-python').setup(LazyVim.get_pkg_path('debugpy', '/venv/bin/python'))
        end
      end,
    },
  },

  {
    'benomahony/uv.nvim',
    ft = 'python',
    dependencies = { 'folke/snacks.nvim' },
    opts = {},
  },

  {
    'hrsh7th/nvim-cmp',
    opts = function(_, opts)
      opts.auto_brackets = opts.auto_brackets or {}
      table.insert(opts.auto_brackets, 'python')
    end,
  },
}
