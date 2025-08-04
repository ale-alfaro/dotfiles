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

-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
-- NOTE: Here is where you install your plugins.
require('lazy').setup({

  -- Colorscheme
  require 'colorscheme',
  require 'custom.plugins.lualine',
  require 'custom.plugins.noice',

  -- Essential plugins
  --[[ MiniVim (Group of plugins) Includes:
      * mini.ai (Better arround/inside textobjects) 
      * mini.surround (Add/delete/replace surroundings i.e parentheses, brackets, etc)
      * mini.statusline (Statusline i.e bottom bar)
      * mini.files (file explorer with buffers) 
  ]]
  --
  require 'kickstart.plugins.minivim',
  -- Treesitter for syntax highlighting and AST parsing
  require 'kickstart.plugins.treesitter',
  -- DAP debugger for Go out of the box but can be extended to other languages
  require 'kickstart.plugins.debug',
  -- Whickey for UI bottom bar to look at keymaps
  require 'kickstart.plugins.whichkey',
  -- Fuzzy finder for files and buffers
  require 'kickstart.plugins.telescope',

  -- LSP Plugins
  require 'lsp.lsp',
  require 'kickstart.plugins.autoformat',
  require 'lsp.plugins.completions',

  -- AI Plugins
  -- SuperMaven for AI completions
  require 'ai.plugins.supermaven',

  -- Avante.nvim for AI chat and agentic features
  -- require 'ai.plugins.avante',
  --
  -- Other Plugins
  -- Highlight todo, notes, etc in comments
  require 'kickstart.plugins.todo-comment',
  -- Indentation guides (i.e vertical lines that go from the top to bottom bracket)
  require 'kickstart.plugins.indent_line',
  -- Linting for Lua, Python, etc
  require 'kickstart.plugins.lint',
  -- Auto generated pairs of brackets
  require 'kickstart.plugins.autopairs',
  -- Gitsigns for showing git diff in the gutter and git aliases
  require 'kickstart.plugins.gitsigns', -- adds gitsigns recommend keymaps

  -- Detect tabstop and shiftwidth automatically
  -- 'NMAC427/guess-indent.nvim',

  -- Unix helper commands such as :Mkdir and :Move
  -- Vim shiftwidth and tabstop automatically
  -- 'tpope/vim-eunuch',
  --'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
  --
  -- File tree explorer (neo-tree) in the sidebar
  -- require 'kickstart.plugins.neo-tree',
  --
  -- Harpoon for managing bookmarks
  --require 'custom.plugins.harpoon',
  --
  -- Vim game for practicing Vim skills
  'theprimeagen/vim-be-good',

  -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --    This is the easiest way to modularize your config.
  --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  --  { import = 'custom.plugins' },
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
