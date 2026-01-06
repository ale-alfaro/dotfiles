-------------------------------------------------------------------------------
-- autocmds
--------------------------------------------------------------------------------
---Helper to create augroups
---@param name string
function _G.augroup(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end

local gr = augroup 'custom-config'

---@alias autocmd_cb string|fun(args: vim.api.keyset.create_autocmd.callback_args): boolean?
---@param event  string
---@param callback autocmd_cb
---@param pattern? string|string[]
---@param desc? string|string[]
---
---@overload fun(event: string, callback: autocmd_cb , desc: string)
function _G.new_autocmd(event, callback, pattern, desc)
  if pattern ~= nil and desc == nil then
    -- Overload without pattern
    desc = pattern
  end
  local opts = {
    group = gr,
    pattern = pattern,
    callback = callback,
    desc = desc,
  }
  ok, _ = pcall(vim.api.nvim_create_autocmd, event, opts)
  if not ok then
    _G.error('Failed to create autocmd ' .. vim.print(pattern) .. ' ' .. vim.print(desc))
  end
end

---@param callback autocmd_cb
---@param pattern? string|string[]
---@param desc? string|string[]
function _G.new_user_autocmd(callback, pattern, desc)
  pattern = pattern or '*'
  _G.new_autocmd('User', callback, pattern, desc)
end
-- Format Options
-- new_autocmd('FileType', function()
--   vim.cmd 'setlocal formatoptions-=c formatoptions-=o'
-- end, "Proper 'formatoptions'")

-- CodeCompanion

new_autocmd('TextYankPost', function()
  (vim.hl or vim.highlight).on_yank()
end, 'Highlight on yank')

-- Resize splits if window got resized
new_autocmd('VimResized', function()
  local current_tab = vim.fn.tabpagenr()
  vim.cmd 'tabdo wincmd ='
  vim.cmd('tabnext ' .. current_tab)
end, 'Resize splits on window resize')

-- Go to last loc when opening a buffer
new_autocmd('BufReadPost', function(event)
  local exclude = { 'gitcommit' }
  local buf = event.buf
  if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].custom_last_loc then
    return
  end
  vim.b[buf].custom_last_loc = true
  local mark = vim.api.nvim_buf_get_mark(buf, '"')
  local lcount = vim.api.nvim_buf_line_count(buf)
  if mark[1] > 0 and mark[1] <= lcount then
    pcall(vim.api.nvim_win_set_cursor, 0, mark)
  end
end, 'Go to last location on buffer open')

-- Close some filetypes with <q>
new_autocmd('FileType', function(event)
  vim.bo[event.buf].buflisted = false
  vim.schedule(function()
    vim.keymap.set('n', 'q', function()
      vim.cmd 'close'
      pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
    end, {
      buffer = event.buf,
      silent = true,
      desc = 'Quit buffer',
    })
  end)
end, {
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
  'tsplayground',
}, 'Close special filetypes with <q>')

-- Wrap and check for spell in text filetypes
new_autocmd('FileType', function()
  vim.opt_local.wrap = true
  vim.opt_local.spell = true
end, { 'text', 'plaintex', 'typst', 'gitcommit', 'markdown' }, 'Wrap and spell check for text filetypes')

-- Fix conceallevel for json files
-- new_autocmd('FileType', { 'json', 'jsonc', 'json5' }, function()
--   vim.opt_local.conceallevel = 0
-- end, 'Fix conceallevel for json files')

-- Auto create dir when saving a file, in case some intermediate directory does not exist
new_autocmd('BufWritePre', function(event)
  if event.match:match '^%w%w+://' then
    return
  end
  local file = vim.fs.abspath(event.match) or event.match
  vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
end, 'Auto create directory on save')

-- Disable autoformat for hyprlang files
new_autocmd('FileType', function()
  vim.notify 'Disabling autoformatting'
  vim.b.autoformat = false
end, { 'hyprlang', 'devicetree' }, 'Disable autoformat for hyprlang')

-- Auto-close floating/special windows on QuitPre
local ft_autoclose = {
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
  'mini*',
}
local ft_autoclose_ignore = { 'snacks_dashboard' }

local function list_wins_for_autoclose()
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

new_autocmd('QuitPre', function()
  local _, wins, close = list_wins_for_autoclose()
  local cur_win = vim.api.nvim_get_current_win()
  if #wins ~= 1 or vim.list_contains(close, cur_win) then
    return
  end
  vim.defer_fn(function()
    pcall(vim.cmd.quit)
  end, 100)
  for _, win in ipairs(close) do
    pcall(vim.api.nvim_win_close, win, true)
  end
end, ft_autoclose, 'Auto-close special windows on quit')
--
-- -- Open Trouble for qflist
new_autocmd('QuickFixCmdPost', function()
  vim.cmd [[Trouble qflist open]]
end, 'Open Trouble for qflist')
