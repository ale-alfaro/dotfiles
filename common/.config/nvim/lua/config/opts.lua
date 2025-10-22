-- General ====================================================================
vim.g.mapleader = ' ' -- Use `<Space>` as <Leader> key
vim.g.localleader = ' ' -- Use `<Space>` as <Leader> key
-- vim.o.mouse = 'a'                  -- Enable mouse
vim.o.mousescroll = 'ver:25,hor:6' -- Customize mouse scroll
vim.o.switchbuf = 'usetab' -- Use already opened buffers when switching
-- vim.o.undofile = true              -- Enable persistent undo

vim.opt.number = true
vim.o.shada = "'100,<50,s10,:1000,/100,@100,h" -- Limit ShaDa file (for startup)
-- -- Enable all filetype plugins and syntax (if not enabled, for better startup)
-- vim.cmd 'filetype plugin indent on'
-- if vim.fn.exists 'syntax_on' ~= 1 then
--   vim.cmd 'syntax enable'
-- end
--
-- -- Editing ====================================================================
vim.o.autoindent = true -- Use auto indent
vim.o.expandtab = true -- Convert tabs to spaces
-- vim.o.formatoptions = 'rqnl1j'          -- Improve comment editing
-- vim.o.ignorecase = false                -- Ignore case during search
-- vim.o.incsearch = true                  -- Show search matches while typing
-- vim.o.infercase = true                  -- Infer case in built-in completion
vim.o.iskeyword = '@,48-57,_,192-255,-' -- Treat dash as `word` textobject part
--
-- -- Pattern for a start of numbered list (used in `gw`). This reads as
-- -- "Start of list item is: at least one special character (digit, -, +, *)
-- -- possibly followed by punctuation (. or `)`) followed by at least one space".
vim.o.formatlistpat = [[^\s*[0-9\-\+\*]\+\([\.\)]\)*\s\+]]
--
-- -- Built-in completion
vim.o.complete = '.,w,b,kspell' -- Use less sources
-- vim.o.completeopt = 'menuone,noselect,fuzzy,nosort' -- Use custom behavior
-- vim.opt.autowrite = true                            -- Enable auto write
-- only set clipboard if not in ssh, to make sure the OSC 52
-- integration works automatically.
vim.opt.clipboard = vim.env.SSH_TTY and '' or 'unnamedplus' -- Sync with system clipboard
-- vim.opt.completevim.o = "menu,menuone,noselect"
vim.opt.conceallevel = 2 -- Hide * markup for bold and italic, but not markers with substitutions
-- vim.opt.confirm = true                                      -- Confirm to save changes before exiting modified buffer
vim.opt.cursorline = true -- Enable highlighting of the current line
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.fillchars = {
  foldopen = '',
  foldclose = '',
  fold = ' ',
  foldsep = ' ',
  diff = '╱',
  eob = ' ',
}
vim.o.foldlevel = 99
vim.o.foldmethod = 'indent'
vim.o.foldtext = ''
vim.o.grepformat = '%f:%l:%c:%m'
vim.o.grepprg = 'rg --vimgrep'
vim.o.inccommand = 'nosplit' -- preview incremental substitute
vim.o.jumpoptions = 'view'
vim.o.laststatus = 3 -- global statusline
-- vim.o.linebreak = true       -- Wrap lines at convenient points
-- vim.o.list = true            -- Show some invisible characters (tabs...
-- vim.o.pumblend = 10          -- Popup blend
-- vim.o.pumheight = 10         -- Maximum number of entries in a popup
-- vim.o.relativenumber = true  -- Relative line numbers
-- vim.o.ruler = false          -- Disable the default ruler
vim.o.scrolloff = 4 -- Lines of context
vim.o.shiftround = true -- Round indent
vim.o.shiftwidth = 2 -- Size of an indent
-- vim.opt.shortmess:append { W = true, I = true, c = true, C = true }
-- vim.o.showmode = false -- Dont show mode since we have a statusline
vim.o.sidescrolloff = 8 -- Columns of context
vim.o.signcolumn = 'yes' -- Always show the signcolumn, otherwise it would shift the text each time
-- vim.o.smartcase = true                          -- Don't ignore case with capitals
-- vim.o.smartindent = true                        -- Insert indents automatically
vim.opt.spelllang = { 'en' }
-- vim.o.splitbelow = true                         -- Put new windows below current
-- vim.o.splitkeep = 'screen'
-- vim.o.splitright = true                         -- Put new windows right of current
vim.o.tabstop = 2 -- Number of spaces tabs count for
-- vim.o.termguicolors = true                      -- True color support
vim.o.timeoutlen = vim.g.vscode and 1000 or 300 -- Lower than default (1000) to quickly trigger which-key
vim.o.undolevels = 10000
vim.o.updatetime = 200 -- Save swap file and trigger CursorHold
-- vim.o.virtualedit = 'block'          -- Allow cursor to move where there is no text in visual block mode
vim.o.wildmode = 'longest:full,full' -- Command-line completion mode
vim.o.winminwidth = 5 -- Minimum window width
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
-- vim.o.backup = true
-- vim.o.writebackup = true
-- vim.o.backupdir = '/tmp/'
