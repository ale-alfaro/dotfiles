vim.pack.add(_G.plug_spec {
  'neovim/nvim-lspconfig',
  'rachartier/tiny-code-action.nvim',
  'p00f/clangd_extensions.nvim',
})

local ok, lsp = pcall(require, 'custom.lsp')
if ok then
  lsp.config { 'lua_ls', 'clangd', 'neocmake', 'bashls', 'taplo', 'yamls', 'jsonls', 'devicetree_ls', 'marksman', 'ruff', 'pyrefly' }
else
  _G.error "COULDN'T LOAD LSP CONFIG"
end
