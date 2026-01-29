H = {}
-- Utilities ------------------------------------------------------------------

---@return string
H.sprintf = function(...)
  local msg = {}
  for i = 1, select('#', ...) do
    local o = select(i, ...)
    if type(o) == 'string' then
      table.insert(msg, o)
    elseif vim.list_contains({ 'number', 'table', 'boolean' }, type(o)) then
      table.insert(msg, vim.inspect(o, { newline = '\n', indent = '  ' }))
    else
      error(string.format('Invalid type trying to be printed. Type=%s', type(o)), 0)
    end
  end
  return table.concat(msg, '\n')
end

H.print = function(...)
  H.info(H.sprintf(...))
end
H.log_level_names = {}
for k, v in pairs(vim.log.levels) do
  H.log_level_names[v] = k
end

H.check_type = function(name, val, ref, allow_nil)
  if type(val) == ref or (ref == 'callable' and vim.is_callable(val)) or (allow_nil and val == nil) then
    return
  end
  error(string.format('`%s` should be %s, not %s', name, ref, type(val)), 0)
end

---@return table
H.ensure_list = function(x)
  x = vim._ensure_list(x)
  if #x > 0 then
    return x
  end
  error(string.format('`%s` should be a list or item, but it is empty', x), 0)
end
H.info = function(msg, lvl)
  msg = type(msg) == 'string' and msg or H.sprintf(msg)
  lvl = lvl or 'INFO'
  if type(lvl) == 'number' then
    lvl = H.log_level_names[lvl]
  elseif type(lvl) ~= 'string' then
    H.error 'Log level must be a string or a vim.log.levels number'
    return
  end
  if VimRc.notify then
    VimRc.notify(msg, lvl)
  else
    vim.notify(msg, lvl)
  end
end
H.warn = function(msg)
  H.info(msg, 'WARN')
end
H.err = function(msg)
  H.info(msg, 'ERROR')
end
H.set_buf_name = function(buf_id, name)
  vim.api.nvim_buf_set_name(buf_id, 'vimrc://' .. buf_id .. '/' .. name)
end

H.is_valid_win = function(win_id)
  return type(win_id) == 'number' and vim.api.nvim_win_is_valid(win_id)
end

H.full_path = function(path)
  return (vim.fn.fnamemodify(path, ':p'):gsub('(.)/$', '%1'))
end
H.normalize_path = function(path)
  return path
end

H.short_path = function(path, cwd)
  cwd = cwd or vim.fn.getcwd()
  -- Ensure `cwd` is treated as directory path (to not match similar prefix)
  cwd = cwd:sub(-1) == '/' and cwd or (cwd .. '/')
  return vim.startswith(path, cwd) and path:sub(cwd:len() + 1) or vim.fn.fnamemodify(path, ':~')
end

function _G.setTimeout(timeout, callback)
  local timer = vim.uv.new_timer()
  if timer ~= nil then
    timer:start(timeout, 0, function()
      timer:stop()
      timer:close()
      callback()
    end)
    return timer
  end
end
return H
