if VimRc.THEME == 'kanagawa' then
  vim.pack.add(_G.plug_spec {
    'rebelot/kanagawa.nvim',
  })
  vim.cmd 'colorscheme kanagawa'
elseif VimRc.THEME == 'matte-black' then
  vim.pack.add(_G.plug_spec {
    'tahayvr/matteblack.nvim',
  })
  require('matteblack').colorscheme()
else
  vim.pack.add(_G.plug_spec {
    'catppuccin/nvim',
  })
  require('catppuccin').setup {
    flavour = 'macchiato', -- latte, frappe, macchiato, mocha
    background = { -- :h background
      light = 'latte',
      dark = 'mocha',
    },
  }
end
-- Set up to not prefer extension-based icon for some extensions
local ext3_blocklist = { scm = true, txt = true, yml = true }
local ext4_blocklist = { json = true, yaml = true }
local mini_icons = require 'mini.icons'
mini_icons.setup {
  use_file_extension = function(ext, _)
    return not (ext3_blocklist[ext:sub(-3)] or ext4_blocklist[ext:sub(-4)])
  end,
}

local starter = require 'mini.starter'
starter.setup {
  items = {
    { action = 'FzfLua global', name = 'Browser', section = 'Fzf' },
    { action = 'FzfLua history', name = 'Command history', section = 'Fzf' },
    { action = 'FzfLua files', name = 'Files', section = 'Fzf' },
    { action = 'FzfLua helptags', name = 'Help tags', section = 'Fzf' },
    { action = 'FzfLua live_grep', name = 'Live grep', section = 'Fzf' },
    { action = 'FzfLua oldfiles', name = 'Old files', section = 'Fzf' },
  },
  content_hooks = {
    starter.gen_hook.adding_bullet(),
    starter.gen_hook.aligning('center', 'center'),
  },
}

-- Mock 'nvim-tree/nvim-web-devicons' for plugins without 'mini.icons' support.
-- Not needed for 'mini.nvim' or MiniMax, but might be useful for others.
mini_icons.mock_nvim_web_devicons()
require('mini.statusline').setup()
-- Tabline. Sets `:h 'tabline'` to show all listed buffers in a line at the top.
-- Buffers are ordered as they were created. Navigate with `[b` and `]b`.
--require('mini.tabline').setup()
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
-- Example for showing notifications in bottom right corner: >lua

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

---@param notif Notification
---@return string
local notif_format_default = function(notif)
  if notif.data.source == 'lsp_progress' then
    return notif.msg
  elseif notif.data.object then
    local prefix = notif_format_basic(notif)
    return string.format('%s \n %s', prefix, VimRc.print(notif.data.object))
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
    -- config = function()
    --   local has_statusline = vim.o.laststatus > 0
    --   local pad = vim.o.cmdheight + (has_statusline and 1 or 0)
    --   return { anchor = 'NE', col = vim.o.columns, row = vim.o.lines - pad }
    -- end,

    -- -- Maximum window width as share (between 0 and 1) of available columns
    max_width_share = 0.6,
    --
    -- -- Value of 'winblend' option
    winblend = 25,
  },
}

vim.notify = MiniNotify.make_notify()
vim.api.nvim_set_hl(0, 'VimRcError', { link = 'StderrMsg' })
vim.api.nvim_set_hl(0, 'VimRcWarn', { link = 'WarningMsg' })
vim.api.nvim_set_hl(0, 'VimRcNormal', { link = 'PmenuKindSel' })
--stylua: ignore
VimRc.loglvl_opts= {
  ERROR = { duration = 5000, hl_group = 'VimRcError' },
  WARN  = { duration = 5000, hl_group = 'VimRcWarn' },
  INFO  = { duration = 5000, hl_group = 'PmenuMatch' },
  DEBUG = { duration = 0, hl_group = 'ComplHint' },
  TRACE = { duration = 0, hl_group = 'LineNr' },
  OFF   = { duration = 0, hl_group = 'LineNr' },
}

VimRc.notify = function(msg, lvl)
  VimRc.check_type('msg', msg, 'string')
  local level_data = VimRc.loglvl_opts[lvl]
  if not level_data or level_data.duration <= 0 then
    return
  end

  local id = MiniNotify.add(msg, lvl, level_data.hl_group, { source = 'VimRc' })
  vim.defer_fn(function()
    MiniNotify.remove(id)
  end, level_data.duration)
end
---@param notif_arr Notification[]
local show_notifications = function(notif_arr)
  local ns_id = vim.api.nvim_create_namespace 'MiniNotifyHighlight'

  local buf_id
  for _, id in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[id].filetype == 'vimrc-notify' then
      buf_id = id
    end
  end
  if buf_id == nil then
    buf_id = vim.api.nvim_create_buf(true, true)
    VimRc.set_buf_name(buf_id, 'notify')
    vim.bo[buf_id].filetype = 'vimrc-notify'
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
      VimRc.error 'Output of `content.format` should be string.'
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
        return notif.ts_remove ~= nil
      end)
      show_notifications(notifs)
    end,
    opts = { desc = '[N]otification [A]ll' },
  },
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
        return notif.level == 'ERROR'
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
