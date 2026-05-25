-- maximum width of notify
--
local has_statusline = vim.o.laststatus > 0
local NOTIFY_WIDTH_PAD = vim.o.cmdheight + (has_statusline and 1 or 0)
local available = vim.o.lines - NOTIFY_WIDTH_PAD
local NOTIFY_WIDTH = math.floor(0.6 * vim.o.columns)

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
    return string.format('%s \n %s', prefix, MiniMisc.put { object = notif.data.object })
  else
    return notif_format_basic(notif)
  end
end
