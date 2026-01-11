---@module "noice"
---@module "which-key"

vim.pack.add(_G.plug_spec {
  'catppuccin/nvim',
  -- 'folke/noice.nvim',
  'folke/which-key.nvim',
  -- 'mrjones2014/smart-splits.nvim',
  'MunifTanjim/nui.nvim',
  'rcarriga/nvim-notify',
})

-- Set up to not prefer extension-based icon for some extensions
local ext3_blocklist = { scm = true, txt = true, yml = true }
local ext4_blocklist = { json = true, yaml = true }
local mini_icons = require 'mini.icons'
mini_icons.setup {
  use_file_extension = function(ext, _)
    return not (ext3_blocklist[ext:sub(-3)] or ext4_blocklist[ext:sub(-4)])
  end,
}

-- Mock 'nvim-tree/nvim-web-devicons' for plugins without 'mini.icons' support.
-- Not needed for 'mini.nvim' or MiniMax, but might be useful for others.
mini_icons.mock_nvim_web_devicons()

-- Example for showing notifications in bottom right corner: >lua
local win_config = function()
  local has_statusline = vim.o.laststatus > 0
  local pad = vim.o.cmdheight + (has_statusline and 1 or 0)
  return { anchor = 'SE', col = vim.o.columns, row = vim.o.lines - pad }
end

--- # Notification specification ~
---
--- Notification is a table with the following keys:
---
--- - <msg> `(string)` - single string with notification message.
---   Use `\n` to delimit several lines.
--- - <level> `(string)` - notification level as key of |vim.log.levels|.
---   Like "ERROR", "WARN", "INFO", etc.
--- - <hl_group> `(string)` - highlight group with which notification is shown.
--- - <data> `(table)` - extra data to store in notification (like `source`, etc.).
--- - <ts_add> `(number)` - timestamp of when notification is added.
--- - <ts_update> `(number)` - timestamp of the latest notification update.
--- - <ts_remove> `(number|nil)` - timestamp of when notification is removed.
---   It is `nil` if notification was never removed and thus considered "active".
---
---@alias NotificationLevel 'ERROR' | 'WARN' | 'INFO' | 'DEBUG'
---@class Notification
---@field msg string
---@field level NotificationLevel
---@field hl_group string
---@field data table
---@field ts_add number
---@field ts_update number
---@field ts_remove number?

---@param notif Notification
local notif_format_basic = function(notif)
  local time = vim.fn.strftime('%H:%M:%S', math.floor(notif.ts_update))
  return string.format('[%s]: %s │ %s', notif.level, time, notif.msg)
end

---@return string
local function vim_print_modified(...)
  local msg = {}
  for i = 1, select('#', ...) do
    local o = select(i, ...)
    if type(o) == 'string' then
      table.insert(msg, o)
    else
      table.insert(msg, vim.inspect(o, { newline = '\n', indent = '  ' }))
    end
  end
  return table.concat(msg, '\n')
end

---@param notif Notification
---@return string
local notif_format_default = function(notif)
  if notif.data.source == 'lsp_progress' then
    return notif.msg
  elseif notif.data.object then
    local prefix = notif_format_basic(notif)
    return string.format('%s \n %s', prefix, vim_print_modified(notif.data.object))
  else
    return notif_format_basic(notif)
  end
end

-- Add LSP kind icons. Useful for 'mini.completion'.
mini_icons.tweak_lsp_kind 'append'
require('mini.notify').setup {
  content = {
    -- Use notification message as is for LSP progress
    format = notif_format_default,

    -- Show more recent notifications first
    sort = function(notif_arr)
      table.sort(notif_arr, function(a, b)
        return a.ts_update > b.ts_update
      end)
      return notif_arr
    end,
  },

  -- Window options
  window = {
    -- Floating window config
    config = win_config,

    -- Maximum window width as share (between 0 and 1) of available columns
    max_width_share = 0.6,

    -- Value of 'winblend' option
    winblend = 25,
  },
}

local set_buf_name = function(buf_id, name)
  vim.api.nvim_buf_set_name(buf_id, 'mininotify://' .. buf_id .. '/' .. name)
end
---@param notif_arr Notification[]
local show_notifications = function(notif_arr)
  local ns_id = vim.api.nvim_create_namespace 'MiniNotifyHighlight'

  local buf_id
  for _, id in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[id].filetype == 'mininotify-history' then
      buf_id = id
    end
  end
  if buf_id == nil then
    buf_id = vim.api.nvim_create_buf(true, true)
    set_buf_name(buf_id, 'history')
    vim.bo[buf_id].filetype = 'mininotify-history'
  end
  -- Ensure clear buffer
  vim.api.nvim_buf_clear_namespace(buf_id, ns_id, 0, -1)
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, true, {})

  -- Compute lines and highlight regions
  local lines, highlights = {}, {}
  for _, notif in ipairs(notif_arr) do
    local notif_lines = vim.split(notif.msg, '\n')
    for _, l in ipairs(notif_lines) do
      table.insert(lines, l)
    end
    table.insert(highlights, { group = notif.hl_group, from_line = #lines - #notif_lines + 1, to_line = #lines })
  end

  -- Set lines and highlighting
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, true, lines)
  local extmark_opts = { end_col = 0, hl_eol = true, hl_mode = 'combine' }
  for _, hi_data in ipairs(highlights) do
    extmark_opts.end_row, extmark_opts.hl_group = hi_data.to_line, hi_data.group
    vim.api.nvim_buf_set_extmark(buf_id, ns_id, hi_data.from_line - 1, 0, extmark_opts)
  end
  vim.api.nvim_win_set_buf(0, buf_id)
end

---@param pred (fun(Notification):boolean)?
---@param format (fun(Notification):string)?
local get_notif_arr = function(pred, format)
  -- Get notifications based on predicate
  local notif_arr = MiniNotify.get_all()
  if pred then
    notif_arr = vim.tbl_filter(function(notif)
      return pred(notif)
    end, notif_arr)
  end
  -- Prepare content
  table.sort(notif_arr, function(a, b)
    return a.ts_update < b.ts_update
  end)
  format = format or notif_format_default
  for _, notif in ipairs(notif_arr) do
    local res = format(notif)
    if type(res) ~= 'string' then
      _G.error 'Output of `content.format` should be string.'
    end
    notif.msg = res
  end
  return notif_arr
end

KEYS.define({
  {
    lhs = '<leader>na',
    rhs = function()
      -- Get active notifications
      local notifs = get_notif_arr(function(notif)
        return notif.ts_remove == nil
      end)
      show_notifications(notifs)
    end,
    opts = { desc = '[N]otification [A]ll' },
  },
  -- {
  --   lhs = '<leader>nf',
  --   rhs = '<Cmd>Noice fzf<CR>',
  --   opts = { desc = '[N]otification [F]ind' },
  -- },
  {
    lhs = '<leader>nh',
    rhs = '<Cmd>lua MiniNotify.show_history()<CR>',
    opts = { desc = '[N]otification [H]istory' },
  },
  {
    lhs = '<leader>ne',
    rhs = function()
      -- Get active notifications
      local err_notifs = get_notif_arr(function(notif)
        return notif.level ~= 'ERROR'
      end)
      show_notifications(err_notifs)
    end,
    opts = { desc = '[N]otification [E]rrors' },
  },
  {
    lhs = '<leader>nd',
    rhs = '<Cmd>lua MiniNotify.clear()<CR>',
    opts = { desc = '[N]otification [D]ismiss' },
  },
}, { prefix = '<leader>n', group = 'Notification' })
-- Similar to 'mhinz/vim-startify' ~
local MiniStarter = require 'mini.starter'
MiniStarter.setup {
  evaluate_single = true,
  items = {
    MiniStarter.sections.builtin_actions(),
    MiniStarter.sections.recent_files(10, false),
    MiniStarter.sections.recent_files(10, true),
    MiniStarter.sections.pick(),
  },
  content_hooks = {
    MiniStarter.gen_hook.adding_bullet(),
    MiniStarter.gen_hook.indexing('all', { 'Builtin actions' }),
    MiniStarter.gen_hook.padding(3, 2),
  },
}
require('mini.statusline').setup()

-- Tabline. Sets `:h 'tabline'` to show all listed buffers in a line at the top.
-- Buffers are ordered as they were created. Navigate with `[b` and `]b`.
require('mini.tabline').setup()
require('catppuccin').setup {
  flavour = 'macchiato', -- latte, frappe, macchiato, mocha
  background = { -- :h background
    light = 'latte',
    dark = 'mocha',
  },
}
vim.cmd 'colorscheme catppuccin'
-- It is not enabled by default because it is not really needed on a daily basis.
-- Uncomment next line (use `gcc`) to enable.
require('mini.hipatterns').setup {
  highlighters = {
    fixme = require('mini.extra').gen_highlighter.words({ 'FIXME', 'Fixme', 'fixme' }, 'MiniHipatternsFixme'),
    hack = require('mini.extra').gen_highlighter.words({ 'HACK', 'Hack', 'hack' }, 'MiniHipatternsHack'),
    todo = require('mini.extra').gen_highlighter.words({ 'TODO', 'Todo', 'todo' }, 'MiniHipatternsTodo'),
    note = require('mini.extra').gen_highlighter.words({ 'NOTE', 'Note', 'note' }, 'MiniHipatternsNote'),
    hex_color = require('mini.hipatterns').gen_highlighter.hex_color(),
  },
}

-- Which-key
require('which-key').setup {
  preset = 'helix',
  defaults = {},
  spec = {
    mode = { 'n', 'v' },
    { '<leader>c', group = 'Code' },
    { '<leader>x', group = 'diagnostics/quickfix' },
    { '[', group = 'prev' },
    { ']', group = 'next' },
    { 'g', group = 'goto' },
    { 'gs', group = 'surround' },
    { 'z', group = 'fold' },
    {
      '<leader>b',
      group = 'buffer',
      expand = function()
        return require('which-key.extras').expand.buf()
      end,
    },
    {
      '<leader>w',
      group = 'windows',
      proxy = '<c-w>',
      expand = function()
        return require('which-key.extras').expand.win()
      end,
    },
  },
}
