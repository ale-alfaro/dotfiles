local command = vim.api.nvim_create_user_command --[[@type function]]

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



command('CopyCwd', function()
  vim.cmd [[let @+=expand("%:p")]]
end, { desc = 'Copy Cwd Path' })

command('FindAndReplace', function(opts)
  vim.api.nvim_command(string.format('silent cdo s/%s/%s', opts.fargs[1], opts.fargs[2]))
  vim.api.nvim_command 'silent cfdo update'
end, { desc = 'Find and Replace (after quickfix)', nargs = '*' })

command('FindAndReplaceUndo', function(opts)
  vim.api.nvim_command 'silent cdo undo'
end, { desc = 'Undo Find and Replace' })


---@param desc string
---@return vim.api.keyset.user_command
local function pack_usercmd_opts(desc)
  return {
    desc = desc,
    nargs = 1,
    ---@type fun(args: vim.api.keyset.create_user_command.command_args)
    complete = function(ArgLead, CmdLine, CursorPos)
      return VimRc.get_plugins()
    end,
  }
end

command('PackOpen', function(opts)
  local ok, plug = pcall(vim.pack.get, { opts.fargs[1] })
  if ok then
    vim.cmd('edit ' .. plug[1].path)
  end
end, pack_usercmd_opts 'Open plugin repository in pack path')

command('PackList', function()
  VimRc.pack_list()
end, { desc = 'List plugins installed with vim.pack' })

command('PackReload', function(opts)
  local plug = { opts.fargs[1] }
  local ok, _ = pcall(vim.pack.get, plug)
  if ok then
    VimRc.pack_reload(plug)
  end
end, pack_usercmd_opts 'Reload plugin')

command('PackSync', function()
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
    VimRc.err 'Failed to delete plugins with vim.pack.del'
  end
  ok, _ = pcall(vim.pack.add, active_plugins_src)
  if not ok then
    VimRc.err 'Failed to add plugins with vim.pack.add'
  end
  vim.pack.update()
end, { desc = 'Sync plugins' })

command('PackDel', function(plugins)
  VimRc.pack_clean()
end, {
  desc = 'Clean unactive plugins',
  nargs = '*',
  complete = function(ArgLead, CmdLine, CursorPos)
    -- return completion candidates as a list-like table
    return VimRc.get_plugins()
  end,
})

command('PackUpdate', function()
  local plugins = VimRc.get_plugins {
    filter_fn = function(pspec)
      return pspec.active
    end,
  }
  if plugins then
    VimRc.info(string.format('Plugins count: %d', #plugins))
    VimRc.info(table.concat(plugins, '\n'))
    vim.pack.update(plugins)
  end
end, { desc = 'Update active plugins' })

vim.api.nvim_create_user_command('LspInfo', ':checkhealth vim.lsp', { desc = 'Alias to `:checkhealth vim.lsp`' })

vim.api.nvim_create_user_command('LspLog', function()
  local logfile = vim.lsp.log.get_filename()
  if vim.uv.fs_stat(logfile) then
    VimRc.exec.run_cmd { 'touch', vim.lsp.log.get_filename() }
  end

  vim.cmd(string.format('tabnew %s', logfile))
end, {
  desc = 'Opens the Nvim LSP client log.',
})

vim.api.nvim_create_user_command('LspLogClean', function()
  VimRc.exec.run_cmd { 'rm', vim.lsp.log.get_filename() }
  VimRc.exec.run_cmd { 'touch', vim.lsp.log.get_filename() }
end, {
  desc = 'Opens the Nvim LSP client log.',
})
