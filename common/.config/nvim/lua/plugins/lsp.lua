-- LSP Server to use for Python.
-- Set to "basedpyright" to use basedpyright instead of pyright.
vim.g.lazyvim_python_lsp = 'ruff'
-- Set to "ruff_lsp" to use the old LSP implementation version.
vim.g.lazyvim_python_ruff = 'ruff'

return {
  {
    'mason-org/mason.nvim',
    cmd = 'Mason',
    keys = { { '<leader>cm', '<cmd>Mason<cr>', desc = 'Mason' } },
    opts = {
      ensure_installed = {
        'clangd',
        'gopls',
        'rust-analyzer',
        'lua-language-server',
        'cmake-language-server',
        'stylua',
        'shfmt',
        'clang-format',
        'goimports',
        'gofumpt',
        'rustfmt',
        'black',
        'isort',
        'shellcheck',
        'ruff',
        'vectorcode',
      },
    },
  },
  {
    'mason-org/mason-lspconfig.nvim',
    dependencies = { 'mason-org/mason.nvim' },
    opts = {
      automatic_installation = true,
    },
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
    },
    opts = {
      servers = {
        pyright = false,
        clangd = {},
        basedpyright = false,
        ruff_lsp = false,
        ruff = {
          cmd = { 'uvx', 'ruff', 'server' },
          cmd_env = { RUFF_TRACE = 'messages' },
          init_options = {
            settings = {
              logLevel = 'error',
            },
          },
          keys = {
            {
              '<leader>co',
              LazyVim.lsp.action['source.organizeImports'],
              desc = 'Organize Imports',
            },
          },
        }, -- ruff

        vectorcode_server = {
          -- cmd = { 'vectorcode-server' },
          -- root_dir = vim.fs.root(0, { '.vectorcode', '.git', '.stylua.toml' }),
        },
      }, -- servers
    },
  },
  {
    'linux-cultist/venv-selector.nvim',
    branch = 'regexp',
    cmd = 'VenvSelect',
    dependencies = {
      'neovim/nvim-lspconfig',
      { 'nvim-telescope/telescope.nvim', branch = '0.1.x', dependencies = { 'nvim-lua/plenary.nvim' } }, -- optional: you can also use fzf-lua, snacks, mini-pick instead.
    },
    ft = 'python', -- Load when opening Python files
    keys = {
      { '<leader>cv', '<cmd>VenvSelect<cr>', desc = 'Select VirtualEnv', ft = 'python' },
    },
    config = function(_, opts)
      require('venv-selector').setup {
        options = {
          on_venv_activate_callback = nil, -- callback function for after a venv activates
          enable_default_searches = false, -- switches all default searches on/off
          enable_cached_venvs = false, -- use cached venvs that are activated automatically when a python file is registered with the LSP.
          cached_venv_automatic_activation = false, -- if set to false, the VenvSelectCached command becomes available to manually activate them.
          activate_venv_in_terminal = true, -- activate the selected python interpreter in terminal windows opened from neovim
          set_environment_variables = true, -- sets VIRTUAL_ENV or CONDA_PREFIX environment variables
          notify_user_on_venv_activation = true, -- notifies user on activation of the virtual env
          search_timeout = 5, -- if a search takes longer than this many seconds, stop it and alert the user
          debug = true, -- enables you to run the VenvSelectLog command to view debug logs
          -- fd_binary_name = M.find_fd_command_name(), -- plugin looks for `fd` or `fdfind` but you can set something else here
          require_lsp_activation = true, -- require activation of an lsp before setting env variables
          -- telescope viewer options
          on_telescope_result_callback = nil, -- callback function for modifying telescope results
          show_telescope_search_type = true, -- Shows which of the searches found which venv in telescope
          telescope_filter_type = 'substring', -- When you type something in telescope, filter by "substring" or "character"
          telescope_active_venv_color = '#00FF00', -- The color of the active venv in telescope
          picker = 'snacks', -- The picker to use. Valid options are "telescope", "fzf-lua", "snacks", "native", "mini-pick" or "auto"
          icon = '', -- The icon to use in the picker for each item
        },
        search = {
          virtualenvs = false,
          hatch = false,
          poetry = false,
          pyenv = false,
          pipenv = false,
          anaconda_envs = false,
          anaconda_base = false,
          miniconda_envs = false,
          miniconda_base = false,
          pipx = false,
          cwd = false,
          workspace = false,
          file = false,
          uv = {
            command = 'uv python find',
          },
        },
      }
    end,
  },
}
