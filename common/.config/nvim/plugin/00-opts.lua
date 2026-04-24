-- General ====================================================================
vim.g.mapleader = ' ' -- Use `<Space>` as <Leader> key
vim.g.maplocalleader = ','
vim.o.mouse = 'a' -- Enable mouse
vim.o.mousescroll = 'ver:25,hor:6' -- Customize mouse scroll
vim.opt.number = true
vim.o.switchbuf = 'usetab' -- Use already opened buffers when switching
vim.o.undofile = true -- Enable persistent undo

-- vim.g.clipboard = {
--   name = 'Tmux',
--   paste = {
--     ['+'] = { 'tmux', 'save-buffer', '-' },
--     ['*'] = { 'tmux', 'save-buffer', '-' },
--   },
--   copy = {
--     ['+'] = { 'tmux', 'load-buffer', '-' },
--     ['*'] = { 'tmux', 'load-buffer', '-' },
--   },
-- }
vim.opt.clipboard = 'unnamedplus' -- Sync with system clipboard
vim.o.dict = '/home/alealfaro/.config/obsidian/Custom Dictionary.txt'
vim.o.gdefault = true -- g is on by default when substituting with s/pattern/replace
vim.o.grepformat = '%f:%l:%c:%m'
vim.o.grepprg = 'rg --vimgrep'
vim.o.inccommand = 'nosplit' -- preview incremental substitute
vim.o.jumpoptions = 'clean'

vim.o.shada = "'100,<50,s10,:1000,/100,@100,h" -- Limit ShaDa file (for startup)

vim.cmd 'filetype plugin indent on'
if vim.fn.exists 'syntax_on' ~= 1 then
  vim.cmd 'syntax enable'
end
-- UI =========================================================================
vim.o.breakindent = true -- Indent wrapped lines to match line start
vim.o.breakindentopt = 'list:-1' -- Add padding for lists (if 'wrap' is set)
vim.o.colorcolumn = '+1' -- Draw column on the right of maximum width
vim.o.cursorline = true -- Enable current line highlighting
vim.o.linebreak = true -- Wrap lines at 'breakat' (if 'wrap' is set)
vim.o.list = true -- Show helpful text indicators
vim.o.number = true -- Show line numbers
vim.o.cmdheight = 2
--- Completion menu
vim.o.pumheight = 10 -- Make popup menu smaller
vim.o.pummaxwidth = 100 -- Make popup menu not too wide
vim.o.pumblend = 10
vim.o.pumborder = 'rounded' -- 'rounded'|'single'

vim.o.ruler = false -- Don't show cursor coordinates
vim.o.shortmess = 'CFOSWaco' -- Disable some built-in completion messages
-- vim.opt.shortmess:append {
--   w = true,
--   s = true,
-- }
vim.o.showmode = false -- Don't show mode in command line
vim.o.signcolumn = 'yes' -- Always show signcolumn (less flicker)
vim.o.splitbelow = true -- Horizontal splits will be below
vim.o.splitkeep = 'screen' -- Reduce scroll during window split
vim.o.splitright = true -- Vertical splits will be to the right
vim.o.winborder = 'single' -- Use border in floating windows
vim.o.wrap = false -- Don't visually wrap lines (toggle with \w)
vim.opt.conceallevel = 2 -- Hide * markup for bold and italic, but not markers with substitutions

vim.o.cursorlineopt = 'screenline,number' -- Show cursor line per screen line

-- Special UI symbols. More is set via 'mini.basics' later.
vim.o.fillchars = 'eob: ,fold:╌'
vim.o.listchars = 'extends:…,nbsp:␣,precedes:…,tab:> '

-- Folds (see `:h fold-commands`, `:h zM`, `:h zR`, `:h zA`, `:h zj`)
vim.o.foldlevel = 10 -- Fold nothing by default; set to 0 or 1 to fold
-- vim.o.foldmethod = 'indent' -- Fold based on indent level
vim.o.foldmethod = 'expr' --- 'indent'| 'expr'
vim.o.foldexpr = 'v:lua.vim.lsp.foldexpr' -- Setting the default to LSP fold expr. Alternative is treesitter

vim.o.foldnestmax = 10 -- Limit number of fold levels
vim.o.foldtext = '' -- Show text under fold with its highlighting

-- vim.o.foldminlines = 50
-- vim.o.foldcolumn = 'auto'
-- vim.opt.fillchars = {
--   foldopen = '',
--   foldclose = '',
--   fold = ' ',
--   foldsep = ' ',
--   diff = '╱',
--   eob = ' ',
-- }
--
--
-- vim.o.laststatus = 3 -- global statusline
-- vim.o.winminwidth = 5 -- Minimum window width
-- vim.o.scrolloff = 4 -- Lines of context
-- vim.o.shiftround = true -- Round indent
-- vim.o.sidescrolloff = 8 -- Columns of context
-- vim.o.signcolumn = 'yes' -- Always show the signcolumn, otherwise it would shift the text each time
--
--
-- -- Editing ====================================================================
vim.o.autoindent = true -- Use auto indent
vim.o.expandtab = true -- Convert tabs to spaces
vim.o.iskeyword = '@,48-57,_,192-255,-' -- Treat dash as `word` textobject part
vim.o.incsearch = true -- Show search matches while typing
vim.o.infercase = true -- Infer case in built-in completion
vim.o.shiftwidth = 2 -- Use this number of spaces for indentation

vim.o.smartcase = true -- Respect case if search pattern has upper case
vim.o.smartindent = true -- Make indenting smart
vim.o.spelloptions = 'camel' -- Treat camelCase word parts as separate words
vim.o.tabstop = 2 -- Show tab as this number of spaces
vim.o.virtualedit = 'block' -- Allow going past end of line in blockwise mode
--
-- -- Pattern for a start of numbered list (used in `gw`). This reads as
-- -- "Start of list item is: at least one special character (digit, -, +, *)
-- -- possibly followed by punctuation (. or `)`) followed by at least one space".
vim.o.formatlistpat = [[^\s*[0-9\-\+\*]\+\([\.\)]\)*\s\+]]
--
-- -- Built-in completion
-- Built-in completion
vim.o.complete = '.,w,b,kspell' -- Use less sources
vim.o.completeopt = 'menuone,noselect,fuzzy,nosort' -- Use custom behavior
vim.o.completetimeout = 100 -- Limit sources delay

vim.o.autocomplete = true
vim.o.autocompletedelay = 100
--- Command Line completion
vim.o.wildmode = 'longest:full,full' -- Command-line completion mode
vim.o.wildignorecase = true
--- Misc

vim.o.undolevels = 10000
vim.o.timeoutlen = 300 --- Do not fuck with this option. You will feel it
vim.o.updatetime = 300
-- Diff mode settings.
-- Setting the context to a very large number disables folding.
vim.opt.diffopt:append 'vertical,context:99'

-- Status line.

-- Autocommands ===============================================================

-- Don't auto-wrap comments and don't insert comment leader after hitting 'o'.
-- Do on `FileType` to always override these changes from filetype plugins.
local f = function()
  vim.cmd 'setlocal formatoptions-=c formatoptions-=o'
end
VimRc.new_autocmd('FileType', f, nil, "Proper 'formatoptions'")

-- There are other autocommands created by 'mini.basics'. See 'plugin/30_mini.lua'.
