-- This Lsps are better not enabled by default and enabled locally
-- Set up LSP servers.
VimRc.now_if_args(function()
  vim.pack.add(_G.plug_spec {
    'neovim/nvim-lspconfig',
    'b0o/schemastore.nvim',
    'rachartier/tiny-code-action.nvim',
  })
  -- Code action setup
  require('vimrc_lsp').setup()
end)
