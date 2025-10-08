return {
  'neovim/nvim-lspconfig',
  opts = {
    servers = {
      taplo = {
        cmd = { 'taplo', 'lsp', 'stdio' },
        filetypes = { 'toml' },
        root_markers = { 'pyproject.toml', '.git' },
      },
    },
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = { ensure_installed = { 'toml' } },
  },
}
