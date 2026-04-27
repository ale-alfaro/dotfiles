---@class obsidian.CLI
---@field cli {cmds:table,args:table,exepath:string}
---@field vaults string[]
---@field setup fun()
---@field handle_command fun(data:vim.api.keyset.create_user_command.command_args)
local M = {
  cli = {
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
  },
  vaults = {},
}

---Run a CLI command asynchronously.
---@param command string Full command string (e.g. "property:read")
---@param args string[] Remaining arguments
---@param callback fun(out: vim.SystemCompleted)
---@return vim.SystemObj
M.run = function(self, command, args, callback)
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
M.run_sync = function(self, command, args)
  local argv = { self.cli.exepath, command, unpack(args) }
  return vim.system(argv, {}):wait()
end

-- ---------------------------------------------------------------------------
-- Dispatch
-- ---------------------------------------------------------------------------

---Handle the :Obsidian user command.
---@param data vim.api.keyset.create_user_command.command_args
function M.handle_command(data)
  local fargs = data.fargs
  if #fargs == 0 then
    VimRc.info 'Usage: :Obsidian <command> [subcommand] [args...]'
    return
  end

  local cmd = fargs[1]
  if not M.cli.cmds[cmd] then
    VimRc.err('Unknown command: ' .. cmd)
    return
  end

  local cmd_name = cmd
  local arg_start = 2

  local subs = (type(M.cli.cmds[cmd]) == 'table') and M.cli.cmds[cmd] or nil
  if subs then
    if #fargs < 2 then
      VimRc.err("Command '" .. cmd .. "' requires a subcommand: " .. table.concat(subs, ', '))
      return
    end
    local sub = fargs[2]
    if not vim.tbl_contains(subs, sub) then
      VimRc.err("Invalid subcommand '" .. sub .. "' for '" .. cmd .. "'. Expected: " .. table.concat(subs, ', '))
      return
    end
    cmd_name = cmd .. ':' .. sub
    arg_start = 3
  end

  local remaining_args = vim.list_slice(fargs, arg_start)

  self.run(cmd_name, remaining_args, function(out)
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

-- ---------------------------------------------------------------------------
-- Setup
-- ---------------------------------------------------------------------------
--
local check_obsidian_open = function()
  return vim.list_contains(vim.fn.systemlist [[hyprctl clients -j | jq -r '.[].class']], 'obsidian')
end

local get_vaults = function()
  return vim.fn.systemlist [[obsidian vaults verbose | awk '{print $2}']]
end

function M.setup()
  if not check_obsidian_open() then
    VimRc.err 'Obsidian UI must be open!'
    return
  end
  M.vaults = get_vaults()
  M.cli.exepath = (vim.fn.executable(M.cli.exepath) == 1) and vim.fn.exepath(M.cli.exepath) or '/home/alealfaro/.local/bin/obsidian'
end

return M
