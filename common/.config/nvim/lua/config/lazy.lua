local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup {
  spec = {
    -- add LazyVim and import its plugins
    { 'LazyVim/LazyVim', import = 'lazyvim.plugins' },
    -- import/override with your plugins
    { import = 'plugins' },
    { import = 'custom' },
    --
    -- -- LSP Plugins
    -- require 'custom.ai_chatbuffer_enhance',
    -- require 'lsp.go',
    -- { import = 'lsp.plugins' },
    --
    -- -- Git Plugins
    -- { import = 'git.plugins' },
    --
    -- -- Avante.nvim for AI chat and agentic features
    -- -- require 'ai.plugins.avante',
    -- --
    -- -- Aesthetics Plugins
    -- require 'aesthetics.colorscheme',
    -- { import = 'aesthetics.plugins' },
    --
    -- -- Other Plugins
    -- { import = 'utils.plugins' },
  },

  -- dev = {
  --   -- Directory where you store your local plugin projects. If a function is used,
  --   -- the plugin directory (e.g. `~/projects/plugin-name`) must be returned.
  --   ---@type string | fun(plugin: LazyPlugin): string
  --   path = vim.fn.stdpath 'config' .. '/lua/custom',
  --   ---@type string[] plugins that match these patterns will use your local versions instead of being fetched from GitHub
  --   patterns = {}, -- For example {"folke"}
  --   fallback = false, -- Fallback to git when local plugin doesn't exist
  -- },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  install = { colorscheme = { 'tokyonight', 'habamax' } },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        'gzip',
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
      },
    },
  },

  custom_keys = {
    -- You can define custom key maps here. If present, the description will
    -- be shown in the help menu.
    -- To disable one of the defaults, set it to false.

    ['<C-l>'] = {
      function(plugin)
        require('lazy.util').float_term({ 'lazygit', 'log' }, {
          cwd = plugin.dir,
        })
      end,
      desc = 'Open lazygit log',
    },

    ['<C-i>'] = {
      function(plugin)
        vim.notify(vim.inspect(plugin), {
          title = 'Inspect ' .. plugin.name,
          lang = 'lua',
        })
      end,
      desc = 'Inspect Plugin',
    },

    ['<C-t>'] = {
      function(plugin)
        require('lazy.util').float_term(nil, {
          cwd = plugin.dir,
        })
      end,
      desc = 'Open terminal in plugin dir',
    },
  },
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
}
