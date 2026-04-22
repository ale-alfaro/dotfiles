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
local function coerce(v)
  if v == vim.NIL then
    return nil
  else
    return v
  end
end

---@param path table
---@param k string
---@param factory fun(path: obsidian.Path): any
---@private
local function cached_get(path, k, factory)
  local cache_key = '__' .. k
  local v = rawget(path, cache_key)
  if v == nil then
    v = factory(path)
    if v == nil then
      v = vim.NIL
    end
    path[cache_key] = v
  end
  return coerce(v)
end

--- A `Path` class that provides a subset of the functionality of the Python `pathlib` library while
--- staying true to its API. It improves on a number of bugs in `plenary.path`.
---
---@toc_entry obsidian.Path
---
---@class obsidian.Path
---
---@field filename string The underlying filename as a string.
---@field name string|? The final path component, if any.
---@field suffix string|? The final extension of the path, if any.
---@field stem string The final path component, without its suffix.
---@operator div(string|obsidian.Path): obsidian.Path
local Path = {}

Path.__tostring = function(self)
  return self.filename
end

Path.__eq = function(a, b)
  return a.filename == b.filename
end
Path.__div = function(self, other)
  return Path.new(vim.fs.joinpath(self.filename, tostring(other)))
end

Path.__index = function(self, k)
  local raw = rawget(Path, k)
  if raw then
    return raw
  end

  local factory
  if k == 'name' then
    factory = function(path)
      return vim.fs.basename(path.filename)
    end
  elseif k == 'suffix' then
    factory = function(path)
      return vim.fs.ext(path.filename)
    end
  elseif k == 'stem' then
    factory = function(path)
      return vim.fs.basename(path.filename):gsub('%.' .. vim.fs.ext(path.filename))
    end
  end

  if factory then
    return cached_get(self, k, factory)
  end
end

--- Check if an object is an `obsidian.Path` object.
---
---@param path any
---
---@return boolean
Path.is_path_obj = function(path)
  if getmetatable(path) == Path then
    return true
  else
    return false
  end
end

-------------------------------------------------------------------------------
--- Constructors.
-------------------------------------------------------------------------------

--- Create a new path from a string.
---
---@param p string|obsidian.Path
---
---@return obsidian.Path
Path.new = function(p)
  local self = {}

  if Path.is_path_obj(p) then
    ---@cast p -string
    return p
  end
  --- Path is expanded to an absolute path
  self.filename = vim.fs.normalize(tostring(p))

  return setmetatable(self, Path)
end

--- Get a temporary path with a unique name.
---
---@param opts { suffix: string|? }|?
---
---@return obsidian.Path
Path.temp = function(opts)
  opts = opts or {}
  local tmpname = vim.fn.tempname()
  if opts.suffix then
    tmpname = tmpname .. opts.suffix
  end
  return Path.new(tmpname)
end

--- Get a path corresponding to a buffer.
---
---@param bufnr integer|? The buffer number or `0` / `nil` for the current buffer.
---
---@return obsidian.Path
Path.buffer = function(bufnr)
  return Path.new(vim.api.nvim_buf_get_name(bufnr or 0))
end

--- Try to resolve a version of the path relative to the other.
--- An error is raised when it's not possible.
---
---@param other obsidian.Path|string
---
---@return obsidian.Path?
Path.relative_to = function(self, other)
  other = (type(other) == 'string') and Path.new(other) or other

  local common_prefix = string.match(other.filename, '^' .. self.filename)
  if common_prefix then
    common_prefix = common_prefix:gsub('%w$', '%1/')
    return Path.new(other.filename:gsub(common_prefix, ''))
  end
  return nil
end
--- The logical parent of the path.
---
---@return obsidian.Path|?
Path.parent = function(self)
  local parent = vim.fs.dirname(self.filename)
  if parent ~= nil then
    return Path.new(parent)
  else
    return nil
  end
end

--- Get a list of the parent directories.
---
---@return obsidian.Path[]
Path.parents = function(self)
  return vim.iter(vim.fs.parents(self.filename)):map(Path.new):totable()
end

--- Check if the path is a parent of other. This is a pure path method, so it only checks by
--- comparing strings. Therefore in practice you probably want to `:resolve()` each path before
--- using this.
---
---@param other obsidian.Path|string
---
---@return boolean
Path.is_parent_of = function(self, other)
  other = Path.new(other)
  for _, parent in ipairs(other:parents()) do
    if parent == self then
      return true
    end
  end
  return false
end

--- Get OS stat results.
---
---@return boolean
Path.exists = function(self)
  local realpath = vim.fs.abspath(self.filename)
  if realpath then
    local stat, _ = vim.uv.fs_stat(realpath)
    return stat ~= nil
  end
  return false
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
