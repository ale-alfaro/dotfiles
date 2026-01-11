local M = {}

function M.tbl_find(tbl, predicate)
  for idx, value in ipairs(tbl) do
    if predicate(value) then
      return value, idx
    end
  end

  return nil
end

Direction = {
  left = 'left',
  right = 'right',
  up = 'up',
  down = 'down',
}
local dir_keys_wezterm_splits = {
  [Direction.left] = '--left',
  [Direction.right] = '--right',
  [Direction.up] = '--top',
  [Direction.down] = '--bottom',
}
local wezterm_cli_path = 'wezterm'
---Check if a window is a floating window
---@param win_id number|nil window ID to check, defaults to current window (0)
---@return boolean
function M.is_floating_window(win_id)
  win_id = win_id or 0
  local win_cfg = vim.api.nvim_win_get_config(win_id)
  return win_cfg and (win_cfg.relative ~= '' or not win_cfg.relative)
end

local executables_cache = {}
--- Runs a system command or throws an error if {cmd} cannot be run.
---
--- The command runs directly (not in 'shell') so shell builtins such as "echo" in cmd.exe, cmdlets
--- in powershell, or "help" in bash, will not work unless you actually invoke a shell:
--- `vim.system({'bash', '-c', 'help'})`.
---
--- Examples:
---
--- ```lua
--- local on_exit = function(obj)
---   print(obj.code)
---   print(obj.signal)
---   print(obj.stdout)
---   print(obj.stderr)
--- end
---
--- -- Runs asynchronously:
--- vim.system({'echo', 'hello'}, { text = true }, on_exit)
---
--- -- Runs synchronously:
--- local obj = vim.system({'echo', 'hello'}, { text = true }):wait()
--- -- { code = 0, signal = 0, stdout = 'hello\n', stderr = '' }
---
--- ```
---
--- See |uv.spawn()| for more details. Note: unlike |uv.spawn()|, vim.system
--- throws an error if {cmd} cannot be run.
---
---@param cmd string[]
---@param stdout_cb fun( data: string?, lines: string[])
---@param sync boolean
---@param cwd? string
function M.run_command_with_output(cmd, stdout_cb, sync, cwd)
  if cwd == nil then
    cwd = M.get_project_root()
  end

  local on_exit = function(obj)
    if obj.code == 0 and obj.stdout then
      _G.info 'Command completed successfully'
      local data = obj.stdout
      if data and data:match '%S' then
        local line_output = vim.split(data, '\n') or {}
        _G.info('comand output: ' .. data)
        if stdout_cb then
          stdout_cb(data, line_output)
        end
      else
        _G.error 'Command failed'
      end
    end
  end
  if sync then
    ---@type vim.SystemOpts
    local opts = {
      cwd = cwd,
      text = true,
    }
    local obj = vim.system(cmd, opts):wait()
    on_exit(obj)
  else
    --- @type fun(out: vim.SystemCompleted)
    -- Run command in background and capture output
    vim.system(cmd, on_exit)
  end
end
---Run a system command.
---@param cmd string[] command arguments
---@return string output, number exit_code the stderr/stdout and the exit code
function M.run_cmd(cmd)
  if #cmd == 0 then
    error 'No command provided'
  end

  executables_cache[cmd[1]] = executables_cache[cmd[1]] or vim.fn.executable(cmd[1]) == 1
  if not executables_cache[cmd[1]] then
    error(string.format('`%s` is not executable (not found on `$PATH`)', cmd[1]))
  end

  local result = vim.system(cmd, { text = true }):wait()
  return result.code == 0 and (result.stdout or '') or (result.stderr or ''), result.code
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
    _G.error('Invalid type fed to west: ' .. type(cmd))
    return nil
  end
  vim.print('Running west cmd: ' .. table.concat(full, ' '))
  local out, ret = M.run_cmd(full)
  if ret ~= 0 then
    _G.error('Non-zero ret code: ' .. tostring(ret))
    return nil
  end
  return out
end

---@param bufnr number?
---@return string|nil output
function M.west_topdir(bufnr)
  local rootdir = vim.fs.root(bufnr or 0, { '.west', 'zephyr' })
  local topdir = M.west 'topdir' or rootdir
  if not topdir or not vim.uv.fs_stat(topdir) then
    _G.error 'No west topdir found'
    return nil
  end
  return topdir
end
---@param config string
---@param set_val string?
---@return string|nil output the stderr/stdout and the exit code
function M.west_config(config, set_val)
  local cmd = { 'config', config }
  if set_val ~= nil then
    _G.info('west config set ' .. config .. ' to ' .. set_val)
    cmd = table.insert(cmd, set_val)
    return M.west(cmd)
  else
    _G.info('west config get ' .. config)
    return M.west(cmd)
  end
end

---@param cmd string[]
---@return string output, number exit_code the stderr/stdout and the exit code
local function wezterm_exec(cmd)
  return M.run_cmd { 'wezterm', 'cli', table.unpack(cmd) }
end

---@class wezterm_spanw_args
---@field cwd string
---@field percentage number
---@field program string

local function wezterm_split_pane(direction, cwd, size, program_args)
  local args = { 'split-pane', dir_keys_wezterm_splits[direction], '--cwd', cwd }
  if size then
    table.insert(args, '--percent')
    table.insert(args, size)
  end
  if program_args and type(program_args) == 'table' and #program_args > 0 then
    table.insert(args, '--')
    vim.list_extend(args, program_args)
  end
  local ok, _ = pcall(wezterm_exec, args)
  return ok
end

function M.wezterm_spawn_terminal()
  local bufname = vim.api.nvim_buf_get_name(0)
  local cwd
  if bufname == '' or bufname == nil then
    cwd = vim.fn.getcwd()
  else
    cwd = vim.fn.expand '%:p:h'
  end
  local ok = wezterm_split_pane(Direction.down, cwd, 30)
  return ok
end

function M.wezterm_spawn_nvim_inst(direction, file)
  local cwd = vim.fn.fnamemodify(file, ':h')
  local program_args = { 'nvim', file }
  local ok = wezterm_split_pane(direction, cwd, nil, program_args)
  return ok
end

return M
