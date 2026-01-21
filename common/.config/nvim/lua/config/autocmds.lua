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
  local ok, _ = pcall(vim.api.nvim_create_autocmd, event, opts)
  if not ok then
    VimRc.error('Failed to create autocmd ' .. vim.print(pattern) .. ' ' .. vim.print(desc))
  end
end

---@param callback autocmd_cb
---@param pattern? string|string[]
---@param desc? string|string[]
function _G.new_user_autocmd(callback, pattern, desc)
  pattern = pattern or '*'
  _G.new_autocmd('User', callback, pattern, desc)
end

new_autocmd('TextYankPost', function()
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
  'notify',
  'qf',
  'dapui',
  'trouble',
  'dap-repl',
  'codecompanion',
  'mini-files',
}

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('easy_quit', { clear = true }),
  desc = 'Close with <q>',
  pattern = ft_easy_quit,
  callback = function(args)
    if args.match ~= 'help' or not vim.bo[args.buf].modifiable then
      vim.keymap.set('n', 'q', '<cmd>quit<cr>', { buffer = args.buf })
    end
  end,
})
-- Close some filetypes with <q>
-- new_autocmd('FileType', function(event)
--   vim.bo[event.buf].buflisted = false
--   vim.schedule(function()
--     vim.keymap.set('n', 'q', function()
--       vim.cmd 'close'
--       -- pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
--     end, {
--       buffer = event.buf,
--       silent = true,
--       desc = 'Quit buffer',
--     })
--   end)
-- end, ft_easy_quit, 'Close special filetypes with <q>')

-- Wrap and check for spell in text filetypes
new_autocmd('FileType', function()
  vim.opt_local.wrap = true
  vim.opt_local.spell = true
end, { 'text', 'plaintex', 'typst', 'gitcommit' }, 'Wrap and spell check for text filetypes')

-- Auto create dir when saving a file, in case some intermediate directory does not exist

vim.api.nvim_create_autocmd({ 'QuitPre' }, {
  pattern = '*',
  desc = 'Auto-close special windows on quit',
  callback = function()
    local all = vim.api.nvim_list_wins()
    local close = {}
    for _, win in ipairs(all) do
      local buf = vim.api.nvim_win_get_buf(win)
      local is_ft = vim.iter(ft_easy_quit):any(function(pat)
        return string.match(vim.bo[buf].ft, pat)
      end)
      if is_ft or not vim.bo[buf].modifiable then
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
  end,
})
--
-- -- Open Trouble for qflist
-- new_autocmd('QuickFixCmdPost', function()
--   vim.cmd [[Trouble qflist open]]
-- end, 'Open Trouble for qflist')
