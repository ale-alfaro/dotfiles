---@class vimrc.KeyMapping
---@field mode (string | string[])?
---@field lhs  string
---@field rhs  string | function
---

vim.o.exrc = true
vim.g.loaded_python3_provider = 0
vim.g.loaded_gtags_cscope = 1
vim.env.PATH = vim.env.HOME .. '/.local/share/mise/shims:' .. vim.env.PATH

-- General ====================================================================
vim.g.mapleader = ' ' -- Use `<Space>` as <Leader> key
vim.g.maplocalleader = '`'
vim.o.mouse = 'a' -- Enable mouse
vim.o.mousescroll = 'ver:25,hor:6' -- Customize mouse scroll
vim.opt.number = true
vim.o.switchbuf = 'usetab' -- Use already opened buffers when switching
vim.o.undofile = true -- Enable persistent undo

-- wl-copy only works with a reachable Wayland socket. Over SSH, or in a tmux
-- pane started without one, use OSC 52 so the terminal owns the clipboard.
if not (vim.env.WAYLAND_DISPLAY and vim.env.XDG_RUNTIME_DIR) then
    local osc52 = require 'vim.ui.clipboard.osc52'
    vim.g.clipboard = {
        name = 'OSC 52',
        copy = { ['+'] = osc52.copy '+', ['*'] = osc52.copy '*' },
        paste = { ['+'] = osc52.paste '+', ['*'] = osc52.paste '*' },
    }
end
--- Shortmess controls the message display
vim.o.shortmess = 'atI' -- default is 'ltToOCF'
vim.opt.clipboard = 'unnamedplus' -- Sync with system clipboard
-- Search and replace (substitute) opts on default
vim.o.gdefault = true -- g is on
vim.o.ignorecase = true -- c (case-INsensitive) on
vim.o.grepformat = '%f:%l:%c:%m'
vim.o.grepprg = 'rg --vimgrep'
vim.o.inccommand = 'nosplit' -- preview incremental substitute
vim.o.jumpoptions = 'clean'
vim.o.incsearch = true -- Show search matches while typing
vim.o.smartcase = true -- Respect case if search pattern has upper case
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
vim.o.shiftwidth = 8 -- Use this number of spaces for indentation
vim.o.tabstop = 8 -- Show tab as this number of spacesA
vim.o.softtabstop = 8 -- Show tab as this number of spacesA
-- vim.o.winblend = 30

vim.o.cmdheight = 2
--- Completion menu
-- vim.o.pumheight = 10 -- Make popup menu smaller
-- vim.o.pummaxwidth = 100 -- Make popup menu not too wide
-- vim.o.pumblend = 10
-- vim.o.pumborder = 'rounded' -- 'rounded'|'single'

vim.o.ruler = false -- Don't show cursor coordinates
vim.o.formatoptions = 'croq'
-- Pattern for a start of numbered list (used in `gw`). This reads as
-- "Start of list item is: at least one special character (digit, -, +, *)
-- possibly followed by punctuation (. or `)`) followed by at least one space".
vim.o.formatlistpat = [[^\s*[0-9\-\+\*]\+\([\.\)]\)*\s\+]]

vim.o.comments = [[sr:/***,m:**,ex:*/]]

vim.o.showmode = false -- Don't show mode in command line
vim.o.signcolumn = 'yes' -- Always show signcolumn (less flicker)
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
vim.o.foldlevel = 5 -- Fold nothing by default; set to 0 or 1 to fold
-- vim.o.foldmethod = 'indent' -- Fold based on indent level
vim.o.foldmethod = 'expr' --- 'indent'| 'expr'
vim.o.foldexpr = 'v:lua.vim.lsp.foldexpr' -- Setting the default to LSP fold expr. Alternative is treesitter

vim.o.foldnestmax = 10 -- Limit number of fold levels
-- vim.o.foldtext = '' -- Show text under fold with its highlighting

-- vim.o.foldminlines = 50
-- vim.o.foldcolumn = 'auto'
-- vim.opt.fillchars = {
--   foldopen = '',
--   foldc
--   fold = ' ',
--   foldsep = ' ',
--   diff = '╱',
--   eob = ' ',
-- }
--
--
--
-- -- Editing ====================================================================
vim.o.autoindent = true -- Use auto indent
vim.o.expandtab = true -- Convert tabs to spaces
vim.o.smartindent = true -- Make indenting smart
vim.o.iskeyword = '@,48-57,_,192-255,-' -- Treat dash as `word` textobject part
vim.o.virtualedit = 'block' -- Allow going past end of line in blockwise mode
--
--
-- -- Built-in completion
-- Built-in completion
-- vim.o.complete = '.,w,b,kspell' -- Use less sources
-- vim.o.completeopt = 'menuone,noselect,fuzzy,nosort' -- Use custom behavior
-- vim.o.completetimeout = 100 -- Limit sources delay

-- vim.o.autocomplete = true
-- vim.o.autocompletedelay = 100
--- Command Line completion
-- vim.o.wildmode = 'longest:full,full' -- Command-line completion mode
-- vim.o.wildignorecase = true
--- Misc

vim.o.undolevels = 10000
vim.o.timeoutlen = 300 --- Do not fuck with this option. You will feel it
vim.o.updatetime = 300

vim.o.termguicolors = false
local gh = function(repo)
    return 'https://github.com/' .. repo
end
local gh_rev = function(repo, rev)
    return { src = 'https://github.com/' .. repo, version = rev }
end

vim.pack.add {
    gh 'nvim-mini/mini.nvim', gh 'folke/snacks.nvim', gh 'stevearc/oil.nvim', gh 'stevearc/quicker.nvim',
    gh 'stevearc/overseer.nvim', gh 'folke/trouble.nvim', gh 'ibhagwan/fzf-lua', gh 'nvim-treesitter/nvim-treesitter',
    gh 'nvim-treesitter/nvim-treesitter-textobjects', gh 'neovim/nvim-lspconfig', gh 'b0o/schemastore.nvim',
    gh 'rachartier/tiny-code-action.nvim', gh 'MeanderingProgrammer/render-markdown.nvim', gh 'MagicDuck/grug-far.nvim',
    gh 'nvim-lua/plenary.nvim', gh 'saghen/blink.lib', gh_rev('saghen/blink.cmp', 'main'), gh 'rebelot/kanagawa.nvim',
}
vim.cmd [[
  packadd nvim.undotree
  packadd nvim.difftool
]]
local misc = require 'mini.misc'

misc.setup()
misc.setup_auto_root()
misc.setup_termbg_sync()
misc.setup_restore_cursor()

---@class VimRc: vimrc.Utils
---@field now            fun(func: function)
---@field later          fun(func: function)
---@field now_if_args    fun(func: function)
---@field on_filetype    fun(ft: string | string[], func: function)
---@field on_event       fun(evt: string, func: function)
---@field on_packchanged fun(plugin_name: string, callback: fun())
---@field notify?        fun(msg: string, lvl: string)
---@field getenv         fun(name: string, fallback?: string): string?
_G.VimRc = _G.VimRc or require 'custom.utils' ---@type VimRc
---
---
VimRc.never = function(_f)
end

VimRc.now = function(f)
    misc.safely('now', f)
end
VimRc.later = function(f)
    misc.safely('later', f)
end
VimRc.now_if_args = vim.fn.argc(-1) > 0 and VimRc.now or VimRc.later
VimRc.never_if_args = vim.fn.argc(-1) > 0 and VimRc.never or VimRc.later

VimRc.on_event = function(ev, f)
    misc.safely('event:' .. ev, f)
end
VimRc.on_filetype = function(ft, f)
    if type(ft) == 'table' and vim.islist(ft) then
        local pat = table.concat(ft, ",")
        misc.safely('filetype:' .. pat, f)
    elseif type(ft) == 'string' then
        misc.safely('filetype:' .. ft, f)
    else
        vim.notify("Bad pattern", vim.log.levels.ERROR)
    end
end

vim.api.nvim_create_autocmd('PackChanged' ,{
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if not vim.tbl_contains({ 'update' }, kind) then
        return
    end
    if not ev.data.active then
        vim.cmd.packadd(name)
    end
end,  desc = "Pack changed"})

VimRc.now(function()
    require('vim._core.ui2').enable {
        enable = true,
        msg = { -- Options related to the message module.
            targets = 'msg', ---@type 'cmd' | 'msg' Default message target if not present in targets.
            cmd = { -- Options related to messages in the cmdline window.
                height = 0.5, -- Maximum height while expanded for messages beyond 'cmdheight'.
            },
            dialog = { -- Options related to dialog window.
                height = 0.5, -- Maximum height.
            },
            msg = { -- Options related to msg window.
                height = 0.5,   -- Maximum height.
                timeout = 4000, -- Time a message is visible in the message window.
            },
            pager = { -- Options related to message window.
                height = 1, -- Maximum height.
            },
        },
    }

    VimRc.icons = require 'custom.icons'
    local ext3_blocklist = { scm = true, txt = true, yml = true }
    local ext4_blocklist = { json = true, yaml = true }
    local mini_icons = require 'mini.icons'
    mini_icons.setup {
        use_file_extension = function(ext, _)
            return not (ext3_blocklist[ext:sub(-3)] or ext4_blocklist[ext:sub(-4)])
        end,
    }
    mini_icons.mock_nvim_web_devicons()
    vim.cmd 'colorscheme kanagawa'
    -- vim.cmd 'colorscheme gruvbox'
    -- vim.cmd 'colorscheme catppuccin'
    -- Set up to not prefer extension-based icon for some extensions

    -- require('extras.image').setup_image_snacks()
    require('mini.statusline').setup()
end)

VimRc.now(function()
    -- No-prefix
    vim.keymap.set('n', 'q', '<nop>', { noremap = true })
    vim.keymap.set('v', '<', '<gv', { noremap = true })
    vim.keymap.set('v', '>', '>gv', { noremap = true })
    vim.keymap.set({ 'n', 'x' }, '<Down>', 'gj', { desc = 'Navigate down (visual line)' })
    vim.keymap.set({ 'n', 'x' }, '<Up>', 'gk', { desc = 'Navigate down (visual line)' })
    vim.keymap.set({ 'n', 'x' }, '<Down>', [[v:count == 0 ? 'gj' : 'j']], { expr = true })
    vim.keymap.set({ 'n', 'x' }, '<Up>', [[v:count == 0 ? 'gk' : 'k']], { expr = true })

    -- Reselect latest changed, put, or yanked text
    vim.keymap.set(
        'n', 'gV', '"g`[" . strpart(getregtype(), 0, 1) . "g`]"',
        {
            expr = true,
            replace_keycodes = false,
            desc = 'Visually select changed text',
        }
    )
    -- Search inside visually highlighted text. Use `silent = false` for it to
    -- make effect immediately.
    vim.keymap.set({ 'n', 'i', 'v', 's' }, '<C-s>', '<esc>:update | redraw<CR>', { desc = 'Save', noremap = true })

    vim.keymap.set({ 'i', 'n', 'v' }, '<C-S>s', function()
        vim.g.skip_formatting = true
        return '<esc>:update | redraw<CR>'
    end, { desc = 'Save (without formatting)', expr = true }
    )

    -- Quickly go to the end of the line while in insert mode.
    local map = function(key, keycmd, desc)
        vim.keymap.set('n', key, keycmd, { desc = desc, noremap = true })
    end
    vim.keymap.set({ 'i', 'c' }, '<C-e>', '<C-o>A', { desc = 'Go to the end of the line' })
    vim.keymap.set({ 'i', 'c' }, '<C-a>', '<C-o>I', { desc = 'Go to the start of the line' })
    map('<C-q>', '<Cmd>qall<CR>', 'Quit All')

    local nmap_leader = function(key, keycmd, desc)
        vim.keymap.set('n', '<leader>' .. key, keycmd, { desc = desc })
    end
    nmap_leader('ba', '<Cmd>b#<CR>', 'Alternate')
    nmap_leader('bd', '<Cmd>lua MiniBufremove.delete()<CR>', 'Delete')
    nmap_leader('bs', '<Cmd>lua VimRc.new_scratch_buffer()<Cr>', 'Scratch')
    nmap_leader('bw', '<Cmd>lua MiniBufremove.delete(0, true)<CR>', 'Delete!')

    local nonprefix_keys = {
        { '<Space><Space>', '<cmd>FzfLua builtin<cr>', 'Find Fzf pickers' },
        { '<C-b>', '<cmd>FzfLua buffers<cr>', 'Buffers' }, { '<C-f>', '<cmd>FzfLua files<cr>', 'Files' },
        { '<C-g>', '<cmd>FzfLua live_grep<cr>', 'Grep (cwd)' }, { '<C-e>', '<cmd>FzfLua grep_cword<cr>', 'Grep CWord' },
        { '<C-c>', '<cmd>FzfLua resume<cr>', 'Continue' },
    }
    for _, k in ipairs(nonprefix_keys) do
        vim.keymap.set('n', k[1], k[2], { desc = k[3], noremap = true })
    end
    -- +Find
    local prefix_keys = {
        { 'o', '<cmd>FzfLua combine pickers=oldfiles;zoxide;visits<cr>', 'Old Files' },
        { 'm', '<cmd>FzfLua manpages<cr>', 'Find Man' },
        { 'h', '<cmd>FzfLua help_tags<cr>', 'Help' },
        { 'k', '<Cmd>FzfLua keymaps<CR>', 'Keymaps' },
        { 'z', '<cmd>FzfLua zoxide<cr>', 'Zoxide' },
        { 'w', '<cmd>Wf<cr>', 'Search West Workspace (Files)' },
        { 'g', '<cmd>Wg<cr>', 'Search West Workspace (Live Grep)' },
        {
            's',
            '<cmd>FzfLua lsp_document_symbols<cr>',
            'Live Document Symbols',
        },
        { 'd', '<cmd>FzfLua lsp_document_diagnostics<cr>', 'Document diagnostics' },
        { 'v', "<cmd>FzfLua visits sort_by='frequency'<cr>", 'Search Frequent Visits' },
        { 'r', '<cmd>FzfLua visits<cr>', 'Search Recent Visits' },
    }

    for _, k in ipairs(prefix_keys) do
        vim.keymap.set('n', '<leader>f' .. k[1], k[2], { desc = k[3] })
    end
    -- +Explore
    local search_keys = {
        { 'v', '<cmd>Oil ' .. vim.fs.dirname(vim.fn.expand '$MYVIMRC') .. '<cr>', 'VimRc' },
        { 'l', '<Cmd>lua MiniFiles.open(MiniFiles.get_latest_path())<cr>', 'Open Explorer (Last Path)' },
    }
    for _, k in ipairs(search_keys) do
        vim.keymap.set('n', '<leader>e' .. k[1], k[2], { desc = k[3] })
    end
    --- +Git
    local git_keys = {
        { 'a', '<cmd>FzfLua git_status<cr>', 'Add/Status' },
        { 'd', '<cmd>lua MiniDiff.toggle_overlay()<cr>', 'Diff Toggle overlay' },
        { 'D', '<cmd>FzfLua git_diff<cr>', 'Diff Hunks' }, { 'h', '<Cmd>FzfLua git_hunks<CR>', 'Hunks' },
        { 'b', '<cmd>FzfLua git_blame<cr>', 'Blame' }, { 'B', '<cmd>Git blame --porcelain -- %<cr>', 'Blame (MiniGit)' },
        { 'l', '<cmd>Git log --oneline<cr>', 'Log (MiniGit)' }, { 's', '<cmd>Git status<cr>', 'Status (MiniGit)' },
        { 'c', '<cmd>Git commit<cr>', 'Commit (MiniGit)' }, { 'b', '<cmd>FzfLua git_bcommits<cr>', 'Buf Commits' },
        { 'C', '<cmd>FzfLua git_commits<cr>', 'Commits' },
    }

    for _, k in ipairs(git_keys) do
        vim.keymap.set('n', '<leader>v' .. k[1], k[2], { desc = k[3] })
    end

    --- +Qf
    local qf_keys = {
        { 'o', '<Cmd>copen<CR>', 'Open' }, { 'c', '<Cmd>cclose<CR>', 'Close' }, { 'h', '<Cmd>chistory<CR>', 'History' },
        { 'n', '<Cmd>cnewer<CR>', 'Newer List' }, { 'p', '<Cmd>colder<CR>', 'Older List' },
        { 'd', '<cmd>Trouble diagnostics filter = { severity=vim.diagnostic.severity.ERROR }<cr>',
            'Diagnostics (Error-only)' }, { 'D', '<cmd>Trouble diagnostics <cr>', 'Diagnostics (Everything)' },
    }

    for _, k in ipairs(qf_keys) do
        vim.keymap.set('n', '<leader>q' .. k[1], k[2], { desc = k[3] })
    end

    --- +Term
    nmap_leader('tt', '<Cmd>vertical term<CR>', 'vertical')
    vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')
    -- Map <A-j>, <A-k>, <A-h>, <A-l> to navigate between windows in any modes
    vim.keymap.set({ 't', 'i' }, '<A-h>', '<C-\\><C-n><C-w>h')
    vim.keymap.set({ 't', 'i' }, '<A-j>', '<C-\\><C-n><C-w>j')
    vim.keymap.set({ 't', 'i' }, '<A-k>', '<C-\\><C-n><C-w>k')
    vim.keymap.set({ 't', 'i' }, '<A-l>', '<C-\\><C-n><C-w>l')
    vim.keymap.set({ 'n' }, '<A-h>', '<C-w>h')
    vim.keymap.set({ 'n' }, '<A-j>', '<C-w>j')
    vim.keymap.set({ 'n' }, '<A-k>', '<C-w>k')
    vim.keymap.set({ 'n' }, '<A-l>', '<C-w>l')
    vim.cmd [[
      :tnoremap <F2> <C-\><C-N><C-\><C-N> 
      :tnoremap <C-d> <C-\><C-N><C-\><C-N> 
      :tnoremap <C-Left>  <C-\><C-N><C-w>h
      :tnoremap <C-Down>  <C-\><C-N><C-w>j
      :tnoremap <C-Up>    <C-\><C-N><C-w>k
      :tnoremap <C-Right> <C-\><C-N><C-w>l
      :inoremap <C-Left>  <C-\><C-N><C-w>h
      :inoremap <C-Down>  <C-\><C-N><C-w>j
      :inoremap <C-Up>    <C-\><C-N><C-w>k
      :inoremap <C-Right> <C-\><C-N><C-w>l
      :nnoremap <C-Left>  <C-w>h
      :nnoremap <C-Down>  <C-w>j
      :nnoremap <C-Up>    <C-w>k
      :nnoremap <C-Right> <C-w>l

  ]]
    --- +Exec
    vim.keymap.set('n', '<leader>xt', '<cmd>OverseerToggle<cr>', { desc = 'OverseerToggle' })
    local miniclue = require 'mini.clue'
    -- stylua: ignore
    miniclue.setup({
        -- Define which clues to show. By default shows only clues for custom mappings
    -- (uses `desc` field from the mapping; takes precedence over custom clue).
        clues = {
            -- This is defined in 'plugin/20_keymaps.lua' with Leader group descriptions
            {
                { mode = 'n', keys = '<Leader>b', desc = '+Buffer' },
                { mode = 'n', keys = '<Leader>e', desc = '+Explore' },
                { mode = 'n', keys = '<Leader>f', desc = '+Find ' },
                { mode = 'n', keys = '<Leader>n', desc = '+Notifications' },
                { mode = 'n', keys = '<Leader>q', desc = '+Qf' },
                { mode = 'x', keys = '<Leader>q', desc = '+Qf' },
                { mode = 'n', keys = '<Leader>t', desc = '+Terminal' },
                { mode = 'n', keys = '<Leader>v', desc = '+VCS' },
                { mode = 'x', keys = '<Leader>v', desc = '+VCS' },
                { mode = 'n', keys = '<Leader>x', desc = '+Exec' },
            },
            miniclue.gen_clues.builtin_completion(),
            miniclue.gen_clues.g(),
            miniclue.gen_clues.marks(),
            miniclue.gen_clues.registers(),
            miniclue.gen_clues.square_brackets(),
            -- This creates a submode for window resize mappings. Try the following:
      -- - Press `<C-w>s` to make a window split.
      -- - Press `<C-w>+` to increase height. Clue window still shows clues as if
      --   `<C-w>` is pressed again. Keep pressing just `+` to increase height.
      --   Try pressing `-` to decrease height.
      -- - Stop submode either by `<Esc>` or by any key that is not in submode.
            miniclue.gen_clues.windows({ submode_resize = true }),
            miniclue.gen_clues.z(),
        },
        -- Explicitly opt-in for set of common keys to trigger clue window
        triggers = {
            { mode = { 'n', 'x' }, keys = '<Leader>' }, -- Leader triggers
            { mode = 'n', keys = '\\' },                -- mini.basics
            { mode = { 'n', 'x' }, keys = '[' },        -- mini.bracketed
            { mode = { 'n', 'x' }, keys = ']' },
            { mode = 'i', keys = '<C-x>' },             -- Built-in completion
            { mode = { 'n', 'x' }, keys = 'g' },        -- `g` key
            { mode = { 'n', 'x' }, keys = 'q' },        -- `g` key
            { mode = { 'n', 'x' }, keys = "'" },        -- Marks
            { mode = { 'n', 'x' }, keys = '`' },
            { mode = { 'n', 'x' }, keys = '"' },        -- Registers
            { mode = { 'i', 'c' }, keys = '<C-r>' },
            { mode = 'n', keys = '<C-w>' },             -- Window commands
            { mode = { 'n', 'x' }, keys = 's' },        -- `s` key (mini.surround, etc.)
            { mode = { 'n', 'x' }, keys = 'z' },        -- `z` key
        },

        window = {
            -- Show window immediately
            delay = 0,

            config = {
                -- Compute window width automatically
                width = 'auto',

                -- Use double-line border
                border = 'double',
            },
        },
    })
end)
