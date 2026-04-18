-- General ====================================================================
vim.g.mapleader = ' ' -- Use `<Space>` as <Leader> key
vim.g.maplocalleader = ','
vim.o.mouse = 'a' -- Enable mouse
vim.o.mousescroll = 'ver:25,hor:6' -- Customize mouse scroll
vim.opt.number = true
vim.o.switchbuf = 'usetab' -- Use already opened buffers when switching
vim.o.undofile = true -- Enable persistent undo

vim.o.shada = "'100,<50,s10,:1000,/100,@100,h" -- Limit ShaDa file (for startup)
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
-- vim.o.complete = '.,w,b,u^5'
vim.o.complete = '.,w,b,kspell' -- Use less sources
vim.o.autocomplete = true
vim.o.autocompletedelay = 100
-- stylua: ignore start
-- stylua: ignore end
--[
-- .	scan the current buffer ('wrapscan' is ignored)
-- w	scan buffers from other windows
-- b	scan other loaded buffers that are in the buffer list
-- u	scan the unloaded buffers that are in the buffer list
-- ^5 limits the number of items to 5
--]--
vim.o.pumblend = 10
vim.o.pumborder = 'rounded'
vim.o.pummaxwidth = 40
vim.o.completeopt = 'menu,menuone,fuzzy,noselect,nosort' -- Use custom behavior
vim.o.completetimeout = 300 -- Limit sources delay

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
vim.o.jumpoptions = 'clean'
vim.o.laststatus = 3 -- global statusline
vim.o.scrolloff = 4 -- Lines of context
vim.o.shiftround = true -- Round indent
vim.o.sidescrolloff = 8 -- Columns of context
vim.o.signcolumn = 'yes' -- Always show the signcolumn, otherwise it would shift the text each time
vim.opt.spelllang = { 'en' }

--- Fold
vim.o.foldmethod = 'expr'
vim.o.foldexpr = 'v:lua.vim.lsp.foldexpr' -- Setting the default to LSP fold expr. Alternative is treesitter
vim.o.foldminlines = 50
vim.o.foldlevel = 4
vim.o.foldnestmax = 5
vim.o.foldcolumn = 'auto'
vim.o.timeoutlen = 300
vim.o.undolevels = 10000
vim.o.updatetime = 200 -- Save swap file and trigger CursorHold
vim.o.wildmode = 'longest:full,full' -- Command-line completion mode
vim.o.wildignorecase = true
vim.o.winminwidth = 5 -- Minimum window width

-- Diff mode settings.
-- Setting the context to a very large number disables folding.
vim.opt.diffopt:append 'vertical,context:99'

vim.opt.shortmess:append {
  w = true,
  s = true,
}

-- Status line.
vim.o.cmdheight = 2
VimRc.now_if_args(function()
  vim.diagnostic.config {
    severity_sort = true,
    float = {
      border = 'rounded',
      source = 'if_many',
      underline = true,
    },
    virtual_text = {
      spacing = 2,
      source = 'if_many',
      prefix = 'o',
    },
    -- Disable signs in the gutter.
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = 'E',
        [vim.diagnostic.severity.WARN] = 'W',
        [vim.diagnostic.severity.INFO] = 'I',
        [vim.diagnostic.severity.HINT] = 'H',
      },
      float = {
        source = true, --'if_many',
      },
      -- Disable signs in the gutter.
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = 'E',
          [vim.diagnostic.severity.WARN] = 'W',
          [vim.diagnostic.severity.INFO] = 'I',
        },
        numhl = {
          [vim.diagnostic.severity.ERROR] = 'ErrorMsg',
          [vim.diagnostic.severity.WARN] = 'WarningMsg',
        },
      },
    },
  }
end)
