---@class vimrc.Utils
---@field log_level_names table<integer,string>
local M = {}
local PRIV = {}
-- Utilities ------------------------------------------------------------------

---@param ... string|number|boolean|table
---@return string
M.sprintf = function(...)
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

--- Print Lua objects in command line
---
---@param lvl string Log level of print function
---@return fun(...:any):...
local make_print_fn = function(lvl)
  return function(...)
    local objects = {}
    -- Not using `{...}` because it removes `nil` input
    for i = 1, select('#', ...) do
      local v = select(i, ...)
      table.insert(objects, vim.inspect(v))
    end

    if VimRc.notify then
      VimRc.notify(table.concat(objects, '\n'), lvl)
    else
      print(table.concat(objects, '\n'))
    end

    return ...
  end
end
---@param ... any
M.print = function(...)
  M.info(M.sprintf(...))
end
M.log_level_names = {}
for k, v in pairs(vim.log.levels) do
  M.log_level_names[v] = k
end

M.info = make_print_fn 'INFO'
M.warn = make_print_fn 'WARN'
M.err = make_print_fn 'ERROR'
M.debug = make_print_fn 'DEBUG'

-- Paths --------------------------------------------------------------------
---@param path string
---@param cwd string?
---@return string
M.short_path = function(path, cwd)
  cwd = cwd or vim.fn.getcwd()
  -- Ensure `cwd` is treated as directory path (to not match similar prefix)
  cwd = cwd:sub(-1) == '/' and cwd or (cwd .. '/')
  return vim.startswith(path, cwd) and path:sub(cwd:len() + 1) or vim.fn.fnamemodify(path, ':~')
end

---@param path string
---@return string
M.full_path = function(path)
  return (vim.fn.fnamemodify(path, ':p'):gsub('(.)/$', '%1'))
end

---@return string[]
M.get_workspace_files = function()
  local workspace_files = {}
  local folders = vim.lsp.buf.list_workspace_folders()
  if #folders > 0 and vim.uv.fs_stat(folders[0]) then
    local workspace_root = folders[0]
    if vim.uv.fs_stat(workspace_root .. '/.git') then
      workspace_files = vim.fn.split(vim.fn.system('git ls-files ' .. workspace_root), '\n')
    else
      VimRc.warn "Workspace is not a git repo. Cant' get files"
    end
  else
    local gitPath = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
    workspace_files = vim.fn.split(vim.fn.system('git ls-files ' .. gitPath), '\n')
  end

  workspace_files = vim.tbl_filter(function(path)
    return vim.fn.filereadable(path) == 1
  end, workspace_files)

  workspace_files = vim.tbl_map(function(path)
    return vim.fn.fnamemodify(path, ':p')
  end, workspace_files)
  return workspace_files
end

---@param timeout integer
---@param callback fun()
---@return uv.uv_timer_t?
M.setTimeout = function(timeout, callback)
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
-- Buffers --------------------------------------------------------------------
---@param buf_id integer
---@param name string
M.set_buf_name = function(buf_id, name)
  vim.api.nvim_buf_set_name(buf_id, 'vimrc://' .. buf_id .. '/' .. name)
end
---@param win_id any
---@return boolean
M.is_valid_win = function(win_id)
  return type(win_id) == 'number' and vim.api.nvim_win_is_valid(win_id)
end
---@param buf_id any
---@return boolean
M.is_valid_buf = function(buf_id)
  return type(buf_id) == 'number' and vim.api.nvim_buf_is_valid(buf_id)
end

---@param buf_id integer
M.buf_ensure_loaded = function(buf_id)
  if type(buf_id) ~= 'number' or vim.api.nvim_buf_is_loaded(buf_id) then
    return
  end
  local cache_eventignore = vim.o.eventignore
  vim.o.eventignore = 'BufEnter'
  pcall(vim.fn.bufload, buf_id)
  vim.o.eventignore = cache_eventignore
end

---@param buf_id integer
---@return string?
M.buf_get_name = function(buf_id)
  if not M.is_valid_buf(buf_id) then
    return nil
  end
  local buf_name = vim.api.nvim_buf_get_name(buf_id)
  if buf_name ~= '' then
    buf_name = vim.fn.fnamemodify(buf_name, ':~:.')
  end
  return buf_name
end

---@param buf_id integer
---@param lines string[]
PRIV.set_buflines = function(buf_id, lines)
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
end

PRIV.define_scratch_buf_window = function(cleanup)
  local buf_id, win_id = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  vim.bo.swapfile, vim.bo.buflisted = false, false

  -- Define action to finish editing Git related file
  local finish_au_id
  local finish = function(data)
    local should_close = data.buf == buf_id or (data.event == 'WinClosed' and tonumber(data.match) == win_id)
    if not should_close then
      return
    end

    pcall(vim.api.nvim_del_autocmd, finish_au_id)
    pcall(vim.api.nvim_win_close, win_id, true)
    vim.schedule(function()
      pcall(vim.api.nvim_buf_delete, buf_id, { force = true })
    end)

    if vim.is_callable(cleanup) then
      vim.schedule(cleanup)
    end
  end
  -- - Use `nested` to allow other events (`WinEnter` for 'mini.statusline')
  local events = { 'WinClosed', 'BufDelete', 'BufWipeout', 'VimLeave' }
  local opts = { nested = true, callback = finish, desc = 'Cleanup window and buffer' }
  finish_au_id = vim.api.nvim_create_autocmd(events, opts)
end
---@param lines string[]
---@param bufname string?
---@return integer
M.write_to_buffer = function(lines, bufname)
  local buf_id = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf_id, bufname or 'vimrc')
  PRIV.set_buflines(buf_id, lines)
  vim.api.nvim_set_current_buf(buf_id)
  PRIV.define_scratch_buf_window()
  return buf_id
end

---@param lines string[]
---@param name string?
---@param filetype string?
M.show_in_split = function(lines, name, filetype)
  -- Create a target window split
  local win_source = vim.api.nvim_get_current_win()
  vim.cmd 'vertical split'
  local win_stdout = vim.api.nvim_get_current_win()

  -- Prepare buffer
  local buf_id = M.write_to_buffer(lines, name)

  local has_filetype = not (filetype == nil or filetype == '')
  vim.bo[buf_id].filetype = filetype or 'vimrc'

  -- Completely unfold for no filetype output (like `:Git help`)
  if not has_filetype then
    vim.wo[win_stdout].foldlevel = 999
  end

  return win_source, win_stdout
end

return M
