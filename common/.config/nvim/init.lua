_G.Config = {}


-- General ====================================================================
vim.g.mapleader   = ' '            -- Use `<Space>` as <Leader> key
vim.g.localleader = '`'            -- Use `<Space>` as <Leader> key
vim.o.mouse       = 'a'            -- Enable mouse
vim.o.mousescroll = 'ver:25,hor:6' -- Customize mouse scroll
vim.o.switchbuf   = 'usetab'       -- Use already opened buffers when switching
vim.o.undofile    = true           -- Enable persistent undo

vim.opt.number    = true
vim.o.shada       = "'100,<50,s10,:1000,/100,@100,h" -- Limit ShaDa file (for startup)
-- -- Enable all filetype plugins and syntax (if not enabled, for better startup)
vim.cmd('filetype plugin indent on')
if vim.fn.exists('syntax_on') ~= 1 then vim.cmd('syntax enable') end
--
-- -- Editing ====================================================================
vim.o.autoindent     = true             -- Use auto indent
vim.o.expandtab      = true             -- Convert tabs to spaces
vim.o.formatoptions  = 'rqnl1j'         -- Improve comment editing
vim.o.ignorecase     = false            -- Ignore case during search
vim.o.incsearch      = true             -- Show search matches while typing
vim.o.infercase      = true             -- Infer case in built-in completion
vim.o.iskeyword      = '@,48-57,_,192-255,-' -- Treat dash as `word` textobject part
--
-- -- Pattern for a start of numbered list (used in `gw`). This reads as
-- -- "Start of list item is: at least one special character (digit, -, +, *)
-- -- possibly followed by punctuation (. or `)`) followed by at least one space".
vim.o.formatlistpat  = [[^\s*[0-9\-\+\*]\+\([\.\)]\)*\s\+]]
--
-- -- Built-in completion
vim.o.complete       = '.,w,b,kspell'               -- Use less sources
vim.o.completeopt    = 'menuone,noselect,fuzzy,nosort' -- Use custom behavior
vim.opt.autowrite    = true                         -- Enable auto write
-- only set clipboard if not in ssh, to make sure the OSC 52
-- integration works automatically.
vim.opt.clipboard    = vim.env.SSH_TTY and "" or "unnamedplus" -- Sync with system clipboard
-- vim.opt.completevim.o = "menu,menuone,noselect"
vim.opt.conceallevel = 2                                    -- Hide * markup for bold and italic, but not markers with substitutions
vim.opt.confirm      = true                                 -- Confirm to save changes before exiting modified buffer
vim.opt.cursorline   = true                                 -- Enable highlighting of the current line
vim.opt.expandtab    = true                                 -- Use spaces instead of tabs
vim.opt.fillchars    = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
vim.o.foldlevel      = 99
vim.o.foldmethod     = "indent"
vim.o.foldtext       = ""
vim.o.grepformat     = "%f:%l:%c:%m"
vim.o.grepprg        = "rg --vimgrep"
vim.o.ignorecase     = true  -- Ignore case
vim.o.inccommand     = "nosplit" -- preview incremental substitute
vim.o.jumpoptions    = "view"
vim.o.laststatus     = 3     -- global statusline
vim.o.linebreak      = true  -- Wrap lines at convenient points
vim.o.list           = true  -- Show some invisible characters (tabs...
vim.o.pumblend       = 10    -- Popup blend
vim.o.pumheight      = 10    -- Maximum number of entries in a popup
vim.o.relativenumber = true  -- Relative line numbers
vim.o.ruler          = false -- Disable the default ruler
vim.o.scrolloff      = 4     -- Lines of context
vim.o.shiftround     = true  -- Round indent
vim.o.shiftwidth     = 2     -- Size of an indent
vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })
-- vim.o.showmode = false -- Dont show mode since we have a statusline
vim.o.sidescrolloff = 8                         -- Columns of context
vim.o.signcolumn = "yes"                        -- Always show the signcolumn, otherwise it would shift the text each time
vim.o.smartcase = true                          -- Don't ignore case with capitals
vim.o.smartindent = true                        -- Insert indents automatically
vim.opt.spelllang = { "en" }
vim.o.splitbelow = true                         -- Put new windows below current
vim.o.splitkeep = "screen"
vim.o.splitright = true                         -- Put new windows right of current
-- vim.o.statuscolumn = [[%!v:lua.LazyVim.statuscolumn()]]
vim.o.tabstop = 2                               -- Number of spaces tabs count for
vim.o.termguicolors = true                      -- True color support
vim.o.timeoutlen = vim.g.vscode and 1000 or 300 -- Lower than default (1000) to quickly trigger which-key
vim.o.undofile = true
vim.o.undolevels = 10000
vim.o.updatetime = 200               -- Save swap file and trigger CursorHold
vim.o.virtualedit = "block"          -- Allow cursor to move where there is no text in visual block mode
vim.o.wildmode = "longest:full,full" -- Command-line completion mode
vim.o.winminwidth = 5                -- Minimum window width
-- vim.o.wrap = false -- Disable line wrap
-- vim.o.statuscolumn = [[%!v:lua.require'snacks.statuscolumn'.get()]]
--[[
-- Backup you shit!
										*backup-table*
'backup' 'writebackup'	action	~
   off	     off	no backup made
   off	     on		backup current file, deleted afterwards (default)
   on	     off	delete old backup, backup current file
   on	     on		delete old backup, backup current file
--]]
vim.o.backup = true
vim.o.writebackup = true
vim.o.backupdir = '/tmp/'

_G.Utils = require("custom.utils")



local diagnostic_opts = {
  -- Show signs on top of any other sign, but only for warnings and errors
  signs = { priority = 9999, severity = { min = 'WARN', max = 'ERROR' } },

  -- Show all diagnostics as underline (for their messages type `<Leader>ld`)
  underline = { severity = { min = 'HINT', max = 'ERROR' } },

  -- Show more details immediately for errors on the current line
  virtual_lines = false,
  virtual_text = {
    current_line = true,
    severity = { min = 'ERROR', max = 'ERROR' },
  },

  -- Don't update diagnostics when typing
  update_in_insert = false,
}
vim.diagnostic.config(diagnostic_opts)
local has_vim_pack = false
if vim.fn.has('nvim-0.12') == 1 then
  _G.Utils.has_vim_pack = true

  vim.pack.add({
    -- Core from original list
    { src = "https://github.com/chentoast/marks.nvim" },
    { src = "https://github.com/stevearc/oil.nvim" },
    { src = "https://github.com/nvim-tree/nvim-web-devicons" },
    { src = "https://github.com/aznhe21/actions-preview.nvim" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter",             version = "main", build = ":TSUpdate" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
    { src = "https://github.com/nvim-telescope/telescope.nvim",               version = "0.1.8" },
    { src = "https://github.com/nvim-telescope/telescope-ui-select.nvim" },
    { src = "https://github.com/jvgrootveld/telescope-zoxide"},
    {src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim"},
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/neovim/nvim-lspconfig" },
    { src = "https://github.com/L3MON4D3/LuaSnip" },
    { src = "https://github.com/rafamadriz/friendly-snippets" },
    { src = "https://github.com/LinArcX/telescope-env.nvim" },
    { src = "https://github.com/nvim-mini/mini.nvim" },

    -- UI & UX
    { src = "https://github.com/folke/tokyonight.nvim" },
    { src = "https://github.com/folke/which-key.nvim" },
    { src = "https://github.com/folke/flash.nvim" },
    { src = "https://github.com/folke/trouble.nvim" },
    { src = "https://github.com/mrjones2014/smart-splits.nvim" },

    -- Completion
    -- { src = "https://github.com/Saghen/blink.cmp" },

    -- Tooling & Languages
    { src = "https://github.com/stevearc/conform.nvim" },
    { src = "https://github.com/mfussenegger/nvim-lint" },
    { src = "https://github.com/benomahony/uv.nvim" },
    { src = "https://github.com/obsidian-nvim/obsidian.nvim" },

    -- AI & Code Companion
    { src = "https://github.com/olimorris/codecompanion.nvim" },
    { src = "https://github.com/lalitmee/codecompanion-spinners.nvim" },
    { src = "https://github.com/ravitemer/codecompanion-history.nvim" },

    -- Dev
    { src = "https://github.com/folke/lazydev.nvim" },
    { src = "https://github.com/Bilal2453/luvit-meta" },
    { src = "https://github.com/justinsgithub/wezterm-types" },
  })

  require('config.10-autocommands')
  require('config.20-keymaps')
  require('plugin.40_plugins')
  require('plugin.50_extras')
else
  vim.notify('Neovim v0.12 is required for this config!')
end
