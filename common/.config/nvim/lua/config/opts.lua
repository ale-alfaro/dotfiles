-- General ====================================================================
vim.g.mapleader = ' ' -- Use `<Space>` as <Leader> key
vim.g.maplocalleader = ','
vim.o.mouse = 'a' -- Enable mouse
vim.o.mousescroll = 'ver:25,hor:6' -- Customize mouse scroll
vim.o.switchbuf = 'usetab' -- Use already opened buffers when switching
vim.o.undofile = true -- Enable persistent undo

vim.opt.number = true
vim.o.shada = "'100,<50,s10,:1000,/100,@100,h" -- Limit ShaDa file (for startup)
-- -- Enable all filetype plugins and syntax (if not enabled, for better startup)
vim.cmd 'filetype plugin indent on'
if vim.fn.exists 'syntax_on' ~= 1 then
  vim.cmd 'syntax enable'
end
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
---
vim.opt.clipboard = 'unnamedplus' -- Sync with system clipboard
vim.opt.conceallevel = 2 -- Hide * markup for bold and italic, but not markers with substitutions
vim.opt.cursorline = true -- Enable highlighting of the current line
vim.opt.fillchars = {
  foldopen = '',
  foldclose = '',
  fold = ' ',
  foldsep = ' ',
  diff = '╱',
  eob = ' ',
}
vim.o.dict = '/home/alealfaro/.config/obsidian/Custom Dictionary.txt'
vim.o.gdefault = true -- g is on by default when substituting with s/pattern/replace
vim.o.grepformat = '%f:%l:%c:%m'
vim.o.grepprg = 'rg --vimgrep'
vim.o.inccommand = 'nosplit' -- preview incremental substitute
-- vim.o.jumpoptions = 'view'
vim.o.laststatus = 3 -- global statusline
vim.o.scrolloff = 4 -- Lines of context
vim.o.shiftround = true -- Round indent
vim.o.sidescrolloff = 8 -- Columns of context
vim.o.signcolumn = 'yes' -- Always show the signcolumn, otherwise it would shift the text each time
vim.opt.spelllang = { 'en' }
--[[
-- Fold Options
'foldenable'  'fen':	Open all folds while not set.
'foldexpr'    'fde':	Expression used for "expr" folding.
'foldignore'  'fdi':	Characters used for "indent" folding.
'foldmarker'  'fmr':	Defined markers used for "marker" folding.
'foldmethod'  'fdm':	Name of the current folding method.
'foldminlines' 'fml':	Minimum number of screen lines for a fold to be
			displayed closed.
'foldnestmax' 'fdn':	Maximum nesting for "indent" and "syntax" folding.
'foldopen'    'fdo':	Which kinds of commands open closed folds.
'foldclose'   'fcl':	When the folds not under the cursor are closed.
--]]
--
vim.o.foldminlines = 50
vim.o.foldlevel = 4
vim.o.foldnestmax = 5
vim.o.foldcolumn = 'auto'
vim.o.exrc = true
vim.o.timeoutlen = 300
vim.o.undolevels = 10000
vim.o.updatetime = 200 -- Save swap file and trigger CursorHold
vim.o.wildmode = 'longest:full,full' -- Command-line completion mode
vim.o.winminwidth = 5 -- Minimum window width

-- Diff mode settings.
-- Setting the context to a very large number disables folding.
vim.opt.diffopt:append 'vertical,context:99'

vim.opt.shortmess:append {
  w = true,
  s = true,
}

-- Status line.
vim.o.laststatus = 3
vim.o.cmdheight = 1
local diagnostic_icons = {
  ERROR = '',
  WARN = '',
  HINT = '',
  INFO = '',
}

-- Disable inlay hints initially (and enable if needed with my ToggleInlayHints command).
-- Define the diagnostic signs.
for severity, icon in pairs(diagnostic_icons) do
  local hl = 'DiagnosticSign' .. severity:sub(1, 1) .. severity:sub(2):lower()
  vim.fn.sign_define(hl, { text = icon, texthl = hl })
end
vim.diagnostic.config {
  virtual_text = {
    prefix = '',
    spacing = 2,
    format = function(diagnostic)
      -- Use shorter, nicer names for some sources:
      local special_sources = {
        ['Lua Diagnostics.'] = 'lua',
        ['Lua Syntax Check.'] = 'lua',
      }

      local message = diagnostic_icons[vim.diagnostic.severity[diagnostic.severity]]
      if diagnostic.source then
        message = string.format('%s %s', message, special_sources[diagnostic.source] or diagnostic.source)
      end
      if diagnostic.code then
        message = string.format('%s[%s]', message, diagnostic.code)
      end

      return message .. ' '
    end,
  },
  float = {
    source = true, --'if_many',
    -- Show severity icons as prefixes.
    prefix = function(diag)
      local level = vim.diagnostic.severity[diag.severity]
      local prefix = string.format(' %s ', diagnostic_icons[level])
      return prefix, 'Diagnostic' .. level:gsub('^%l', string.upper)
    end,
  },
  -- Disable signs in the gutter.
  signs = false,
}
