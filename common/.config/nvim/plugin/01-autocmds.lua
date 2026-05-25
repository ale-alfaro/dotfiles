---@param evt string|string[]
---@param cb function
---@param desc string?
---@param other table?
local autocmd = function(evt, cb, desc, other)
  vim.api.nvim_create_autocmd(evt, vim.tbl_extend('force', { callback = cb, desc = desc }, other or {}))
end

local ft_autocmd = function(pattern, cb, desc, group)
  vim.api.nvim_create_autocmd('FileType', { pattern = pattern, callback = cb, desc = desc, group = group })
end
autocmd('TextYankPost', function()
  (vim.hl or vim.highlight).on_yank()
end, 'Highlight on yank')
vim.cmd [[
:autocmd! nvim.terminal TermClose
]]
-- ──────────────────────────────────────────────────────────────
--  Spelling for prose filetypes (enable spell + <C-l> quick-fix)
-- ──────────────────────────────────────────────────────────────

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('mariasolos/big_file', { clear = true }),
  desc = 'Disable features in big files',
  pattern = 'bigfile',
  callback = function(args)
    vim.schedule(function()
      vim.bo[args.buf].syntax = vim.filetype.match { buf = args.buf } or ''
    end)
  end,
})
close_with_q = vim.api.nvim_create_augroup('mariasolos/close_with_q', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  group = close_with_q,
  desc = 'Close with <q>',
  pattern = {
    'help',
    'man',
    'lspinfo',
    'checkhealth', -- qf handled by ftplugin/qf.lua
    'notify',
    'git',
    'diff',
    'grug-far',
    'qf',
    'oil',
    'scratch',
    'vimrc',
    'scratch',
    'minigit',
    'ministarter',
    'Overseer',
  },
  callback = function(args)
    if args.match ~= 'help' or not vim.bo[args.buf].modifiable then
      vim.b[args.buf].miniclue_disable = true
      vim.keymap.set('n', 'q', '<cmd>quit<cr>', { buffer = args.buf })
    end
  end,
})
vim.api.nvim_create_autocmd('BufEnter', {
  group = close_with_q,
  desc = 'Close with <q> (unlisted buffers)',
  callback = function(args)
    if not vim.bo[args.buf].buflisted or vim.bo[args.buf].buftype == 'nofile' then
      vim.keymap.set('n', 'q', '<cmd>quit<cr>', { buffer = args.buf })
    end
  end,
})
ft_autocmd({ 'tex', 'markdown', 'norg', 'text', 'gitcommit' }, function(ev)
  vim.opt_local.spell = true
  vim.opt_local.wrap = true
  vim.keymap.set('i', '<c-l>', '<c-g>u<Esc>[s1z=`]a<c-g>u', { buffer = ev.buf, silent = true, desc = 'fix spelling' })
end)
