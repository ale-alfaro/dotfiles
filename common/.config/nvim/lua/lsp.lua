vim.pack.add(_G.plug_spec {
  'neovim/nvim-lspconfig',
  'rachartier/tiny-code-action.nvim',
})
-- local diagnostics_opts = {
--   virtual_text = {
--     spacing = 4,
--     source = 'if_many',
--     prefix = '●',
--     current_line = true,
--     -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
--     -- prefix = "icons",
--   },
--   severity_sort = true,
--   signs = { priority = 9999, severity = { min = 'WARN', max = 'ERROR' } },
--   -- Don't update diagnostics when typing
--   update_in_insert = false,
--   underline = { severity = { min = 'HINT', max = 'ERROR' } },
-- }
-- vim.diagnostic.config(diagnostics_opts)
VimRc.lsp.setup {
  'lua_ls',
  'clangd',
  'ruff',
  'ty',
  'bashls',
  'taplo',
  'yamls',
  'jsonls',
  'basedpyright',
  'dts-lsp',
}
