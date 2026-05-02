---@class obsidian.CLI
---@field cli {cmds:table,args:table,exepath:string}
---@field vaults table<string,string>
---@field setup fun()
---@field handle_command fun(data:vim.api.keyset.create_user_command.command_args)
local cli = {
  exepath = 'obsidian',
  cmds = {
    ['append'] = true,
    ['bookmark'] = true,
    ['bookmarks'] = true,
    ['daily'] = true,
    ['delete'] = true,
    ['diff'] = true,
    ['file'] = true,
    ['files'] = true,
    ['folder'] = true,
    ['folders'] = true,
    ['move'] = true,
    ['orphans'] = true,
    ['outline'] = true,
    ['prepend'] = true,
    ['properties'] = true,
    ['property'] = { 'read', 'remove', 'set' },
    ['read'] = true,
    ['rename'] = true,
    ['restart'] = true,
    ['search'] = true,
    ['task'] = true,
    ['tasks'] = true,
    ['template'] = { 'read', 'insert' },
    ['templater'] = { 'create-from-template' },
    ['templates'] = true,
    ['tag'] = true,
    ['tags'] = true,
    ['vault'] = true,
    ['vaults'] = true,
    ['web'] = true,
  },
  args = {
    append = { 'file=', 'path=', 'content=', 'inline' },
    bookmark = { 'file=', 'subpath=', 'folder=', 'search=', 'url=', 'title=' },
    bookmarks = { 'total', 'verbose', 'format=' },
    daily = { 'paneType=' },
    delete = { 'file=', 'path=', 'permanent' },
    diff = { 'file=', 'path=', 'from=', 'to=', 'filter=' },
    file = { 'file=', 'path=' },
    files = { 'folder=', 'ext=', 'total' },
    folder = { 'path=', 'info=' },
    folders = { 'folder=', 'total' },
    move = { 'file=', 'path=', 'to=' },
    orphans = { 'total', 'all' },
    outline = { 'file=', 'path=', 'format=', 'total' },
    prepend = { 'file=', 'path=', 'content=', 'inline' },
    properties = { 'file=', 'path=', 'name=', 'total', 'sort=', 'counts', 'format=', 'active' },
    ['property:read'] = { 'name=', 'file=', 'path=' },
    ['property:remove'] = { 'name=', 'file=', 'path=' },
    ['property:set'] = { 'name=', 'value=', 'type=', 'file=', 'path=' },
    read = { 'file=', 'path=' },
    rename = { 'file=', 'path=', 'name=' },
    restart = {},
    search = { 'query=', 'path=', 'limit=', 'total', 'case', 'format=' },
    task = { 'ref=', 'file=', 'path=', 'line=', 'toggle', 'done', 'todo', 'daily', 'status=' },
    tasks = { 'file=', 'path=', 'total', 'done', 'todo', 'status=', 'verbose', 'format=', 'active', 'daily' },
    ['template:read'] = { 'name=', 'resolve', 'title=' },
    ['template:insert'] = { 'name=' },
    ['templater:create-from-template'] = { 'template=', 'file=', 'open' },
    templates = { 'total' },
    tag = { 'name=', 'total', 'verbose' },
    tags = { 'file=', 'path=', 'total', 'counts', 'sort=', 'format=', 'active' },
    vault = { 'info=' },
    vaults = { 'total', 'verbose' },
    web = { 'url=', 'newtab' },
  },
}

---Run a CLI command asynchronously.
---@param command string Full command string (e.g. "property:read")
---@param args string[] Remaining arguments
---@param callback fun(out: vim.SystemCompleted)
---@return vim.SystemObj
local run = function(self, command, args, callback)
  local argv = { self.cli.exepath, command, unpack(args) }
  return vim.system(argv, {}, function(out)
    vim.schedule(function()
      callback(out)
    end)
  end)
end

---Run a CLI command synchronously.
---@param command string Full command string (e.g. "property:read")
---@param args string[] Remaining arguments
---@return vim.SystemCompleted
local run_sync = function(self, command, args)
  local argv = { self.cli.exepath, command, unpack(args) }
  return vim.system(argv, {}):wait()
end

-- ---------------------------------------------------------------------------
-- Dispatch
-- ---------------------------------------------------------------------------

---Handle the :Obsidian user command.
---@param data vim.api.keyset.create_user_command.command_args
local function handle_command(data)
  local fargs = data.fargs
  if #fargs == 0 then
    VimRc.info 'Usage: :Obsidian <command> [subcommand] [args...]'
    return
  end

  local cmd = fargs[1]
  if not cli.cmds[cmd] then
    VimRc.err('Unknown command: ' .. cmd)
    return
  end

  local cmd_name = cmd
  local arg_start = 2

  local subs = (type(cli.cmds[cmd]) == 'table') and cli.cmds[cmd] or {}
  if #fargs < 2 then
    return
  end
  local sub = fargs[2] or ''
  if not vim.tbl_contains(subs, sub) then
    return
  end
  cmd_name = cmd .. ':' .. sub
  arg_start = 3

  local remaining_args = vim.list_slice(fargs, arg_start)

  run_sync(cmd_name, remaining_args, function(out)
    if out.code ~= 0 then
      VimRc.err(out.stderr)
      return
    end

    local stdout = vim.trim(out.stdout or '')
    if stdout == '' then
      return
    end

    local lines = vim.split(stdout, '\n', { plain = true })
    if #lines <= 3 then
      VimRc.info(stdout)
    else
      VimRc.show_in_split(lines, 'obsidian://' .. cmd_name)
    end
  end)
end

---Return arg completions for a CLI command, filtering out already-typed args.
---@param cli_cmd string Full CLI command name (e.g. "files" or "property:read")
---@param typed_args string[] Arguments already on the command line
---@param arg_lead string Current partial text being completed
---@return string[]
local function obsidian_get_arg_completions(cli_cmd, typed_args, arg_lead)
  local available = cli.args[cli_cmd]
  if not available then
    return {}
  end

  local used = {}
  for _, arg in ipairs(typed_args) do
    local key = arg:match '^([%w_%-]+)'
    if key then
      used[key] = true
    end
  end

  return vim.tbl_filter(function(candidate)
    local key = candidate:match '^([%w_%-]+)'
    if not key or used[key] then
      return false
    end
    return vim.startswith(candidate, arg_lead)
  end, available)
end

---Completion function for the :Obsidian user command.
---@param arg_lead string
---@param cmdline string
---@param cursor_pos number
---@return string[]
local function obsidian_cmd_completions(arg_lead, cmdline, cursor_pos)
  local parts = vim.split(cmdline, ' ', { plain = true, trimempty = true })
  local trailing_space = cmdline:sub(-1) == ' '
  local nparts = #parts

  local cmd = parts[2]
  if not cli.cmds[cmd] then
    return {}
  end

  local subs = (type(cli.cmds[cmd]) == 'table') and cli.cmds[cmd] or nil

  -- Phase 2: subcommands for commands that have them
  if subs then
    if nparts == 2 and trailing_space then
      return subs
    end
    if nparts == 3 and not trailing_space then
      return vim.tbl_filter(function(s)
        return vim.startswith(s, parts[3])
      end, subs)
    end
    -- Subcommand is complete, offer arg completions
    if nparts >= 3 and vim.tbl_contains(subs, parts[3]) then
      local cli_cmd = cmd .. ':' .. parts[3]
      local typed_args = trailing_space and vim.list_slice(parts, 4) or vim.list_slice(parts, 4, nparts - 1)
      return obsidian_get_arg_completions(cli_cmd, typed_args or {}, arg_lead)
    end
    return {}
  end

  -- Phase 3: arg completions for simple commands
  local typed_args = trailing_space and vim.list_slice(parts, 3) or vim.list_slice(parts, 3, nparts - 1)
  return obsidian_get_arg_completions(cmd, typed_args or {}, arg_lead)
end
-- ---------------------------------------------------------------------------
-- Setup
-- ---------------------------------------------------------------------------
local M = {}
function M.setup()
  local check_obsidian_open = function()
    return vim.list_contains(vim.fn.systemlist [[hyprctl clients -j | jq -r '.[].class']], 'obsidian')
  end
  if not check_obsidian_open() then
    VimRc.err 'Obsidian UI must be open!'
    return
  end
  vim.api.nvim_create_user_command('Obsidian', function(data)
    handle_command(data)
  end, {
    nargs = '+',
    complete = obsidian_cmd_completions,
  })
  ---@return table<string,string>
  local get_vaults = function()
    return vim
      .iter(vim.fn.systemlist { 'obsidian', 'vaults', 'verbose' })
      :map(function(v)
        return vim.split(v, '\t')
      end)
      :fold({}, function(acc, v)
        local n, p = v[1], v[2]
        acc[n] = p
        return acc
      end)
  end

  local vaults = get_vaults()
  local function obs_vault_usercmd(name, cb, desc)
    vim.api.nvim_create_user_command(name, cb, {
      desc = desc,
      nargs = 1,
      complete = vim.tbl_keys(vaults),
    })
  end
  obs_vault_usercmd('ObsHealth', function(ev)
    local name = (ev.fargs or {})[1]
    local path = vaults[name]
    if not path then
      error('Vault not found in `obsidian vaults`: ' .. name, 2)
    end
    require('custom.obsidian.health').open(path)
  end, 'Obsidian Vault Health')
  obs_vault_usercmd('ObsFiles', function(ev)
    local arg = (ev.fargs or {})[1]
    vim.cmd('FzfLua files cwd_only=true cwd=' .. arg)
  end, 'Obsidian Files')

  obs_vault_usercmd('ObsGrep', function(ev)
    local arg = (ev.fargs or {})[1]
    local fzf = require 'fzf-lua'
    fzf.live_grep {
      cwd = arg,
      cwd_only = true,
      prompt = 'Live Grep',
    }
  end, 'Obsidian Grep')
end

return M
