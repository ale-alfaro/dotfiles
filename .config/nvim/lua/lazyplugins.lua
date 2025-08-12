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
  --
  -- require 'core.plugins.minivim',
  -- require 'core.plugins.minifiles',
  -- DAP debugger for Go out of the box but can be extended to other languages
  -- require 'core.plugins.debug',
  -- Whickey for UI bottom bar to look at keymaps
  -- Fuzzy finder for files and buffers
  -- require 'core.plugins.telescope',

  -- Multiplexer for managing multiple windows with Zellij
  require 'multiplexer.plugins.smart-splits',

  -- LSP Plugins
  require 'lsp.lsp',
  require 'lsp.go',
  { import = 'lsp.plugins' },
  -- require 'kickstart.plugins.autoformat',
  -- require 'lsp.plugins.completions',
  -- -- Treesitter for syntax highlighting and AST parsing
  -- require 'kickstart.plugins.treesitter',
  -- -- Linting for Lua, Python, etc
  -- require 'kickstart.plugins.lint',

  -- Git Plugins
  -- Neogit is the main git client plugin for Neovim
  require 'git.plugins.neogit',
  -- Diffview is a plugin for viewing and comparing git diffs
  require 'git.plugins.diffview',
  -- Gitsigns for showing git diff in the gutter and git aliases
  require 'git.plugins.gitsigns',

  -- AI Plugins
  -- SuperMaven for AI completions
  require 'ai.plugins.supermaven',

  -- Avante.nvim for AI chat and agentic features
  -- require 'ai.plugins.avante',
  --
  -- Aesthetics Plugins
  require 'aesthetics.colorscheme',
  { import = 'aesthetics.plugins' },
  -- Noice for general UI improvements
  -- require 'custom.plugins.noice',
  -- -- Highlight todo, notes, etc in comments
  -- require 'kickstart.plugins.todo-comment',
  -- -- Indentation guides (i.e vertical lines that go from the top to bottom bracket)
  -- require 'kickstart.plugins.indent_line',
  -- -- Auto generated pairs of brackets
  -- require 'kickstart.plugins.autopairs',
  -- -- Statusline i.e bottom bar
  -- require 'custom.plugins.lualine',

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
