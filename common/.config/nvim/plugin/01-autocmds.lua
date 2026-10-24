---@param evt   string | string[]
---@param cb    function
---@param desc  string?
---@param other table?
local autocmd = function(evt, cb, desc, other)
    vim.api.nvim_create_autocmd(evt, vim.tbl_extend('force', { callback = cb, desc = desc }, other or {}))
end
autocmd('TextYankPost', function()
    (vim.hl or vim.highlight).on_yank()
end, 'Highlight on yank'
)
vim.cmd [[
:autocmd! nvim.terminal TermClose
]]
autocmd('BufRead', function(ev)
    vim.g.autoformat = false
end, 'Disable formatting for Claude conversations', { pattern = '/tmp/claude-*/**/*.md' }
)

vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'bigfile' },
    callback = function(args)
        vim.schedule(function()
            vim.bo[args.buf].syntax = vim.filetype.match { buf = args.buf } or ''
        end)
    end,
    desc = 'Disable features in big files',
})
-- ──────────────────────────────────────────────────────────────
--  Spelling for prose filetypes (enable spell + <C-l> quick-fix)
-- ──────────────────────────────────────────────────────────────

vim.api.nvim_create_autocmd('FileType', {
    pattern = {
        'grug-far',
        'oil',
        'git*',
        'diff',
        'man',
        'lspinfo',
        'checkhealth', -- qf handled by ftplugin/qf.lua
        'notify',
        'qf',
        'scratch',
        'minigit',
        'ministarter',
        'Overseer*',
        'help',
    },
    callback = function(args)
        vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = args.buf })
        if not vim.b[args.buf].miniclue_disable then
            local miniclue = MiniClue or require 'mini.clue'
            miniclue.ensure_buf_triggers(args.buf)
        end
    end,
    desc = 'Close with <q>',
})

vim.api.nvim_create_autocmd('BufEnter', {
    callback = function(args)
        if not vim.bo[args.buf].buflisted or vim.bo[args.buf].buftype == 'nofile' then
            vim.keymap.set('n', 'q', '<cmd>quit<cr>', { buffer = args.buf })
        end
    end,
    desc = 'Close with <q> (unlisted buffers)',
})
