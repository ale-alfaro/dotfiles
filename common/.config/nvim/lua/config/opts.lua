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
vim.o.iskeyword = '@,48-57,_,192-255,-' -- Treat dash as `word` textobject part
--
-- -- Pattern for a start of numbered list (used in `gw`). This reads as
-- -- "Start of list item is: at least one special character (digit, -, +, *)
-- -- possibly followed by punctuation (. or `)`) followed by at least one space".
vim.o.formatlistpat = [[^\s*[0-9\-\+\*]\+\([\.\)]\)*\s\+]]
--
-- -- Built-in completion
vim.o.complete = '.,w,b,kspell' -- Use less sources
vim.opt.clipboard = vim.env.SSH_TTY and '' or 'unnamedplus' -- Sync with system clipboard
-- vim.opt.completevim.o = "menu,menuone,noselect"
vim.opt.conceallevel = 2 -- Hide * markup for bold and italic, but not markers with substitutions
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
vim.o.grepformat = '%f:%l:%c:%m'
vim.o.grepprg = 'rg --vimgrep'
vim.o.inccommand = 'nosplit' -- preview incremental substitute
vim.o.jumpoptions = 'view'
vim.o.laststatus = 3 -- global statusline
vim.o.scrolloff = 4 -- Lines of context
vim.o.shiftround = true -- Round indent
vim.o.shiftwidth = 2 -- Size of an indent
vim.o.sidescrolloff = 8 -- Columns of context
vim.o.signcolumn = 'yes' -- Always show the signcolumn, otherwise it would shift the text each time
vim.opt.spelllang = { 'en' }
vim.o.tabstop = 2 -- Number of spaces tabs count for
vim.o.timeoutlen = 300
vim.o.undolevels = 10000
vim.o.updatetime = 200 -- Save swap file and trigger CursorHold
vim.o.wildmode = 'longest:full,full' -- Command-line completion mode
vim.o.winminwidth = 5 -- Minimum window width
