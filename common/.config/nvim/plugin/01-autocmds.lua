---@param evt string|string[]
---@param cb function
---@param desc string?
---@param other table?
local autocmd = function(evt, cb, desc, other)
  vim.api.nvim_create_autocmd(evt, vim.tbl_extend('force', { callback = cb, desc = desc }, other or {}))
end
autocmd('TextYankPost', function()
  (vim.hl or vim.highlight).on_yank()
end, 'Highlight on yank')
vim.cmd [[
:autocmd! nvim.terminal TermClose
]]
autocmd('BufRead', function(args)
  vim.b.autoformat = false
end, 'Disable formatting for Claude conversations', { pattern = '/tmp/claude-*/**/*.md' })

local aug_with_q = vim.api.nvim_create_augroup('vimrc/close_with_q', {clear = true})


vim.api.nvim_create_autocmd('BufEnter', {
  callback = function(args)
    if not vim.bo[args.buf].buflisted or vim.bo[args.buf].buftype == 'nofile' then
      vim.keymap.set('n', 'q', '<cmd>quit<cr>', { buffer = args.buf })
    end
  end, desc = 'Close with <q> (unlisted buffers)'})
  vim.api.nvim_create_autocmd('FileType', { pattern ={ 'bigfile' }, callback =function(args)
    vim.schedule(function()
      vim.bo[args.buf].syntax = vim.filetype.match { buf = args.buf } or ''
    end)
  end,
  desc = 'Disable features in big files',
  group = aug_with_q,
})
-- ──────────────────────────────────────────────────────────────
--  Zephyr/west workspaces: `:compiler west` for any buffer under the
--  nearest ancestor directory containing `.west/` (fires after
--  after/ftplugin/*.lua, so it wins over e.g. c.lua's `:compiler gcc`)
-- ──────────────────────────────────────────────────────────────
autocmd({ 'BufReadPost', 'BufNewFile' }, function(args)
  if vim.bo[args.buf].buftype ~= '' then
    return
  end
  if vim.fs.root(args.buf, { '.west' }) then
    vim.api.nvim_buf_call(args.buf, function()
      vim.cmd.compiler 'west'
    end)
  end
end, 'Set compiler=west inside west workspaces', { group = vim.api.nvim_create_augroup('vimrc/west_compiler', { clear = true }) })
-- ──────────────────────────────────────────────────────────────
--  Spelling for prose filetypes (enable spell + <C-l> quick-fix)
-- ──────────────────────────────────────────────────────────────

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'qf',
  callback = function(args) local map = function(key, mapping)
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
  end, 
  desc = 'Keymaps for quickfix'
})

vim.api.nvim_create_autocmd('FileType', {pattern ={
  'help',
  'man',
  'lspinfo',
  'checkhealth', -- qf handled by ftplugin/qf.lua
  'notify',
  'git',
  'diff',
  'vimrc',
}, callback = function(args)
  if args.match ~= 'help' or not vim.bo[args.buf].modifiable then
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = args.buf })
  end
end, desc = 'Close with <q>', group = aug_with_q })



local aug_miniclue = vim.api.nvim_create_augroup('miniclue/ensure_buf_triggers', {clear = true})

vim.api.nvim_create_autocmd('FileType', { 
  pattern = {
    'grug-far',
    'oil',
    'git',
    'diff',
    'scratch',
    'minigit',
    'ministarter',
    'Overseer*',
  }, 
  callback = function(args)
    if not vim.b[args.buf].miniclue_disable then
      local miniclue = MiniClue or require 'mini.clue'
      miniclue.ensure_buf_triggers(args.buf)
    end
  end, 
  desc = 'MiniClue Ensure buf triggers ', 
  group = aug_miniclue,
})

