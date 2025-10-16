
-- ┌──────────────────────────┐
-- │ Built-in Neovim behavior │
-- └──────────────────────────┘
--
-- This file defines Neovim's built-in behavior. The goal is to improve overall
-- usability in a way that works best with MINI.
--
-- Here `vim.o.xxx = value` sets default value of option `xxx` to `value`.
-- See `:h 'xxx'` (replace `xxx` with actual option name).
--
-- Option values can be customized on per buffer or window basis.
-- See 'after/ftplugin/' for common example.

-- stylua: ignore start
-- The next part (until `-- stylua: ignore end`) is aligned manually for easier
-- reading. Consider preserving this or remove `-- stylua` lines to autoformat.

-- Define config table to be able to pass data between scripts
_G.Config = {}


-- General ====================================================================
vim.g.mapleader = ' ' -- Use `<Space>` as <Leader> key
vim.g.localleader = '`' -- Use `<Space>` as <Leader> key
vim.o.mouse       = 'a'            -- Enable mouse
vim.o.mousescroll = 'ver:25,hor:6' -- Customize mouse scroll
vim.o.switchbuf   = 'usetab'       -- Use already opened buffers when switching
vim.o.undofile    = true           -- Enable persistent undo
--
vim.o.shada = "'100,<50,s10,:1000,/100,@100,h" -- Limit ShaDa file (for startup)
--
-- -- Enable all filetype plugins and syntax (if not enabled, for better startup)
-- vim.cmd('filetype plugin indent on')
if vim.fn.exists('syntax_on') ~= 1 then vim.cmd('syntax enable') end
--
-- -- UI =========================================================================
-- vim.o.breakindent    = true       -- Indent wrapped lines to match line start
-- vim.o.breakindentopt = 'list:-1'  -- Add padding for lists (if 'wrap' is set)
-- vim.o.colorcolumn    = '+1'       -- Draw column on the right of maximum width
-- vim.o.cursorline     = true       -- Enable current line highlighting
-- vim.o.linebreak      = true       -- Wrap lines at 'breakat' (if 'wrap' is set)
-- vim.o.list           = true       -- Show helpful text indicators
-- vim.o.number         = true       -- Show line numbers
-- vim.o.pumheight      = 10         -- Make popup menu smaller
-- vim.o.ruler          = false      -- Don't show cursor coordinates
-- vim.o.shortmess      = 'CFOSWaco' -- Disable some built-in completion messages
-- vim.o.showmode       = false      -- Don't show mode in command line
-- vim.o.signcolumn     = 'yes'      -- Always show signcolumn (less flicker)
-- vim.o.splitbelow     = true       -- Horizontal splits will be below
-- vim.o.splitkeep      = 'screen'   -- Reduce scroll during window split
-- vim.o.splitright     = true       -- Vertical splits will be to the right
-- vim.o.winborder      = 'single'   -- Use border in floating windows
-- vim.o.wrap           = false      -- Don't visually wrap lines (toggle with \w)
--
-- vim.o.cursorlineopt  = 'screenline,number' -- Show cursor line per screen line
--
-- -- Special UI symbols. More is set via 'mini.basics' later.
-- vim.o.fillchars = 'eob: ,fold:╌'
-- vim.o.listchars = 'extends:…,nbsp:␣,precedes:…,tab:> '
--
-- -- Folds (see `:h fold-commands`, `:h zM`, `:h zR`, `:h zA`, `:h zj`)
-- vim.o.foldlevel   = 10       -- Fold nothing by default; set to 0 or 1 to fold
-- vim.o.foldmethod  = 'indent' -- Fold based on indent level
-- vim.o.foldnestmax = 10       -- Limit number of fold levels
-- vim.o.foldtext    = ''       -- Show text under fold with its highlighting
--
-- -- Editing ====================================================================
-- vim.o.autoindent    = true    -- Use auto indent
-- vim.o.expandtab     = true    -- Convert tabs to spaces
vim.o.formatoptions = 'rqnl1j'-- Improve comment editing
-- vim.o.ignorecase    = true    -- Ignore case during search
-- vim.o.incsearch     = true    -- Show search matches while typing
-- vim.o.infercase     = true    -- Infer case in built-in completion
-- vim.o.shiftwidth    = 2       -- Use this number of spaces for indentation
-- vim.o.smartcase     = true    -- Respect case if search pattern has upper case
-- vim.o.smartindent   = true    -- Make indenting smart
-- vim.o.spelloptions  = 'camel' -- Treat camelCase word parts as separate words
-- vim.o.tabstop       = 2       -- Show tab as this number of spaces
-- vim.o.virtualedit   = 'block' -- Allow going past end of line in blockwise mode
--
-- vim.o.iskeyword = '@,48-57,_,192-255,-' -- Treat dash as `word` textobject part
--
-- -- Pattern for a start of numbered list (used in `gw`). This reads as
-- -- "Start of list item is: at least one special character (digit, -, +, *)
-- -- possibly followed by punctuation (. or `)`) followed by at least one space".
vim.o.formatlistpat = [[^\s*[0-9\-\+\*]\+[\.\)]*\s\+]]
--
-- -- Built-in completion
vim.o.complete    = '.,w,b,kspell'                  -- Use less sources
vim.o.completeopt = 'menuone,noselect,fuzzy,nosort' -- Use custom behavior
--
-- -- Autocommands ===============================================================
--
-- -- Define custom autocommand group and helper to create an autocommand.
-- -- Autocommands are Neovim's way to define actions that are executed on events
-- -- (like creating a buffer, setting an option, etc.).
-- --
-- -- See also:
-- -- - `:h autocommand`
-- -- - `:h nvim_create_augroup()`
-- -- - `:h nvim_create_autocmd()`
-- -- Don't auto-wrap comments and don't insert comment leader after hitting 'o'.
-- -- Do on `FileType` to always override these changes from filetype plugins.
--
-- -- There are other autocommands created by 'mini.basics'. See 'plugin/30_mini.lua'.
--
vim.opt.autowrite = true -- Enable auto write
-- only set clipboard if not in ssh, to make sure the OSC 52
-- integration works automatically.
vim.opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus" -- Sync with system clipboard
-- vim.opt.completevim.o = "menu,menuone,noselect"
vim.opt.conceallevel = 2 -- Hide * markup for bold and italic, but not markers with substitutions
vim.opt.confirm = true -- Confirm to save changes before exiting modified buffer
vim.opt.cursorline = true -- Enable highlighting of the current line
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
vim.o.foldlevel = 99
vim.o.foldmethod = "indent"
vim.o.foldtext = ""
-- vim.o.formatexpr = "v:lua.LazyVim.format.formatexpr()"
vim.o.grepformat = "%f:%l:%c:%m"
vim.o.grepprg = "rg --vimgrep"
vim.o.ignorecase = true -- Ignore case
vim.o.inccommand = "nosplit" -- preview incremental substitute
vim.o.jumpoptions = "view"
vim.o.laststatus = 3 -- global statusline
vim.o.linebreak = true -- Wrap lines at convenient points
vim.o.list = true -- Show some invisible characters (tabs...
vim.o.mouse = "a" -- Enable mouse mode
vim.o.number = true -- Print line number
vim.o.pumblend = 10 -- Popup blend
vim.o.pumheight = 10 -- Maximum number of entries in a popup
vim.o.relativenumber = true -- Relative line numbers
vim.o.ruler = false -- Disable the default ruler
vim.o.scrolloff = 4 -- Lines of context
vim.opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
vim.o.shiftround = true -- Round indent
vim.o.shiftwidth = 2 -- Size of an indent
vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })
vim.o.showmode = false -- Dont show mode since we have a statusline
vim.o.sidescrolloff = 8 -- Columns of context
vim.o.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time
vim.o.smartcase = true -- Don't ignore case with capitals
vim.o.smartindent = true -- Insert indents automatically
vim.o.smoothscroll = true
vim.opt.spelllang = { "en" }
vim.o.splitbelow = true -- Put new windows below current
vim.o.splitkeep = "screen"
vim.o.splitright = true -- Put new windows right of current
-- vim.o.statuscolumn = [[%!v:lua.LazyVim.statuscolumn()]]
vim.o.tabstop = 2 -- Number of spaces tabs count for
vim.o.termguicolors = true -- True color support
vim.o.timeoutlen = vim.g.vscode and 1000 or 300 -- Lower than default (1000) to quickly trigger which-key
vim.o.undofile = true
vim.o.undolevels = 10000
vim.o.updatetime = 200 -- Save swap file and trigger CursorHold
vim.o.virtualedit = "block" -- Allow cursor to move where there is no text in visual block mode
vim.o.wildmode = "longest:full,full" -- Command-line completion mode
vim.o.winminwidth = 5 -- Minimum window width
vim.o.wrap = false -- Disable line wrap
vim.o.statuscolumn = [[%!v:lua.require'snacks.statuscolumn'.get()]]

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


--
--

-- ┌─────────────────┐
-- │ Custom mappings │
-- └─────────────────┘
--
-- This file contains definitions of custom general and Leader mappings.

_G.Utils = require("custom.utils")
-- General mappings ===========================================================
-- Use this section to add custom general mappings. See `:h vim.keymap.set()`.

-- An example helper to create a Normal mode mapping
local map = vim.keymap.set
-- Paste linewise before/after current line
-- Usage: `yiw` to yank a word and `]p` to put it on the next line.
_G.Utils.nmap('[p', '<Cmd>exe "put! " . v:register<CR>', 'Paste Above')
_G.Utils.nmap(']p', '<Cmd>exe "put "  . v:register<CR>', 'Paste Below')

-- Many general mappings are created by 'mini.basics'. See 'plugin/30_mini.lua'

-- stylua: ignore start
-- The next part (until `-- stylua: ignore end`) is aligned manually for easier
-- reading. Consider preserving this or remove `-- stylua` lines to autoformat.

-- Leader mappings ============================================================

-- Neovim has the concept of a Leader key (see `:h <Leader>`). It is a configurable
-- key that is primarily used for "workflow" mappings (opposed to text editing).
-- Like "open file explorer", "create scratch buffer", "pick from buffers".
--
-- In 'plugin/10_options.lua' <Leader> is set to <Space>, i.e. press <Space>
-- whenever there is a suggestion to press <Leader>.
--
-- This config uses a "two key Leader mappings" approach: first key describes
-- semantic group, second key executes an action. Both keys are usually chosen
-- to create some kind of mnemonic.
-- Example: `<Leader>f` groups "find" type of actions; `<Leader>ff` - find files.
-- Use this section to add Leader mappings in a structural manner.
--
-- Usually if there are global and local kinds of actions, lowercase second key
-- denotes global and uppercase - local.
-- Example: `<Leader>fs` / `<Leader>fS` - find workspace/document LSP symbols.
--
-- Many of the mappings use 'mini.nvim' modules set up in 'plugin/30_mini.lua'.

-- Create a global table with information about Leader groups in certain modes.
-- This is used to provide 'mini.clue' with extra clues.
-- Add an entry if you create a new group.

-- Helpers for a more concise `<Leader>` mappings.
-- Most of the mappings use `<Cmd>...<CR>` string as a right hand side (RHS) in
-- an attempt to be more concise yet descriptive. See `:h <Cmd>`.
-- This approach also doesn't require the underlying commands/functions to exist
-- during mapping creation: a "lazy loading" approach to improve startup time.



-- b is for 'Buffer'. Common usage:
-- - `<Leader>bs` - create scratch (temporary) buffer
-- - `<Leader>ba` - navigate to the alternative buffer
-- - `<Leader>bw` - wipeout (fully delete) current buffer
local new_scratch_buffer = function()
  vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(true, true))
end

_G.Utils.nmapleader('ba', '<Cmd>b#<CR>',                                 'Alternate')
_G.Utils.nmapleader('bd', '<Cmd>lua MiniBufremove.delete()<CR>',         'Delete')
_G.Utils.nmapleader('bD', '<Cmd>lua MiniBufremove.delete(0, true)<CR>',  'Delete!')
_G.Utils.nmapleader('bs', new_scratch_buffer,                            'Scratch')
_G.Utils.nmapleader('bw', '<Cmd>lua MiniBufremove.wipeout()<CR>',        'Wipeout')
_G.Utils.nmapleader('bW', '<Cmd>lua MiniBufremove.wipeout(0, true)<CR>', 'Wipeout!')

map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
-- map("n", "<leader>bd", function()
--   Snacks.bufdelete()
-- end, { desc = "Delete Buffer" })
-- map("n", "<leader>bo", function()
--   Snacks.bufdelete.other()
-- end, { desc = "Delete Other Buffers" })
-- map("n", "<leader>bD", "<cmd>:bd<cr>", { desc = "Delete Buffer and Window" })
-- e is for 'Explore' and 'Edit'. Common usage:
-- - `<Leader>ed` - open explorer at current working directory
-- - `<Leader>ef` - open directory of current file (needs to be present on disk)
-- - `<Leader>ei` - edit 'init.lua'
-- - All mappings that use `edit_plugin_file` - edit 'plugin/' config files
local edit_plugin_file = function(filename)
  return string.format('<Cmd>edit %s/plugin/%s<CR>', vim.fn.stdpath('config'), filename)
end

-- Helpers for a more concise `<Leader>` mappings.
-- Most of the mappings use `<Cmd>...<CR>` string as a right hand side (RHS) in
-- an attempt to be more concise yet descriptive. See `:h <Cmd>`.
-- This approach also doesn't require the underlying commands/functions to exist
-- during mapping creation: a "lazy loading" approach to improve startup time.
_G.Utils.nmapleader('ei', '<Cmd>edit $MYVIMRC<CR>',                 'init.lua')
_G.Utils.nmap('q', '<nop>', "",{ noremap = true })
_G.Utils.nmap('Q', 'q', 'Record macro', { noremap = true })
_G.Utils.nmap('<M-q>', 'Q', 'Replay last register', { noremap = true })
-- Move to window using the <ctrl> hjkl keys
_G.Utils.nmap( '<C-h>', '<C-w>h', 'Go to Left Window', {remap = true })
_G.Utils.nmap( '<C-j>', '<C-w>j', 'Go to Lower Window',{ remap = true })
_G.Utils.nmap( '<C-k>', '<C-w>k', 'Go to Upper Window',{ remap = true })
_G.Utils.nmap( '<C-l>', '<C-w>l', 'Go to Right Window',{ remap = true })

-- Resize window using <ctrl> arrow keys
-- _G.Utils.nmap( '<C-Up>', '<cmd>resize +2<cr>', { desc = 'Increase Window Height' })
-- _G.Utils.nmap( '<C-Down>', '<cmd>resize -2<cr>', { desc = 'Decrease Window Height' })
-- _G.Utils.nmap( '<C-Left>', '<cmd>vertical resize -2<cr>', { desc = 'Decrease Window Width' })
-- _G.Utils.nmap( '<C-Right>', '<cmd>vertical resize +2<cr>', { desc = 'Increase Window Width' })
-- map({ 'n', 'v', 'x' }, '<leader>O', '<Cmd>restart<CR>', { desc = 'Restart vim.' })
map({ 'n', 'v', 'x' }, '<leader>ev', '<Cmd>edit $MYVIMRC<CR>', { desc = 'Edit ' .. vim.fn.expand '$MYVIMRC' })
map({ 'n', 'v', 'x' }, '<leader>ez', '<Cmd>e $ZDOTDIR<CR>', { desc = 'Edit .zshrc' })
map({ 'n', 'v', 'x' }, '<leader>eh', '<Cmd>e $XDG_CONFIG_HOME/hypr/hyprland<CR>', { desc = 'Edit Hyprland Config' })
map({ 'n', 'v', 'x' }, '<leader>ez', '<Cmd>e $JUSTFILE_HOME<CR>', { desc = 'Edit Global Justfiles' })
-- map({ 'n', 'v', 'x' }, '<leader>n', ':norm ', { desc = 'ENTER NORM COMMAND.' })
map({ 'n', 'v', 'x' }, '<leader>o', '<Cmd>source %<CR>', { desc = 'Source ' .. vim.fn.expand '$MYVIMRC' })
-- buffers
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next Buffer" })
--
-- -- Clear search and stop snippet on escape
-- map({ "i", "n", "s" }, "<esc>", function()
--   vim.cmd("noh")
--   LazyVim.cmp.actions.snippet_stop()
--   return "<esc>"
-- end, { expr = true, desc = "Escape and Clear hlsearch" })
--
-- Clear search, diff update and redraw
-- taken from runtime/lua/_editor.lua
map(
  "n",
  "<leader>ur",
  "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
  { desc = "Redraw / Clear hlsearch / Diff Update" }
)

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- Add undo break-points
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- save file
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

--keywordprg
map("n", "<leader>K", "<cmd>norm! K<cr>", { desc = "Keywordprg" })

-- better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- commenting
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

map("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })

-- new file
map("n", "<leader>fn", "<cmd>new<cr>", { desc = "New File" })

-- location list
map("n", "<leader>xl", function()
  local success, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
  if not success and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Location List" })

-- quickfix list
map("n", "<leader>xq", function()
  local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
  if not success and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Quickfix List" })

map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

-- formatting

-- diagnostic
local diagnostic_goto = function(next, severity)
  local go = next and vim.diagnostic.get_next or vim.diagnostic.get_prev
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function()
    go({ severity = severity })
  end
end
_G.Utils.nmap( "<leader>cd", vim.diagnostic.open_float, "Line Diagnostics" )
_G.Utils.nmap( "]d", diagnostic_goto(true), "Next Diagnostic")
_G.Utils.nmap( "[d", diagnostic_goto(false), "Prev Diagnostic")
_G.Utils.nmap( "]e", diagnostic_goto(true, "ERROR"), "Next Error")
_G.Utils.nmap( "[e", diagnostic_goto(false, "ERROR"), "Prev Error")
_G.Utils.nmap( "]w", diagnostic_goto(true, "WARN"), "Next Warning")
_G.Utils.nmap( "[w", diagnostic_goto(false, "WARN"), "Prev Warning")


-- e is for 'Explore' and 'Edit'. Common usage:
-- - `<Leader>ed` - open explorer at current working directory
-- - `<Leader>ef` - open directory of current file (needs to be present on disk)
-- - `<Leader>ei` - edit 'init.lua'
-- - All mappings that use `edit_plugin_file` - edit 'plugin/' config files
local explore_at_file = '<Cmd>lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>'
local explore_quickfix = function()
  for _, win_id in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.fn.getwininfo(win_id)[1].quickfix == 1 then return vim.cmd('cclose') end
  end
  vim.cmd('copen')
end

_G.Utils.nmapleader('ed', '<Cmd>lua MiniFiles.open()<CR>',          'Directory')
_G.Utils.nmap('\\',explore_at_file,  'Open file explorer quick')
_G.Utils.nmapleader('en', '<Cmd>lua MiniNotify.show_history()<CR>', 'Notifications')
_G.Utils.nmapleader('eq', explore_quickfix,                         'Quickfix')
-- l is for 'Language'. Common usage:
-- - `<Leader>ld` - show more diagnostic details in a floating window
-- - `<Leader>lr` - perform rename via LSP
-- - `<Leader>ls` - navigate to source definition of symbol under cursor
--
-- NOTE: most LSP mappings represent a more structured way of replacing built-in
-- LSP mappings (like `:h gra` and others). This is needed because `gr` is mapped
-- by an "replace" operator in 'mini.operators' (which is more commonly used).
local formatting_cmd = '<Cmd>lua require("conform").format({lsp_fallback=true})<CR>'

_G.Utils.nmapleader('la', '<Cmd>lua vim.lsp.buf.code_action()<CR>',     'Actions')
_G.Utils.nmapleader('ld', '<Cmd>lua vim.diagnostic.open_float()<CR>',   'Diagnostic popup')
_G.Utils.nmapleader('lf', formatting_cmd,                               'Format')
_G.Utils.nmapleader('li', '<Cmd>lua vim.lsp.buf.implementation()<CR>',  'Implementation')
_G.Utils.nmapleader('lh', '<Cmd>lua vim.lsp.buf.hover()<CR>',           'Hover')
_G.Utils.nmapleader('lr', '<Cmd>lua vim.lsp.buf.rename()<CR>',          'Rename')
_G.Utils.nmapleader('lr', '<Cmd>lua vim.lsp.buf.references()<CR>',      'References')
_G.Utils.nmapleader('ld', '<Cmd>lua vim.lsp.buf.definition()<CR>',      'Source definition')
_G.Utils.nmapleader('lt', '<Cmd>lua vim.lsp.buf.type_definition()<CR>', 'Type definition')

_G.Utils.xmapleader('lf', formatting_cmd, 'Format selection')

local nvim_config_path = vim.fn.stdpath('config')
vim.opt.rtp:append(nvim_config_path .. "/minimax")
