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
local q_close_ft = {
  'help',
  'man',
  'lspinfo',
  'checkhealth', -- qf handled by ftplugin/qf.lua
  'notify',
  'git',
  'grug-far',
  'qf',
  'scratch',
  'vimrc',
  'scratch',
  'minigit',
  'git',
  'ministarter',
  'Overseer',
}
local qclose_gr = vim.api.nvim_create_augroup('q_close', { clear = true })
ft_autocmd(q_close_ft, function(ev)
  local bufnr = vim.api.nvim_get_current_buf()
  vim.keymap.set('n', 'q', function()
    MiniBufremove.unshow(bufnr)
    MiniBufremove.delete(bufnr, true)
  end, { buf = ev.buf, silent = true, nowait = true })
  MiniClue.ensure_buf_triggers(bufnr)
end, 'Close with Q', qclose_gr)
vim.cmd [[
:autocmd! nvim.terminal TermClose
]]
-- ──────────────────────────────────────────────────────────────
--  Spelling for prose filetypes (enable spell + <C-l> quick-fix)
-- ──────────────────────────────────────────────────────────────

ft_autocmd({ 'tex', 'markdown', 'norg', 'text', 'gitcommit' }, function(ev)
  vim.opt_local.spell = true
  vim.opt_local.wrap = true
  vim.keymap.set('i', '<c-l>', '<c-g>u<Esc>[s1z=`]a<c-g>u', { buffer = ev.buf, silent = true, desc = 'fix spelling' })
end)
