-- Install with
-- mac: brew install lua-language-server
-- Arch: pacman -S lua-language-server

---@type vim.lsp.Config
return {
  cmd = { 'emmylua_ls' },
  filetypes = { 'lua' },
  root_markers = { '.emmyrc.json', '.emmyrc.lua', '.luarc.json' },
  workspace_required = false,
  ---@type lspconfig.settings.emmylua_ls
  settings = {
    emmylua = {
      codeLens = { enable = true },
      hint = { enable = true },
      workspace = {
        library = {
          vim.env.VIMRUNTIME,
          -- For LSP Settings Type Annotations: https://github.com/neovim/nvim-lspconfig#lsp-settings-type-annotations
          vim.api.nvim_get_runtime_file('lua/lspconfig', false)[1],
        },
      },
    },
  },
}
