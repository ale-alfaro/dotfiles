--
-- ---@class snacks.notify
-- ---@overload fun(msg: string|string[], opts?: snacks.notify.Opts)
local M = setmetatable({}, {
  __call = function(t, ...)
    return t.notify(...)
  end,
})

M.meta = {
  desc = "Utility functions to work with Neovim's `vim.notify`",
}

---@alias snacks.notify.Opts snacks.notifier.Notif.opts|{once?: boolean}

---@param msg string|string[]
---@param level string
---@param comment string
function M.notify(msg, level, comment)
  msg = type(msg) == "table" and table.concat(msg, "\n") or msg --[[@as string]]
  msg = vim.trim(msg)
  local id = MiniNotify.add(msg, level, comment)
  vim.defer_fn(function() MiniNotify.remove(id) end, 1000)
end

---@param msg string|string[]
---@param opts? snacks.notify.Opts
function M.warn(msg, opts)
  return M.notify(msg, "WARN")
end

---@param msg string|string[]
---@param opts? snacks.notify.Opts
function M.info(msg, opts)
  return M.notify(msg, "INFO")
end

---@param msg string|string[]
---@param opts? snacks.notify.Opts
function M.error(msg, opts)
  return M.notify(msg, "ERROR")
end

-- delay notifications till vim.notify was replaced or after 500ms
function M.lazy_notify()
  local notifs = {}
  local function temp(...)
    table.insert(notifs, vim.F.pack_len(...))
  end

  local orig = vim.notify
  vim.notify = temp

  local timer = vim.uv.new_timer()
  local check = assert(vim.uv.new_check())

  local replay = function()
    timer:stop()

    check:stop()
    if vim.notify == temp then
      vim.notify = orig -- put back the original notify if needed
    end
    vim.schedule(function()
      ---@diagnostic disable-next-line: no-unknown
      for _, notif in ipairs(notifs) do
        vim.notify(vim.F.unpack_len(notif))
      end
    end)
  end

  -- wait till vim.notify has been replaced
  check:start(function()
    if vim.notify ~= temp then
      replay()
    end
  end)
  -- or if it took more than 500ms, then something went wrong
  timer:start(500, 0, replay)
end
return M
