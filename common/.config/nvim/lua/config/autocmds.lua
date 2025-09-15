local ft_autoclose = { 'snacks_', 'dapui_', 'dap-repl', 'qf' }
local ft_autoclose_ignore = { 'snacks_dashboard' }

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
})

-- vim.api.nvim_create_autocmd('QuitPre', {
--   callback = function()
--     local snacks_windows = {}
--     local floating_windows = {}
--     local windows = vim.api.nvim_list_wins()
--     for _, w in ipairs(windows) do
--       local filetype = vim.api.nvim_get_option_value('filetype', { buf = vim.api.nvim_win_get_buf(w) })
--       if filetype:match 'snacks_' ~= nil then
--         table.insert(snacks_windows, w)
--       elseif vim.api.nvim_win_get_config(w).relative ~= '' then
--         table.insert(floating_windows, w)
--       end
--     end
--     if 1 == #windows - #floating_windows - #snacks_windows then
--       -- Should quit, so we close all Snacks windows.
--       for _, w in ipairs(snacks_windows) do
--         vim.api.nvim_win_close(w, true)
--       end
--     end
--   end,
-- })
