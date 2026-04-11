VimRc.new_autocmd('TextYankPost', function()
  (vim.hl or vim.highlight).on_yank()
end, 'Highlight on yank')

local ft_easy_quit = {
  'git',
  'checkhealth',
  'grug-far',
  'help',
  'lspinfo',
  'man',
  'qf',
  'scratch',
  'notify*',
  'qf',
  'minigit',
  'ministarter',
  'Overseer*',
  'VimRc*',
}

VimRc.new_autocmd('FileType', function(args)
  vim.bo[args.buf].buflisted = false
  vim.api.nvim_buf_set_keymap(args.buf, 'n', 'q', '<Cmd>lua MiniBufremove.delete(0, true)<CR>', { desc = 'Delete!' })
end, ft_easy_quit, 'Close with <q>')

-- Wrap and check for spell in text filetypes
VimRc.new_autocmd('FileType', function()
  vim.opt_local.wrap = true
  vim.opt_local.spell = true
end, { 'text', 'plaintex', 'typst', 'gitcommit' }, 'Wrap and spell check for text filetypes')

-- Auto create dir when saving a file, in case some intermediate directory does not exist

VimRc.new_autocmd('QuitPre', function()
  local all = vim.api.nvim_list_wins()
  local close = {}
  for _, win in ipairs(all) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.bo[buf].filetype
    if vim.list_contains({ 'help', 'qf', 'checkhealth', 'ministarter' }, ft) or not vim.bo[buf].modifiable then
      table.insert(close, win)
    end
  end
  local cur_win = vim.api.nvim_get_current_win()
  if #close ~= 1 or vim.list_contains(close, cur_win) then
    return
  end
  for _, win in ipairs(close) do
    pcall(vim.api.nvim_win_close, win, true)
  end
end, 'Auto-close special windows on quit')
