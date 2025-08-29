-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

require('lazy').setup({

  -- Essential plugins
  --[[ MiniVim (Group of plugins) Includes:
      * mini.ai (Better arround/inside textobjects) 
      * mini.surround (Add/delete/replace surroundings i.e parentheses, brackets, etc)
      * mini.statusline (Statusline i.e bottom bar)
      * mini.files (file explorer with buffers) 
  ]]
  { import = 'core.plugins' },

  -- LSP Plugins
  require 'lsp.lsp',
  require 'lsp.go',
  { import = 'lsp.plugins' },

  -- Git Plugins
  { import = 'git.plugins' },
  -- AI Plugins
  { import = 'ai.plugins' },
  -- SuperMaven for AI completions

  -- Avante.nvim for AI chat and agentic features
  -- require 'ai.plugins.avante',
  --
  -- Aesthetics Plugins
  require 'aesthetics.colorscheme',
  { import = 'aesthetics.plugins' },

  -- Other Plugins
  { import = 'utils.plugins' },
}, {
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
})
