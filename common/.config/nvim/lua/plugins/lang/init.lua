return {
  {
    'neovim/nvim-lspconfig',

    ---@param opts PluginLspOpts
    opts = function(_, opts)
      opts = opts or {}
      -- vim.tbl_deep_extend('force', opts.servers, {
      opts.servers = {
        stylua = { enabled = false },
        lua_ls = {
          cmd = { 'lua-language-server' },
          filetypes = { 'lua' },
          root_markers = {
            '.luarc.json',
            '.luarc.jsonc',
            '.luacheckrc',
            '.stylua.toml',
            'stylua.toml',
            'selene.toml',
            'selene.yml',
            '.git',
          },
          -- mason = false, -- set to false if you don't want this server to be installed with mason
          -- Use this to add any additional keymaps
          -- for specific lsp servers
          -- ---@type LazyKeysSpec[]
          -- keys = {},
          settings = {
            Lua = {
              workspace = {
                checkThirdParty = false,
              },
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
        },
      }
      vim.lsp.enable 'lua_ls'
    end,
  },
}
