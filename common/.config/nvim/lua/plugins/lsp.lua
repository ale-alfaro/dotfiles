return {
  {
    'neovim/nvim-lspconfig',
    -- opts = {
    --   -- options for vim.diagnostic.config()
    --   ---@type vim.diagnostic.Opts
    --   -- diagnostics = {
    --   --   underline = true,
    --   --   update_in_insert = false,
    --   --   virtual_text = {
    --   --     spacing = 4,
    --   --     source = 'if_many',
    --   --     prefix = '●',
    --   --     -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
    --   --     -- prefix = "icons",
    --   --   },
    --   --   severity_sort = true,
    --   --   signs = {
    --   --     text = {
    --   --       [vim.diagnostic.severity.ERROR] = LazyVim.config.icons.diagnostics.Error,
    --   --       [vim.diagnostic.severity.WARN] = LazyVim.config.icons.diagnostics.Warn,
    --   --       [vim.diagnostic.severity.HINT] = LazyVim.config.icons.diagnostics.Hint,
    --   --       [vim.diagnostic.severity.INFO] = LazyVim.config.icons.diagnostics.Info,
    --   --     },
    --   --   },
    --   -- },
    --   -- Enable this to enable the builtin LSP inlay hints on Neovim.
    --   -- Be aware that you also will need to properly configure your LSP server to
    --   -- provide the inlay hints.
    --   inlay_hints = {
    --     enabled = true,
    --     exclude = { 'vue' }, -- filetypes for which you don't want to enable inlay hints
    --   },
    --   -- Enable this to enable the builtin LSP code lenses on Neovim.
    --   -- Be aware that you also will need to properly configure your LSP server to
    --   -- provide the code lenses.
    --   codelens = {
    --     enabled = true,
    --   },
    --   -- Enable this to enable the builtin LSP folding on Neovim.
    --   -- Be aware that you also will need to properly configure your LSP server to
    --   -- provide the folds.
    --   folds = {
    --     enabled = true,
    --   },
    --   -- add any global capabilities here
    --   -- capabilities = {
    --   --   workspace = {
    --   --     fileOperations = {
    --   --       didRename = true,
    --   --       willRename = true,
    --   --     },
    --   --   },
    --   -- },
    --   -- options for vim.lsp.buf.format
    --   -- `bufnr` and `filter` is handled by the LazyVim formatter,
    --   -- but can be also overridden when specified
    --   -- format = {
    --   --   formatting_options = nil,
    --   --   timeout_ms = nil,
    --   -- },
    --   -- LSP Server Settings
    --   ---@alias lazyvim.lsp.Config vim.lsp.Config|{mason?:boolean, enabled?:boolean}
    --   ---@type table<string, lazyvim.lsp.Config|boolean>
    --
    -- },
    --
    ---@class PluginLspOpts
    opts = function(_, opts)
      -- opts.servers = python_lsp_config
      opts.servers = {

        lua_ls = {
          -- mason = false, -- set to false if you don't want this server to be installed with mason
          -- Use this to add any additional keymaps
          -- for specific lsp servers
          -- ---@type LazyKeysSpec[]
          -- keys = {},
          settings = {
            Lua = {
              --     workspace = {
              --       checkThirdParty = false,
              --     },
              --     codeLens = {
              --       enable = true,
              --     },
              --     completion = {
              --       callSnippet = 'Replace',
              --     },
              --     doc = {
              --       privateName = { '^_' },
              --     },
              hint = {
                --       enable = true,
                setType = true,
                --       paramType = true,
                --       paramName = 'Disable',
                --       semicolon = 'Disable',
                --       arrayIndex = 'Disable',
              },
            },
          },
        },
        stylua = {},
        bashls = {},
      }
      vim.lsp.enable 'lua_ls'
      vim.lsp.enable 'bashls'
      vim.lsp.enable 'stylua'
    end,
  },
  {

    'mason-org/mason.nvim',
    enabled = false,
  },

  {

    'mason-org/mason-lspconfig.nvim',
    enabled = false,
  },
}
