-- LSP Server to use for Python.
-- Set to "basedpyright" to use basedpyright instead of pyright.
vim.g.lazyvim_python_lsp = 'basedpyright'
-- Set to "ruff_lsp" to use the old LSP implementation version.
vim.g.lazyvim_python_ruff = 'ruff'

return {
  {
    'williamboman/mason.nvim',
    cmd = 'Mason',
    keys = { { '<leader>cm', '<cmd>Mason<cr>', desc = 'Mason' } },
    opts = {
      ensure_installed = {
        'clangd',
        'gopls',
        'rust-analyzer',
        'lua-language-server',
        'basedpyright',
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
      },
    },
  },
  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'williamboman/mason.nvim' },
    opts = {
      automatic_installation = true,
    },
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
    },
    opts = {
      servers = {
        pyright = false,
        clangd = {},
        basedpyright = {
          analysis = {
            autoImportCompletions = true,
            autoSearchPaths = true,
            diagnosticMode = 'workspace',
            typeCheckingMode = 'basic',
          },
        },
        ruff = {
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
        },
      },
    },
  },
  {
    'linux-cultist/venv-selector.nvim',
    branch = 'regexp',
    cmd = 'VenvSelect',
    opts = {
      name = {
        'venv',
        '.venv',
        'env',
        '.env',
      },
      dap_enabled = true,
    },
    keys = {
      { '<leader>cv', '<cmd>VenvSelect<cr>', desc = 'Select VirtualEnv', ft = 'python' },
    },
  },
}
