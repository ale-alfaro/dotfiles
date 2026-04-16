--[[
--

Completion behavior ~
				*:command-completion* *E179* *E180* *E181*
				*:command-complete*
By default, the arguments of user defined commands do not undergo completion.
However, by specifying one or the other of the following attributes, argument
completion can be enabled:

	-complete=arglist	file names in argument list
	-complete=augroup	autocmd groups
	-complete=breakpoint	|:breakadd| suboptions
	-complete=buffer	buffer names
	-complete=color		color schemes
	-complete=command	Ex command (and arguments)
	-complete=compiler	compilers
	-complete=diff_buffer	diff buffer names
	-complete=dir		directory names
	-complete=dir_in_path	directory names in 'cdpath'
	-complete=environment	environment variable names
	-complete=event		autocommand events
	-complete=expression	Vim expression
	-complete=file		file and directory names
	-complete=file_in_path	file and directory names in 'path'
	-complete=filetype	filetype names 'filetype'
	-complete=function	function name
	-complete=help		help subjects
	-complete=highlight	highlight groups
	-complete=history	|:history| suboptions
	-complete=keymap	keyboard mappings
	-complete=locale	locale names (as output of locale -a)
	-complete=lua		Lua expression |:lua|
	-complete=mapclear	buffer argument
	-complete=mapping	mapping name
	-complete=menu		menus
	-complete=messages	|:messages| suboptions
	-complete=option	options
	-complete=packadd	optional package |pack-add| names
	-complete=retab		|:retab| suboptions
	-complete=runtime	file and directory names in 'runtimepath'
	-complete=scriptnames	sourced script names
	-complete=shellcmd	Shell command
	-complete=shellcmdline	First is a shell command and subsequent ones
				are filenames.  The same behavior as |:!cmd|
	-complete=sign		|:sign| suboptions
	-complete=syntax	syntax file names 'syntax'
	-complete=syntime	|:syntime| suboptions
	-complete=tag		tags
	-complete=tag_listfiles	tags, file names are shown when CTRL-D is hit
	-complete=user		user names
	-complete=var		user variables
	-complete=custom,{func} custom completion, defined via {func}
	-complete=customlist,{func} custom completion, defined via {func}
Lua functions are called with a single table argument containing arguments and
modifiers. The most important are:
• `name`: a string with the command name
• `fargs`: a table containing the command arguments split by whitespace (see |<f-args>|)
• `bang`: `true` if the command was executed with a `!` modifier (see |<bang>|)
• `line1`: the starting line number of the command range (see |<line1>|)
• `line2`: the final line number of the command range (see |<line2>|)
• `range`: the number of items in the command range: 0, 1, or 2 (see |<range>|)
• `count`: any count supplied (see |<count>|)
• `smods`: a table containing the command modifiers (see |<mods>|)

For example:
>lua
    vim.api.nvim_create_user_command('Upper',
      function(opts)
        print(string.upper(opts.fargs[1]))
      end,
      { nargs = 1 })

    vim.cmd.Upper('foo')
    --> FOO
<
The `complete` attribute can take a Lua function in addition to the
attributes listed in |:command-complete|. >lua

    vim.api.nvim_create_user_command('Upper',
      function(opts)
        print(string.upper(opts.fargs[1]))
      end,
      { nargs = 1,
        complete = function(ArgLead, CmdLine, CursorPos)
          -- return completion candidates as a list-like table
          return { "foo", "bar", "baz" }
        end,
    })
<
Buffer-local user commands are created with `vim.api.`|nvim_buf_create_user_command()|.
Here the first argument is the buffer number (`0` being the current buffer);
the remaining arguments are the same as for |nvim_create_user_command()|:
>lua
    vim.api.nvim_buf_create_user_command(0, 'Upper',
      function(opts)
        print(string.upper(opts.fargs[1]))
      end,
      { nargs = 1 })
--]]
local new_usercmd = function(name, cb, desc)
  vim.api.nvim_create_user_command(name, cb, { desc = desc })
end

new_usercmd('CopyCwd', function()
  vim.cmd [[let @+=expand("%:p")]]
end, 'Copy Cwd Path')

---@class FilterOpts
---@field names string[]?
---@field filter_fn fun(p:vim.pack.PlugData):boolean|nil
---@field output_names boolean?
---
---@param opts FilterOpts?
---@return string[]
local get_plugins = function(opts)
  vim.validate('opts', opts, 'table', true, 'FilterOpts')
  opts = vim.tbl_extend('force', { names = nil, filter_fn = nil, output_names = true }, opts or {})
  ---@type FilterOpts

  return vim
    .iter(vim.pack.get(opts.names))
    :map(function(p)
      local pname = opts.output_names and p.spec.name or p
      if type(opts.filter_fn) == 'callable' then
        return pname and opts.filter_fn(p) or nil
      end
      return pname
    end)
    :totable()
end

--- @param plugins string[] Optional: A single plugin name or a list of plugin names to update.
local pack_reload = function(plugins)
  local ok, _ = pcall(vim.pack.del, plugins)
  if not ok then
    vim.cmd.echo 'Failed to delete plugins with vim.pack.del'
    return
  end
  ok, _ = pcall(vim.pack.add, _G.plug_spec(plugins))
  if not ok then
    vim.cmd.echo 'Failed to add plugins with vim.pack.add'
  end
end
---@param desc string
local function vim_pack_usercmd(name, cb, desc)
  vim.api.nvim_create_user_command(name, cb, {
    desc = desc,
    nargs = 1,
    ---@type fun(args: vim.api.keyset.create_user_command.command_args)
    complete = function(args)
      return get_plugins()
    end,
  })
end

vim_pack_usercmd('PackOpen', function(opts)
  local ok, plug = pcall(vim.pack.get, { opts.fargs[1] })
  if ok then
    vim.cmd('edit ' .. plug[1].path)
  end
end, 'Open plugin repository in pack path')

--- @param p vim.pack.PlugData
--- @return string
local function write_plug_info(p)
  local active_suffix = p.active and '' or ' (not active)'

  local parts = { ('## %s%s\n'):format(p.spec.name, active_suffix) }
  local version_suffix = p.spec.version == '' and '' or (' (%s)'):format(p.spec.version)

  parts[#parts + 1] = table.concat({
    'Path:     ' .. p.path,
    'Source:   ' .. p.spec.src,
    'Revision: ' .. p.rev .. version_suffix,
  }, '\n')

  return table.concat(parts, '')
end
local function pack_list()
  ---@type vim.pack.PlugData[]
  local plugins = M.get_plugins { output_names = false }
  ---@type string[]
  local active = vim
    .iter(plugins)
    :filter(function(p)
      return p.active
    end)
    :map(function(plug)
      return write_plug_info(plug)
    end)
    :totable()
  active = vim.list_extend({ 'Active Plugins List:' }, active)
  local inactive = vim
    .iter(plugins)
    :filter(function(p)
      return not p.active
    end)
    :map(function(plug)
      return write_plug_info(plug)
    end)
    :totable()
  local lines = vim.list_extend(active, vim.list_extend({ 'INACTIVE Plugins List:' }, inactive))

  local bufnr = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_name(bufnr, 'vim.pack.list#' .. bufnr)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(table.concat(lines, '\n ------ \n'), '\n'))
  vim.cmd.sbuffer { bufnr, mods = { tab = vim.fn.tabpagenr() } }
end
new_usercmd('PackList', pack_list, 'List plugins installed with vim.pack')

local function pack_clean()
  local active_plugins = {}
  local unused_plugins = {}

  for _, plugin in ipairs(vim.pack.get()) do
    active_plugins[plugin.spec.name] = plugin.active
  end

  for _, plugin in ipairs(vim.pack.get()) do
    if not active_plugins[plugin.spec.name] then
      table.insert(unused_plugins, plugin.spec.name)
    end
  end

  if #unused_plugins == 0 then
    print 'No unused plugins.'
    return
  end

  local choice = vim.fn.confirm('Remove unused plugins?', '&Yes\n&No', 2)
  if choice == 1 then
    vim.pack.del(unused_plugins)
  end
end
vim_pack_usercmd('PackDel', pack_clean, 'Clean unactive plugins')
vim_pack_usercmd('PackReload', function(opts)
  local plug = { opts.fargs[1] }
  local ok, _ = pcall(vim.pack.get, plug)
  if ok then
    pack_reload(plug)
  end
end, 'Reload plugin')

new_usercmd('PackSync', function()
  --- @type string[]
  local plugins_name = {}
  --- @type string[]
  local active_plugins_src = {}
  for _, plugin in ipairs(vim.pack.get()) do
    plugins_name[#plugins_name + 1] = plugin.spec.name
    if plugin.active then
      active_plugins_src[#active_plugins_src + 1] = plugin.spec.src
    end
  end
  local ok, _ = pcall(vim.pack.del, plugins_name)
  if not ok then
    vim.cmd.echo 'Failed to delete plugins with vim.pack.del'
    return
  end
  ok, _ = pcall(vim.pack.add, active_plugins_src)
  if not ok then
    vim.cmd.echo 'Failed to add plugins with vim.pack.add'
  end
  vim.pack.update()
end, 'Sync plugins')

new_usercmd('PackUpdate', function()
  local plugins = get_plugins {
    filter_fn = function(pspec)
      return pspec.active
    end,
  }
  if plugins then
    vim.cmd.echo(string.format('Plugins count: %d', #plugins))
    vim.cmd.echo(table.concat(plugins, '\n'))
    vim.pack.update(plugins)
  end
end, 'Update active plugins')

new_usercmd('LspInfo', ':checkhealth vim.lsp', { desc = 'Alias to `:checkhealth vim.lsp`' })

new_usercmd('LspLog', function()
  local logfile = vim.lsp.log.get_filename()
  if vim.uv.fs_stat(logfile) then
    vim.cmd.edit(vim.lsp.log.get_filename())
  end

  vim.cmd(string.format('tabnew %s', logfile))
end, 'Opens the Nvim LSP client log.')

new_usercmd('LspLogClean', function()
  local log = vim.lsp.log.get_filename()
  vim.cmd(string.format('!rm %q', log))
  vim.cmd(string.format('!touch  %q', log))
end, 'Opens the Nvim LSP client log.')
