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
  end
end
H.warn = function(msg)
  H.info(msg, 'WARN')
end
H.err = function(msg)
  H.info(msg, 'ERROR')
end
H.debug = function(msg)
  H.info(msg, 'DEBUG')
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
---@return string[]
H.get_workspace_files = function()
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

local function _detect_filetype(path)
  local filetype = vim.filetype.match { filename = path }

  -- vim.filetype.match is not guaranteed to work on filename alone (see https://github.com/neovim/neovim/issues/27265)
  if not filetype then
    for _, buf in ipairs(vim.fn.getbufinfo()) do
      if vim.fn.fnamemodify(buf.name, ':p') == path then
        return vim.filetype.match { buf = buf.bufnr }
      end
    end

    local bufn = vim.fn.bufadd(path)
    vim.fn.bufload(bufn)

    filetype = vim.filetype.match { buf = bufn }

    vim.api.nvim_buf_delete(bufn, { force = true })
  end

  return filetype
end

local _detected_filetypes = {}
local _dont_cache_these_extensions = { 'conf' }
H.get_filetype = function(path)
  local ext = vim.fn.fnamemodify(path, ':e')

  if rawget(_detected_filetypes, ext) ~= nil then
    return _detected_filetypes[ext]
  end

  local filetype = _detect_filetype(path)

  -- some file types share the same extension (see https://github.com/artemave/workspace-diagnostics.nvim/issues/3)
  -- so we never want to cache detection results for those ones.
  if not vim.tbl_contains(_dont_cache_these_extensions, ext) then
    _detected_filetypes[ext] = filetype or false
  end
  return filetype
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
