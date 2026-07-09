---@param evt string|string[]
---@param cb function
---@param desc string?
---@param other table?
local autocmd = function(evt, cb, desc, other)
  vim.api.nvim_create_autocmd(evt, vim.tbl_extend('force', { callback = cb, desc = desc }, other or {}))
end

---@param pattern string[]
---@param cb function
---@param desc string
---@param group_name string
local ft_autocmd = function(pattern, cb, desc, group_name)
  vim.api.nvim_create_autocmd('FileType', { pattern = pattern, callback = cb, desc = desc, group = vim.api.nvim_create_augroup(group_name, { clear = true }) })
end
autocmd('TextYankPost', function()
  (vim.hl or vim.highlight).on_yank()
end, 'Highlight on yank')
vim.cmd [[
:autocmd! nvim.terminal TermClose
]]
autocmd('BufEnter', function(args)
  if not vim.bo[args.buf].buflisted or vim.bo[args.buf].buftype == 'nofile' then
    vim.keymap.set('n', 'q', '<cmd>quit<cr>', { buffer = args.buf })
  end
end, 'Close with <q> (unlisted buffers)')
-- ──────────────────────────────────────────────────────────────
--  Spelling for prose filetypes (enable spell + <C-l> quick-fix)
-- ──────────────────────────────────────────────────────────────

ft_autocmd({ 'qf' }, function(args)
  local map = function(key, mapping)
    vim.api.nvim_buf_set_keymap(args.buf, 'n', key, mapping, { silent = true })
  end
  map('<CR>', '<CR><C-w>p')
  map('o', '<CR><C-w>p')
  map('q', ':cclose<CR>')
  vim.keymap.set('n', 'dd', function()
    local line = vim.fn.line '.'
    local qf_list = vim.fn.getqflist()
    table.remove(qf_list, line)
    vim.fn.setqflist(qf_list, 'r')
    VimRc.info 'Removed qflist entry'
  end, { buf = args.buf, silent = true })
end, 'Keymaps for quickfix', 'vimrc/bigfile')
ft_autocmd({ 'bigfile' }, function(args)
  vim.schedule(function()
    vim.bo[args.buf].syntax = vim.filetype.match { buf = args.buf } or ''
  end)
end, 'Disable features in big files', 'vimrc/bigfile')
ft_autocmd({
  'help',
  'man',
  'lspinfo',
  'checkhealth', -- qf handled by ftplugin/qf.lua
  'notify',
  'git',
  'diff',
  'vimrc',
}, function(args)
  if args.match ~= 'help' or not vim.bo[args.buf].modifiable then
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = args.buf })
  end
end, 'Close with <q>', 'vimrc/close_with_q')
ft_autocmd({
  'grug-far',
  'oil',
  'git',
  'diff',
  'scratch',
  'minigit',
  'ministarter',
  'Overseer*',
}, function(args)
  if not vim.b[args.buf].miniclue_disable then
    local miniclue = MiniClue or require 'mini.clue'
    miniclue.ensure_buf_triggers(args.buf)
  end
end, 'MiniClue Ensure buf triggers ', 'miniclue/ensure_buf_triggers')
ft_autocmd({ 'tex', 'markdown', 'norg', 'text', 'gitcommit' }, function(ev)
  vim.opt_local.spell = true
  vim.opt_local.wrap = false
  vim.keymap.set('i', '<c-l>', '<c-g>u<Esc>[s1z=`]a<c-g>u', { buffer = ev.buf, silent = true, desc = 'Spelling' })
end, 'No Wrap and Spelling', 'nowrap')
