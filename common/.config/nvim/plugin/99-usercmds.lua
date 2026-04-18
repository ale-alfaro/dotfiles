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
---@param name string
---@param cb fun():nil
---@param desc string
local usercmd = function(name, cb, desc)
  vim.api.nvim_create_user_command(name, cb, { desc = desc })
end
---@param name string
---@param cb string|fun(args: vim.api.keyset.create_user_command.command_args) Replacement command to execute when this user command is executed. When called
---@param nargs integer
---@param desc string
local usercmd_args = function(name, cb, nargs, desc)
  vim.api.nvim_create_user_command(name, cb, { nargs = nargs, desc = desc })
end

---@param name string
---@param cb string|fun(args: vim.api.keyset.create_user_command.command_args) Replacement command to execute when this user command is executed. When called
---@param desc string
---@param nargs integer
---@param complete fun(ArgLead:string,CmdLine:string,CursorPos:integer)|fun()
--- ArgLead		the leading portion of the argument currently being
---			completed on; note that this only captures the current
---			space-separated word, even when using "-nargs=1"
---	CmdLine		the entire command line
---	CursorPos	the cursor position in it (byte index)
local function usercmd_args_comp(name, cb, desc, nargs, complete)
  vim.api.nvim_create_user_command(name, cb, {
    desc = desc,
    nargs = nargs,
    complete = complete,
  })
end
usercmd('CopyCwd', function()
  vim.cmd [[let @+=expand("%:p")]]
end, 'Copy Cwd Path')

vim.cmd [[
	set findfunc=Find
	func Find(arg, _)
	  if empty(s:filescache)
	    let s:filescache = globpath('.', '**', 1, 1)
	    call filter(s:filescache, '!isdirectory(v:val)')
	    call map(s:filescache, "fnamemodify(v:val, ':.')")
	  endif
	  return a:arg == '' ? s:filescache : matchfuzzy(s:filescache, a:arg)
	endfunc
	let s:filescache = []
	autocmd CmdlineEnter : let s:filescache = []

  	command! -nargs=+ -complete=customlist,<SID>Grep
		\ Grep call <SID>VisitFile()

	func s:Grep(arglead, cmdline, cursorpos)
	  if match(&grepprg, '\$\*') == -1 | let &grepprg ..= ' $*' | endif
	  let cmd = substitute(&grepprg, '\$\*', shellescape(escape(a:arglead, '\')), '')
	  return len(a:arglead) > 1 ? systemlist(cmd) : []
	endfunc

	func s:VisitFile()
	  let item = getqflist(#{lines: [s:selected]}).items[0]
	  let pos  = '[0,\ item.lnum,\ item.col,\ 0]'
	  exe $':b +call\ setpos(".",\ {pos}) {item.bufnr}'
	  call setbufvar(item.bufnr, '&buflisted', 1)
	endfunc

	autocmd CmdlineLeavePre :
	      \ if get(cmdcomplete_info(), 'matches', []) != [] |
	      \   let s:info = cmdcomplete_info() |
	      \   if getcmdline() =~ '^\s*fin\%[d]\s' && s:info.selected == -1 |
	      \     call setcmdline($'find {s:info.matches[0]}') |
	      \   endif |
	      \   if getcmdline() =~ '^\s*Grep\s' |
	      \     let s:selected = s:info.selected != -1
	      \         ? s:info.matches[s:info.selected] : s:info.matches[0] |
	      \     call setcmdline(s:info.cmdline_orig) |
	      \   endif |
	      \ endif
]]
---@param args string,
---@param cmdline string
---@param cursorpos integer
---@return string[]
local get_plugins = function(args, cmdline, cursorpos)
  return vim
    .iter(vim.pack.get())
    :map(function(p)
      return p.spec.name or p
    end)
    :totable()
end

-- ──────────────────────────────────────────────────────────────
--  Redir  — redirect :command / !shell output to scratch buffer
-- ──────────────────────────────────────────────────────────────
--
-- VimRc.create_comp_commands = function()
--   local opts = { bang = true, nargs = '+', complete = command_complete, desc = 'Execute Git command' }
--   vim.api.nvim_create_user_command('Git', H.command_impl, opts)
-- end
usercmd_args('Redir', function(opts)
  local cmd = opts.args
  local output
  if cmd:sub(1, 1) == '!' then
    output = vim.fn.system(cmd:sub(2))
  else
    output = vim.api.nvim_exec2(cmd, { output = true }).output
  end
  VimRc.show_in_split {
    'Cmd: ' .. cmd,
    '---------',
    unpack(vim.split(output or '', '\n')),
  }
end, 1, 'redirect command output to scratch buffer')

-- ──────────────────────────────────────────────────────────────
--  show_modified_buffers  — list unsaved buffers in quickfix
-- ──────────────────────────────────────────────────────────────

local function show_modified_buffers()
  local items = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_get_option_value('modified', { buf = buf }) then
      local name = vim.api.nvim_buf_get_name(buf)
      table.insert(items, {
        bufnr = buf,
        filename = name ~= '' and name or '[No Name]',
        lnum = 1,
        col = 0,
        text = name ~= '' and name or '[No Name]',
      })
    end
  end
  if #items > 0 then
    vim.fn.setqflist({}, ' ', { title = 'Modified Buffers', items = items })
    vim.cmd 'copen'
  else
    vim.notify('No modified buffers.', vim.log.levels.INFO)
  end
end

usercmd('UnmodBuf', show_modified_buffers, 'show unsaved buffers in quickfix')

usercmd_args_comp('PackOpen', function(opts)
  local ok, plug = pcall(vim.pack.get, { opts.fargs[1] })
  if ok then
    vim.cmd('edit ' .. plug[1].path)
  end
end, 'Open plugin repository in pack path', 1, get_plugins)

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
  local plugins = vim.pack.get()
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

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, 'vim.pack.list#' .. bufnr)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(table.concat(lines, '\n ------ \n'), '\n'))
  vim.cmd.sbuffer { bufnr, mods = { tab = vim.fn.tabpagenr() } }
end
usercmd('PackList', pack_list, 'List plugins installed with vim.pack')

usercmd_args_comp('PackClean', function(opts)
  vim
    .iter(vim.pack.get())
    :filter(function(x)
      return not x.active
    end)
    :map(function(x)
      return x.spec.name
    end)
    :totable()
end, 'Delete Unactive plugins', 1, get_plugins)

usercmd('PackUpdate', function()
  local plugins = vim
    .iter(vim.pack.get())
    :filter(function(pspec)
      return pspec.active
    end)
    :totable()
  if plugins then
    vim.cmd.echo(string.format('Plugins count: %d', #plugins))
    vim.cmd.echo(table.concat(plugins, '\n'))
    vim.pack.update(plugins)
  end
end, 'Update active plugins')

vim.api.nvim_create_user_command('Lsp', function(args)
  local cmd = args.args
  if cmd then
    if cmd == 'log' then
      local log = vim.lsp.log.get_filename()
      vim.api.nvim_cmd({
        cmd = 'edit',
        args = { log },
      }, {})
    elseif cmd == 'clean' then
      local log = vim.lsp.log.get_filename()
      vim.cmd(string.format('!rm %q', log))
      vim.cmd(string.format('!touch  %q', log))
    elseif cmd == 'info' then
      vim.cmd ':checkhealth vim.lsp'
    end
  end
end, {
  nargs = 1,
  desc = 'Lsp Commands',
  complete = function(ArgLead, CmdLine, CursorPos)
    -- return completion candidates as a list-like table
    return { 'log', 'clean', 'info' }
  end,
})
