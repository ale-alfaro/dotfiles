---@class vimrc.Utils
---@field log_level_names table<integer,string>
local M = {}
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
---@param lvl integer Log level of print function
---@return fun(...:any):...
local make_print_fn = function(lvl)
  return function(...)
    local objects = {}
    -- Not using `{...}` because it removes `nil` input
    for i = 1, select('#', ...) do
      local v = select(i, ...)
      table.insert(objects, vim.inspect(v))
    end

    vim.notify(table.concat(objects, '\n'), lvl)

    return ...
  end
end

M.debug = make_print_fn(vim.log.levels.DEBUG)
M.info = make_print_fn(vim.log.levels.INFO)
M.warn = make_print_fn(vim.log.levels.WARN)
M.err = make_print_fn(vim.log.levels.ERROR)

---@param value any
---@return boolean
M.is_truthy = function(value)
  return value ~= nil and value ~= false
end
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
--[[
--12. Special kinds of buffers			*special-buffers*

Instead of containing the text of a file, buffers can also be used for other
purposes.  A few options can be set to change the behavior of a buffer:
	'bufhidden'	what happens when the buffer is no longer displayed
			in a window.
	'buftype'	what kind of a buffer this is
	'swapfile'	whether the buffer will have a swap file
	'buflisted'	buffer shows up in the buffer list

A few useful kinds of a buffer:

quickfix	Used to contain the error list or the location list.  See
		|:cwindow| and |:lwindow|.  This command sets the 'buftype'
		option to "quickfix".  You are not supposed to change this!
		'swapfile' is off.

help		Contains a help file.  Will only be created with the |:help|
		command.  The flag that indicates a help buffer is internal
		and can't be changed.  The 'buflisted' option will be reset
		for a help buffer.

terminal	A terminal window buffer, see |terminal|.  The contents cannot
		be read or changed until the job ends.

directory	Displays directory contents.  Can be used by a file explorer
		plugin.  The buffer is created with these settings: >
			:setlocal buftype=nowrite
			:setlocal bufhidden=delete
			:setlocal noswapfile
<		The buffer name is the name of the directory and is adjusted
		when using the |:cd| command.

						*scratch-buffer*
scratch		Contains text that can be discarded at any time.  It is kept
		when closing the window, it must be deleted explicitly.
		Settings: >
			:setlocal buftype=nofile
			:setlocal bufhidden=hide
			:setlocal noswapfile
<		The buffer name can be used to identify the buffer, if you
		give it a meaningful name.

						*unlisted-buffer*
unlisted	The buffer is not in the buffer list.  It is not used for
		normal editing, but to show a help file, remember a file name
		or marks.  The ":bdelete" command will also set this option,
		thus it doesn't completely delete the buffer.  Settings: >
			:setlocal nobuflisted

--
--]]
---@generic T : any
---@param tbl T[]
---@param start_idx? number
---@param end_idx? number
---@return T[]
M.tbl_slice = function(tbl, start_idx, end_idx)
  local ret = {}
  if not start_idx then
    start_idx = 1
  end
  if not end_idx then
    end_idx = #tbl
  end
  for i = start_idx, end_idx do
    table.insert(ret, tbl[i])
  end
  return ret
end
M.new_scratch_buffer = function()
  vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(true, true))
end
---@param lines string[]
---@param name? string
M.show_in_unlisted_ro_only_buf = function(lines, name)
  local buf_id = vim.api.nvim_create_buf(false, true)
  if name then
    vim.api.nvim_buf_set_name(buf_id, name)
  end
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
  vim.api.nvim_set_current_buf(buf_id)
  vim.bo.filetype = 'vimrc'
  vim.bo.modifiable = false
  return buf_id
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
---@alias SplitType
---|'vert'
---|'hor'
---
---@param type?  SplitType
M.scratch_split = function(type)
  -- Create a target window split
  local win_source = vim.api.nvim_get_current_win()
  vim.api.nvim_cmd({
    cmd = type or 'vert',
    args = { 'split' },
  }, {})
  local win_stdout = vim.api.nvim_get_current_win()

  -- Prepare buffer
  M.new_scratch_buffer()

  return win_source, win_stdout
end
---@param lines string[]
---@param name string?
M.show_in_split = function(lines, name)
  -- Create a target window split
  local win_source = vim.api.nvim_get_current_win()
  vim.cmd 'vertical split '
  local win_stdout = vim.api.nvim_get_current_win()

  -- Prepare buffer
  M.show_in_unlisted_ro_only_buf(lines, name)

  return win_source, win_stdout
end

---@param cmd string
---@return string[]
M.shell_build_argv = function(cmd)
  local argv = {}

  -- If the shell starts with a quote, it contains spaces (from :help 'shell').
  -- The shell may also have additional arguments in it, separated by spaces.
  if vim.startswith(vim.o.shell, '"') then
    local quoted = vim.o.shell:match '^"([^"]+)"'
    table.insert(argv, quoted)
    vim.list_extend(argv, vim.split(vim.o.shell:sub(quoted:len() + 3), '%s+', { trimempty = true }))
  else
    vim.list_extend(argv, vim.split(vim.o.shell, '%s+'))
  end

  vim.list_extend(argv, vim.split(vim.o.shellcmdflag, '%s+', { trimempty = true }))

  if vim.o.shellxquote ~= '' then
    -- When shellxquote is "(", we should escape the shellxescape characters with '^'
    -- See :help 'shellxescape'
    if vim.o.shellxquote == '(' and vim.o.shellxescape ~= '' then
      cmd = cmd:gsub('.', function(char)
        if string.find(vim.o.shellxescape, char, 1, true) then
          return '^' .. char
        else
          return char
        end
      end)
    end

    if vim.o.shellxquote == '(' then
      cmd = '(' .. cmd .. ')'
    elseif vim.o.shellxquote == '"(' then
      cmd = '"(' .. cmd .. ')"'
    else
      cmd = vim.o.shellxquote .. cmd .. vim.o.shellxquote
    end
  end

  table.insert(argv, cmd)
  return argv
end
function M.run_command_async(cmd)
  local co = assert(coroutine.running())

  local stdout = {}
  local stderr = {}
  local exit_code = nil

  local jobid = vim.system(cmd, {
    text = true,
    stdout = function(_, data)
      if data then
        stdout[#stdout + 1] = data
      end
    end,
    stderr = function(_, data)
      stderr[#stderr + 1] = data
    end,
    function(_, code, _)
      exit_code = code
      coroutine.resume(co)
    end,
  })

  if jobid <= 0 then
    vim.notify(('[lspconfig] unable to run cmd: %s'):format(cmd), vim.log.levels.WARN)
    return nil
  end

  coroutine.yield()

  if exit_code ~= 0 then
    vim.notify(
      ('[lspconfig] cmd failed with code %d: %s\n%s'):format(exit_code, cmd, table.concat(stderr, '')),
      vim.log.levels.WARN
    )
    return nil
  end

  if next(stdout) == nil then
    return nil
  end
  return stdout and stdout or nil
end
M.with_preserved_view = function(op)
  local view = vim.fn.winsaveview()
  local ok, err = pcall(function()
    if type(op) == 'function' then
      op()
    else
      vim.cmd(('keepjumps keeppatterns %s'):format(op))
    end
  end)
  vim.fn.winrestview(view)
  if not ok then
    VimRc.err('[with_preserved_view]: ' .. (err or 'Unknown error'), vim.log.levels.ERROR)
  end
end
return M
