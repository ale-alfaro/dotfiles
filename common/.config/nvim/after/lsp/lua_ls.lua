-- ┌────────────────────┐
-- │ LSP config example │
-- └────────────────────┘
--
-- This file contains configuration of 'lua_ls' language server.
-- Source: https://github.com/LuaLS/lua-language-server
-- It is used by `:h vim.lsp.enable()` and `:h vim.lsp.config()`.
-- See `:h vim.lsp.Config` and `:h vim.lsp.ClientConfig` for all available fields.
--
-- This config is designed for Lua's activity around Neovim. It provides only
-- basic config and can be further improved.
return {
  -- LuaLS Structure of these settings comes from LuaLS, not Neovim
  settings = {
    Lua = {
      -- Define runtime properties. Use 'LuaJIT', as it is built into Neovim.
      runtime = {
        version = 'LuaJIT',
        path = {
          'lua/?.lua',
          'lua/?/init.lua',
          '$XDG_DATA_HOME/nvim/site/pack/core/opt/?/lua/?.lua',
          '$XDG_DATA_HOME/nvim/site/pack/core/opt/?/lua/?/?.lua',
          '$XDG_DATA_HOME/nvim/site/pack/core/opt/?/lua/?/init.lua',
        },

      },
      workspace = {
        -- Don't analyze code from submodules
        -- ignoreSubmodules = true,
        -- Add Neovim's methods for easier code writing
        library = {
          vim.env.VIMRUNTIME,
          '${3rd}/luv/library'

        },
        checkThirdParty = false,
      },
      --
      codeLens = {
        enable = true,
      },
      completion = {
        callSnippet = 'Replace',
      },
      doc = {
        privateName = { '^_' },
      },
      hint = {
        enable = true,
        setType = false,
        paramType = true,
        paramName = 'Disable',
        semicolon = 'Disable',
        arrayIndex = 'Disable',
      },
    },
  },
}
