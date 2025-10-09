local ft_autoclose = {}
local ft_autoclose_ignore = { 'snacks_dashboard' }
-- Disable autoformat for lua files
vim.api.nvim_create_autocmd({ 'FileType' }, {
  pattern = { 'hyprlang' },
  callback = function()
    vim.notify 'Disabling autoformatting'
    vim.b.autoformat = false
  end,
})
local list_wins = function()
  local all, close, rest = vim.api.nvim_list_wins(), {}, {}
  for _, win in ipairs(all) do
    local config = vim.api.nvim_win_get_config(win)
    local buf = vim.api.nvim_win_get_buf(win)
    local wininfo = vim.fn.getwininfo(win)[1]
    local is_ignore = vim.iter(ft_autoclose_ignore):any(function(pat)
      return string.match(vim.bo[buf].ft, pat)
    end)
    local is_ft = vim.iter(ft_autoclose):any(function(pat)
      return string.match(vim.bo[buf].ft, pat)
    end)
    local is_float = config.relative ~= ''
    local is_qf = wininfo.quickfix == 1 or wininfo.loclist == 1
    if not is_ignore and (is_ft or is_float or is_qf) then
      table.insert(close, win)
    else
      table.insert(rest, win)
    end
  end
  return all, rest, close
end

vim.keymap.set('n', '<leader>bD', function()
  local _, wins, close = list_wins()
  local cur_win = vim.api.nvim_get_current_win()
  -- Prevent quit when 'close' window is focused
  if vim.list_contains(close, cur_win) then
    return
  end
  if #wins == 1 then
    pcall(vim.cmd.quitall)
  else
    pcall(vim.cmd.quit)
  end
end, { desc = '[B]uffer and window [D]elete' })
vim.api.nvim_create_autocmd('QuitPre', {
  -- group = augroup("close_with_q"),
  pattern = {
    'PlenaryTestPopup',
    'checkhealth',
    'dbout',
    'gitsigns-blame',
    'grug-far',
    'help',
    'lspinfo',
    'neotest-output',
    'neotest-output-panel',
    'neotest-summary',
    'notify',
    'qf',
    'spectre_panel',
    'startuptime',
    'noice',
    'dapui',
    'trouble',
    'dap-repl',
    'codecompanion',
  },

  callback = function()
    local _, wins, close = list_wins()
    local cur_win = vim.api.nvim_get_current_win()
    if #wins ~= 1 then
      return
    end
    -- Prevent quit when 'close' window is focused
    if vim.list_contains(close, cur_win) then
      return
    end
    if vim.list_contains(close, cur_win) then
      -- stylua: ignore
      vim.defer_fn(function() pcall(vim.cmd.quit) end, 100)
    end
    for _, win in ipairs(close) do
      pcall(vim.api.nvim_win_close, win, true)
    end
  end,
  -- callback = function(event)
  --   vim.bo[event.buf].buflisted = false
  --   vim.schedule(function()
  --     vim.keymap.set("n", "q", function()
  --       vim.cmd("close")
  --       pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
  --     end, {
  --       buffer = event.buf,
  --       silent = true,
  --       desc = "Quit buffer",
  --     })
  --   end)
  -- end,
})
-- vim.api.nvim_create_autocmd('QuitPre', {
--   callback = function()
--     local _, wins, close = list_wins()
--     local cur_win = vim.api.nvim_get_current_win()
--     if #wins ~= 1 then
--       return
--     end
--     -- Prevent quit when 'close' window is focused
--     if vim.list_contains(close, cur_win) then
--       return
--     end
--     if vim.list_contains(close, cur_win) then
--       -- stylua: ignore
--       vim.defer_fn(function() pcall(vim.cmd.quit) end, 100)
--     end
--     for _, win in ipairs(close) do
--       pcall(vim.api.nvim_win_close, win, true)
--     end
--   end,
-- })

vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  callback = function()
    vim.cmd [[Trouble qflist open]]
  end,
})

-- vim.api.nvim_create_autocmd('BufRead', {
--   callback = function(ev)
--     if vim.bo[ev.buf].buftype == 'quickfix' then
--       vim.schedule(function()
--         vim.cmd [[cclose]]
--         vim.cmd [[Trouble qflist open]]
--       end)
--     end
--   end,
-- })
