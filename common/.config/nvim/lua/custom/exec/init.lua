local M = {}
local PRIV = {}

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

local cli_notify = function(msg, level)
  vim.schedule(function()
    vim.notify('[exec] ' .. msg, vim.log.levels[level] or vim.log.levels.INFO)
  end)
end
---@param executable string
---@param on_done? fun(ret:integer, stdout:string, stderr:string)
---@param opts? {cwd?:string,envs?:table<string,string>,timeout:number,stdin:string}
---@return table<integer, string, string>|nil
M.cli_run = function(executable, on_done, opts)
  vim.validate('executable', executable, 'string')
  vim.validate('on_done', on_done, 'function', true)
  vim.validate('opts', opts, 'table', true)

  opts = opts or {}
  local timeout = opts.timeout or 100
  local stdin_pipe = opts.stdin and vim.loop.new_pipe() or nil
  local stdout, stderr = vim.loop.new_pipe(), vim.loop.new_pipe()
  local process = nil

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
    local str_out = PRIV.cli_stream_tostring(out)
    local str_err = PRIV.cli_stream_tostring(err):gsub('\r+', '\n'):gsub('\n%s+\n', '\n\n')
    on_done(code, str_out, str_err)
  end
  ---@type uv.spawn.options
  local spawn_opts = { args = opts.args, cwd = opts.cwd or vim.fn.getcwd(), stdio = { stdin_pipe, stdout, stderr }, env = opts.envs }
  ---@type uv.uv_process_t?
  process = vim.loop.spawn(executable, spawn_opts, on_exit)
  if stdin_pipe then
    stdin_pipe:write(opts.stdin)
    stdin_pipe:shutdown(function()
      stdin_pipe:close()
    end)
  end
  PRIV.cli_read_stream(assert(stdout), out)
  PRIV.cli_read_stream(assert(stderr), err)
  vim.defer_fn(function()
    if not process or not process:is_active() then
      return
    end
    cli_notify('PROCESS REACHED TIMEOUT', 'WARN')
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
PRIV.cli_read_stream = function(stream, feed)
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

---@param stream string[]
---@return string
PRIV.cli_stream_tostring = function(stream)
  return (table.concat(stream):gsub('\n+$', ''))
end

PRIV.cli_err_notify = function(code, out, err)
  local should_stop = code ~= 0
  if should_stop then
    cli_notify(err .. (out == '' and '' or ('\n' .. out)), 'ERROR')
  end
  if not should_stop and err ~= '' then
    cli_notify(err, 'WARN')
  end
  return should_stop
end

---@param x string
---@return string
PRIV.cli_escape = function(x)
  return (string.gsub(x, '([ \\])', '\\%1'))
end

-- Command --------------------------------------------------------------------
local executables_cache = {}
---Run a system command.
---@param cmd string command arguments
---@param args? string[] command arguments
---@return table<integer, string, string>
function M.run_cmd_sync(cmd, args)
  vim.validate('cmd', cmd, 'string')
  vim.validate('args', args, vim.islist, true)
  local executable = cmd[1]
  executables_cache[executable] = executables_cache[executable] or vim.fn.executable(executable) == 1
  if not executables_cache[executable] then
    error(string.format('`%s` is not executable (not found on `$PATH`)', executable))
  end

  return assert(M.cli_run(executable, nil, { args = args }))
end
return M
