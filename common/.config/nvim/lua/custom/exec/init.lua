local M = {}

local uv = vim.uv or vim.loop
vim.env.PATH = vim.env.HOME .. '/.local/share/mise/shims:' .. vim.env.PATH
M.env = vim.fn.environ() or {}
M.append_path = function(path)
  vim.validate('path', path, 'string')
  if not uv.fs_stat(path) then
    VimRc.err('Failed to append to PATH: ' .. path)
    return nil
  end
  vim.fn.setenv('PATH', string.format('%$PATH:%s', path))
  return vim.fn.getenv 'PATH'
end
---Get environment variable
---@description Use for getting with fallback
---@param name string
---@param fallback? string
M.getenv = function(name, fallback)
  vim.validate('name', name, 'string')
  vim.validate('fallback', fallback, 'string', true)
  if VimRc.env[name] then
    return VimRc.env[name]
  elseif fallback then
    return fallback
  else
    VimRc.err('Failed to get env: ' .. name)
  end
end
-- Prepend mise shims to PATH
-- 'WEST_TOPDIR'
function M.check_env(name)
  return vim.fn.has_key(vim.fn.environ(), name)
end

---@class vimrc.exec.Error
---@field code exec.ERROR_CODE
---@field message string
---@field debounce_message? boolean

---@enum exec.ERROR_CODE
M.ERROR_CODE = {
  -- Error occurred during when calling vim.system
  VIM_SYSTEM = 3,
  -- Command timed out during execution
  TIMEOUT = 4,
  -- Command was pre-empted by another call to format
  INTERRUPTED = 5,
  -- Command produced an error during execution
  RUNTIME = 6,
}
---@alias Stream uv.uv_stream_t

---@class CliRunOpts : uv.spawn.options
--- Command line arguments as a list of strings. The first string should be the path to the program. On Windows, this uses CreateProcess which concatenates the arguments into a string. This can cause some strange errors. (See `options.verbatim` below for Windows.)
---@field args string[]
---
--- Set environment variables for the new process.
---@field env table<string, string>
---@field stdin  uv.spawn.options.stdio

-- CLI ------------------------------------------------------------------------
---@param env_vars table
---@return table
M.make_spawn_env = function(env_vars)
  -- Setup all environment variables (`vim.loop.spawn()` by default has none)
  local environ = vim.tbl_deep_extend('force', vim.loop.os_environ(), env_vars)
  local res = {}
  for k, v in pairs(environ) do
    table.insert(res, string.format('%s=%s', k, tostring(v)))
  end
  return res
end

---@param command string[]
---@param cwd? string
---@param on_done? fun(ret:integer, stdout:string, stderr:string)
---@param opts? table
---@return table<integer, string, string>|nil
M.cli_run = function(command, cwd, on_done, opts)
  local spawn_opts = opts or {}
  local timeout = spawn_opts.timeout or 100
  local stdin_data = spawn_opts.stdin
  spawn_opts.stdin, spawn_opts.timeout = nil, nil
  local executable, args = command[1], vim.list_slice(command, 2, #command)
  local stdin_pipe = stdin_data and vim.loop.new_pipe() or nil
  local stdout, stderr = vim.loop.new_pipe(), vim.loop.new_pipe()
  local process = nil
  spawn_opts.args, spawn_opts.cwd, spawn_opts.stdio = args, cwd or vim.fn.getcwd(), { stdin_pipe, stdout, stderr }

  -- Allow `on_done = nil` to mean synchronous execution
  local is_sync, res = false, nil
  if on_done == nil then
    is_sync = true
    on_done = function(code, out, err)
      res = { code = code, out = out, err = err }
    end
  end

  local out, err, is_done = {}, {}, false
  local on_exit = function(code)
    -- Ensure calling this only once
    if is_done then
      return
    end
    is_done = true
    if not process then
      return
    end
    if process:is_closing() then
      return
    end
    process:close()

    -- Convert to strings appropriate for notifications
    local str_out = M.cli_stream_tostring(out)
    local str_err = M.cli_stream_tostring(err):gsub('\r+', '\n'):gsub('\n%s+\n', '\n\n')
    on_done(code, str_out, str_err)
  end
  ---@type uv.uv_process_t?
  process = vim.loop.spawn(executable, spawn_opts, on_exit)
  if stdin_pipe and stdin_data then
    stdin_pipe:write(stdin_data)
    stdin_pipe:shutdown(function()
      stdin_pipe:close()
    end)
  end
  M.cli_read_stream(assert(stdout), out)
  M.cli_read_stream(assert(stderr), err)
  vim.defer_fn(function()
    if not process or not process:is_active() then
      return
    end
    M.notify('PROCESS REACHED TIMEOUT', 'WARN')
    on_exit(1)
  end, timeout)

  if is_sync then
    vim.wait(timeout + 10, function()
      return is_done
    end, 1)
  end
  return res
end
---@param stream uv.uv_pipe_t
---@param feed string[]
M.cli_read_stream = function(stream, feed)
  stream:read_start(function(err, data)
    if err then
      return table.insert(feed, 1, 'ERROR: ' .. err)
    end
    if data ~= nil then
      return table.insert(feed, data)
    end
    stream:close()
  end)
end

M.notify = function(msg, level)
  vim.schedule(function()
    vim.notify('[exec] ' .. msg, vim.log.levels[level] or vim.log.levels.INFO)
  end)
end

---@param stream string[]
---@return string
M.cli_stream_tostring = function(stream)
  return (table.concat(stream):gsub('\n+$', ''))
end

M.cli_err_notify = function(code, out, err)
  local should_stop = code ~= 0
  if should_stop then
    M.notify(err .. (out == '' and '' or ('\n' .. out)), 'ERROR')
  end
  if not should_stop and err ~= '' then
    M.notify(err, 'WARN')
  end
  return should_stop
end

---@param x string
---@return string
M.cli_escape = function(x)
  return (string.gsub(x, '([ \\])', '\\%1'))
end

-- Buffers --------------------------------------------------------------------
M.is_valid_buf = function(buf_id)
  return type(buf_id) == 'number' and vim.api.nvim_buf_is_valid(buf_id)
end

M.buf_ensure_loaded = function(buf_id)
  if type(buf_id) ~= 'number' or vim.api.nvim_buf_is_loaded(buf_id) then
    return
  end
  local cache_eventignore = vim.o.eventignore
  vim.o.eventignore = 'BufEnter'
  pcall(vim.fn.bufload, buf_id)
  vim.o.eventignore = cache_eventignore
end

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

M.set_buflines = function(buf_id, lines)
  vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
end
-- Command --------------------------------------------------------------------
local executables_cache = {}
---Run a system command.
---@param cmd string[] command arguments
---@return table<integer, string, string>
function M.run_cmd_sync(cmd)
  if #cmd == 0 then
    error 'No command provided'
  end

  executables_cache[cmd[1]] = executables_cache[cmd[1]] or vim.fn.executable(cmd[1]) == 1
  if not executables_cache[cmd[1]] then
    error(string.format('`%s` is not executable (not found on `$PATH`)', cmd[1]))
  end

  return assert(M.cli_run(cmd))
end

---Run a system command.
---@param cmd string[] command arguments
---@param on_done fun(ret:integer, stdout:string, stderr:string)
function M.run_cmd(cmd, on_done)
  if #cmd == 0 then
    error 'No command provided'
  end

  executables_cache[cmd[1]] = executables_cache[cmd[1]] or vim.fn.executable(cmd[1]) == 1
  if not executables_cache[cmd[1]] then
    error(string.format('`%s` is not executable (not found on `$PATH`)', cmd[1]))
  end

  M.cli_run(cmd, nil, on_done)
end
---@param cmd string|string[]
---@return string|nil
function M.west(cmd)
  local full = { 'west' }
  if type(cmd) == 'table' then
    full = vim.list_extend({ 'west' }, cmd, 1, #cmd + 1)
  elseif type(cmd) == 'string' then
    for c in vim.gsplit(cmd, ' ', { plain = true, trimempty = true }) do
      table.insert(full, c)
    end
  else
    VimRc.err('Invalid type fed to west: ' .. type(cmd))
    return nil
  end
  VimRc.inf('Running west cmd: ' .. table.concat(full, ' '))
  local ret, out, err = M.run_cmd_sync(full)
  if ret ~= 0 then
    VimRc.err('Cmd return error: ' .. err)
    return nil
  end
  return out
end

return M
