-- maximum width of notify
local NOTIFY_WIDTH = 100

--- to display progress when the server supports percentages
local PROGRESS = { '⡀', '⣀', '⣄', '⣤', '⣦', '⣶', '⣷', '⣿' }

--- to display infinite progress, when percentage is unavailable
local INFINITE_PROGRESS = { '⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷' }
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
---@param notif_arr Notification[]
local show_notifications = function(notif_arr)
  local ns_id = vim.api.nvim_create_namespace 'MiniNotifyHighlight'

  local buf_id
  for _, id in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[id].filetype == 'vimrc-notify' then
      buf_id = id
    end
  end
  -- Ensure clear buffer
  -- vim.api.nvim_buf_clear_namespace(buf_id, ns_id, 0, -1)
  -- vim.api.nvim_buf_set_lines(buf_id, 0, -1, true, {})

  -- Compute lines and highlight regions
  local lines, highlights = {}, {}
  for _, notif in ipairs(notif_arr) do
    local notif_lines = vim.split(notif.msg, '\n')
    for _, l in ipairs(notif_lines) do
      table.insert(lines, l)
    end
    table.insert(highlights, { group = notif.hl_group, from_line = #lines - #notif_lines + 1, to_line = #lines })
  end

  if buf_id ~= nil then
    vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
  else
    buf_id = VimRc.write_to_buffer(lines, 'notify')
  end
  -- Set lines and highlighting
  local extmark_opts = { end_col = 0, hl_eol = true, hl_mode = 'combine' }
  for _, hi_data in ipairs(highlights) do
    extmark_opts.end_row, extmark_opts.hl_group = hi_data.to_line, hi_data.group
    vim.api.nvim_buf_set_extmark(buf_id, ns_id, hi_data.from_line - 1, 0, extmark_opts)
  end
  vim.api.nvim_set_current_buf(buf_id)
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
      VimRc.err 'Output of `content.format` should be string.'
    end
    notif.msg = res
  end
  return notif_arr
end

--- @param item table
--- @return string message
local function message(item)
  local value = item.data.response.value --[[@as table]]
  if value.kind == 'end' then
    -- when complete, indicate how much time it took the operation
    return string.format('%.2fs', item.ts_update - item.ts_add)
  elseif value.message and value.title and vim.startswith(value.message, value.title) then
    -- best effort to remove redundancy (title == message, title startswith message, etc)
    return vim.trim(value.message:sub(#value.title + 1))
  else
    return value.message or ''
  end
end
--- @param str string
--- @param length integer
--- @return string truncated string
local function trunc(str, length)
  str = str or ''
  -- remove "..." present in messages/titles as it only wastes space (looking at you JDTLS)
  local smaller = str:gsub('[.][.][.]', '')
  -- truncate to length and use "..." to indicate we truncated
  return #smaller > length and (smaller:sub(1, length - 3) .. '...') or smaller
end

--- @param item table
--- @return string icon
local function icon(item)
  local value = item.data.response.value --[[@as table]]
  if value.kind == 'end' then
    return '✔'
  elseif value.percentage and value.percentage > 0 then
    return PROGRESS[math.ceil(math.max(1, value.percentage) / 100 * #PROGRESS)] or '?'
  else
    local index = assert(vim.uv.gettimeofday()) % #INFINITE_PROGRESS
    return INFINITE_PROGRESS[1 + index] or '?'
  end
end

--- Format LSP message as "message title [client] ICON",
--- this results in the least "movement", only the "message" really changes width
--- @param item table
--- @return string result
local function format_lsp(item)
  local client_name = trunc(item.data.client_name, 13) --[[@as string]]
  local remaining = NOTIFY_WIDTH - 6 - #client_name
  local value = item.data.response.value --[[@as table]]
  local title = trunc(value.title, remaining - 10)
  remaining = remaining - #title
  local msg = trunc(message(item), remaining)
  local output = string.format('%s %s [%s] %s', msg, title, client_name, icon(item))
  local width = vim.fn.strdisplaywidth(output)
  return string.rep(' ', NOTIFY_WIDTH - width) .. output
end
local notify = require 'mini.notify'

notify.setup {
  content = {
    -- Use notification message as is for LSP progress
    format = function(item)
      if item.data.source == 'lsp_progress' then
        return format_lsp(item)
      elseif item.data.source == 'vim.notify' then
        local output = string.format('%s ■', trunc(item.msg, NOTIFY_WIDTH - 6))
        local width = vim.fn.strdisplaywidth(output)
        return string.rep(' ', NOTIFY_WIDTH - width) .. output
      else
        return notify.default_format(item)
      end
    end,

    -- Show more recent notifications first
    sort = function(notif_arr)
      table.sort(notif_arr, function(a, b)
        return a.ts_update > b.ts_update
      end)
      return notif_arr
    end,
  },

  window = {
    -- Undo the adjusted height since we aren't wrapping but instead truncating
    -- Place at bottom right of screen
    config = function(buffer)
      local count = vim.api.nvim_buf_line_count(buffer)
      local has_statusline = vim.o.laststatus > 0
      local pad = vim.o.cmdheight + (has_statusline and 1 or 0)
      return {
        anchor = 'SE',
        col = vim.o.columns,
        row = vim.o.lines - pad,
        width = NOTIFY_WIDTH,
        height = count,
        border = 'none',
      }
    end,
    max_width_share = 0.6,
    --
    -- -- Value of 'winblend' option
    winblend = 25,
  },
  lsp_progress = {
    duration_last = 2500,
  },
}
vim.notify = MiniNotify.make_notify()
vim.api.nvim_set_hl(0, 'VimRcError', { link = 'StderrMsg' })
vim.api.nvim_set_hl(0, 'VimRcWarn', { link = 'WarningMsg' })
vim.api.nvim_set_hl(0, 'VimRcNormal', { link = 'PmenuKindSel' })
VimRc.loglvl_opts = {
  ERROR = { duration = 5000, hl_group = 'VimRcError' },
  WARN = { duration = 5000, hl_group = 'VimRcWarn' },
  INFO = { duration = 5000, hl_group = 'PmenuMatch' },
  DEBUG = { duration = 0, hl_group = 'ComplHint' },
  TRACE = { duration = 0, hl_group = 'LineNr' },
  OFF = { duration = 0, hl_group = 'LineNr' },
}

VimRc.notify = function(msg, lvl)
  vim.validate('msg', msg, 'string')
  local level_data = VimRc.loglvl_opts[lvl]
  if not level_data or level_data.duration <= 0 then
    return
  end

  local id = MiniNotify.add(msg, lvl, level_data.hl_group, { source = 'VimRc' })
  vim.defer_fn(function()
    MiniNotify.remove(id)
  end, level_data.duration)
end

local keymaps = {
  {
    '<leader>na',
    function()
      -- Get active notifications
      local notifs = get_notif_arr(function(notif)
        return notif.ts_remove ~= nil
      end)
      show_notifications(notifs)
    end,
    '[N]otification [A]ll',
  },
  {
    '<leader>nh',
    '<Cmd>lua MiniNotify.show_history()<CR>',
    '[N]otification [H]istory',
  },
  {
    '<leader>ne',
    function()
      -- Get active notifications
      local err_notifs = get_notif_arr(function(notif)
        return notif.level == 'ERROR'
      end)
      show_notifications(err_notifs)
    end,
    '[N]otification [E]rrors',
  },
  {
    '<leader>nd',
    '<Cmd>lua MiniNotify.clear()<CR>',
    '[N]otification [D]ismiss',
  },
}

for _, k in ipairs(keymaps) do
  vim.keymap.set('n', k[1], k[2], { desc = k[3] })
end
