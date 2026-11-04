---@type vim.lsp.Config
return {
  cmd = { 'emmylua_ls' },
  filetypes = { 'lua' },

  -- Sets the workspace "root" to the directory where any of these files is found.
  -- Files sharing a root will reuse the LSP client/connection.
  -- Nested lists indicate equal priority, see |vim.lsp.Config|.
  root_markers = { { '.emmyrc.json', '.luarc.json' }, '.git' },
  workspace_required = false,
  ---@type lspconfig.settings.emmylua_ls
  settings = {
    emmylua = {
      runtime = {
        version = "LuaJIT",
        requirePattern = {
          "lua/?.lua",
          "lua/?/init.lua",
          "?/lua/?.lua",
          "?/lua/?/init.lua",
        },
      },
      codeLens = { enable = true },

      diagnostics = {
        globals = {
          "vim",
          "VimRc",
        },
      },
      completion = {
        autoRequire = true,
        callSnippet = false,
        postfix = "@",
      },
      doc = {
        syntax = "md",
      },
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
