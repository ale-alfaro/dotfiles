vim.pack.add(_G.plug_spec {
  'neovim/nvim-lspconfig',
  'rachartier/tiny-code-action.nvim',
})

local ok, lsp = pcall(require, 'custom.lsp')
if ok then
  lsp.config { 'lua_ls', 'clangd', 'bashls', 'taplo', 'yamls', 'jsonls', 'dts-lsp', 'marksman', 'ruff', 'pyrefly' }
else
  _G.error "COULDN'T LOAD LSP CONFIG"
end
