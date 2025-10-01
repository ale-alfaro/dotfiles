return {
  'neovim/nvim-lspconfig',
  opts = {
    servers = {
      taplo = {
        filetypes = 'toml',
        root_markers = { '.toml' },
      },
    },
  },
}
