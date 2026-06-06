local M = {
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

local check_obsidian_open = function()
  return vim.list_contains(vim.fn.systemlist [[hyprctl clients -j | jq -r '.[].class']], 'obsidian')
end
local prompt_for_open = function()
  if vim.g.obisdian_pid then
    return
  end
  vim.ui.select({ 'yes', 'no' }, {
    prompt = 'Obsidian UI must be open, run Obsidian command first to get the rest of the user commands?',
    format_item = function(item)
      return ('Open: %s'):format(item)
    end,
  }, function(ans)
    if ans == 'yes' then
      local ov = require 'overseer.task'
      if ov then
        local task = ov.new {
          cmd = 'obsidian',
        }
        task:start()
      else
        vim.g.obisdian_pid = vim.fn.jobstart('obsidian', {
          pty = true,
        })
      end
    end
  end)
end
---@param opts? {open_pty:boolean}
M.setup = function(opts)
  opts = opts or {}
  vim.api.nvim_create_user_command('Obsidian', function(data)
    if not check_obsidian_open() then
      prompt_for_open()
    end
    ObsidianCli.handle_command(data)
  end, {
    nargs = '*',
    desc = 'Obsidian CLI command',
    complete = function(arglead, cmdline, cursorpos)
      return vim.tbl_keys(M.cmds)
    end,
  })

  if opts.open_pty then
    prompt_for_open()
  end
end

---Run a  command asynchronously.
---@param subcmd string
---@param kwargs? table<string,string>
---@return string[]?
M.exec = function(subcmd, kwargs)
  vim.validate('subcmd', subcmd, 'string')
  vim.validate('kwargs', kwargs, 'table', true)
  kwargs = kwargs or {}
  local cmd = { 'obsidian', subcmd }
  for k, v in vim.spairs(kwargs) do
    cmd[#cmd + 1] = k .. '=' .. v
  end
  local sysobj = vim.system(cmd):wait()
  if sysobj.code ~= 0 then
    VimRc.err('Obsidian cmd failed with err: ', sysobj.stderr)
    return
  end
  local lines = vim.split(sysobj.stdout, '\n', { trimempty = true })
  if #lines == 0 then
    VimRc.warn('No output for command', { cmd = cmd })
  end
  return lines
end
--- Obsidian cmd
---@param args string[]
M.obsplit = function(args)
  vim.validate('args', args, vim.islist)
  -- local args = { 'term://obsidian', unpack(vim.split(subcmd, ' ', { trimempty = true })) }
  vim.api.nvim_cmd({ cmd = 'vsplit', args = { 'term://obsidian', unpack(args) } }, {})
end
---@return table<string,string>
M.get_vaults = function()
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
---Handle the :Obsidian user command.
---@param data vim.api.keyset.create_user_command.command_args
M.handle_command = function(data)
  local fargs = data.fargs
  if #fargs == 0 then
    return
  end

  local cmd = fargs[1]
  if not M.cmds[cmd] then
    VimRc.err('Unknown command: ' .. cmd)
    return
  end
  local valid_args = M.args[cmd]
  local remaining_args = vim.list_slice(fargs, 2)
  for _, tok in ipairs(remaining_args) do
    tok = tok:match '%w+?='
    if not vim.list_contains(valid_args, tok) then
      VimRc.err('Invalid argument ' .. tok .. ' for cmd ' .. cmd)
      return
    end
  end

  M.obsplit(fargs)
end
return M
