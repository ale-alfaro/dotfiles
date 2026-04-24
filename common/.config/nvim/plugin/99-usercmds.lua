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
---@param nargs integer|string
---@param complete (fun(ArgLead:string,CmdLine:string,CursorPos:integer):string[])|string[]
--- ArgLead		the leading portion of the argument currently being
---			completed on; note that this only captures the current
---			space-separated word, even when using "-nargs=1"
---	CmdLine		the entire command line
---	CursorPos	the cursor position in it (byte index)
local function usercmd_args_comp(name, cb, desc, nargs, complete)
  vim.api.nvim_create_user_command(name, cb, {
    desc = desc,
    nargs = nargs,
    complete = (vim.islist(complete)) and function(args, cmdline, cursorpos)
      return complete
    end or complete,
  })
end
usercmd_args_comp('CopyBufPath', function(ev)
  local arg = (ev.fargs or { 'abs' })[1]
  local path
  if arg == 'dir' then
    path = vim.fn.expand '%:p:h'
  elseif arg == 'abs' then
    path = vim.fn.expand '%:p'
  elseif arg == 'rel' then
    path = vim.fn.expand '%'
  end
  if path then
    vim.fn.setreg('+', path)
    vim.print('Copied ' .. path)
  end
end, 'Copy Cwd Path', 1, { 'rel', 'abs', 'dir' })

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

-- ──────────────────────────────────────────────────────────────
--  Vim.pack cmd
-- ──────────────────────────────────────────────────────────────
local get_plugins = function(args, cmdline, cursorpos)
  return vim
    .iter(vim.pack.get())
    :map(function(p)
      return p.spec.name or p
    end)
    :totable()
end
usercmd_args_comp('PackOpen', function(opts)
  local ok, plug = pcall(vim.pack.get, { opts.fargs[1] })
  if ok then
    vim.cmd.edit(plug[1].path)
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

usercmd_args_comp('Pack', function(args)
  local arg = (args.fargs or {})[1]
  local plugins = vim.pack.get()
  local active = vim
    .iter()
    :filter(function(pspec)
      return pspec.active
    end)
    :totable()

  local inactive = vim
    .iter(plugins)
    :filter(function(p)
      return not p.active
    end)
    :totable()

  if arg == 'clean' then
    vim.pack.del(inactive)
  elseif string.find(arg, '^up') then
    vim.cmd.echo(string.format('Plugins count: %d', #active))
    vim.cmd.echo(table.concat(active, '\n'))
    vim.pack.update(active)
  elseif arg == 'ls' or arg == 'list' then
    local lines = {
      'Active Plugins List:',
      unpack(vim.iter(active):map(write_plug_info):totable()),
      'INACTIVE Plugins List:',
      unpack(vim.iter(inactive):map(write_plug_info):totable()),
    }

    VimRc.show_in_split(lines)
  else
    VimRc.err('Unknown Pack arg: ' .. arg)
  end
end, 'vim.pack Interface', 1, { 'list', 'update', 'clean' })

usercmd_args_comp('Lsp', function(args)
  local arg = (args.fargs or {})[1]
  if arg == 'log' then
    local log = vim.lsp.log.get_filename()
    vim.api.nvim_cmd({
      cmd = 'edit',
      args = { log },
    }, {})
  elseif arg == 'clean' then
    local log = vim.lsp.log.get_filename()
    vim.cmd(string.format('!rm %q', log))
    vim.cmd(string.format('!touch  %q', log))
  elseif arg == 'info' then
    vim.cmd ':checkhealth vim.lsp'
  end
end, 'Lsp Commands', 1, { 'log', 'clean', 'info' })

local list_files_from_branch_action = function(action, selected, o, args)
  local file = require('fzf-lua').path.entry_to_file(selected[1], o)
  local cmd = string.format('%s %s:%s', action, args, file.path)
  vim.cmd(cmd)
end

local get_vaults = function()
  return vim.fn.systemlist [[obsidian vaults verbose | awk '{print $2}']]
end
usercmd_args_comp('ObsFiles', function(ev)
  local arg = (ev.fargs or {})[1]
  vim.cmd('FzfLua files cwd_only=true cwd=' .. arg)
end, 'Obsidian Files', 1, get_vaults)

usercmd_args_comp('ObsGrep', function(ev)
  local arg = (ev.fargs or {})[1]
  local fzf = require 'fzf-lua'
  fzf.live_grep {
    cwd = arg,
    cwd_only = true,
    prompt = 'Live Grep',
  }
end, 'Obsidian Grep', 1, get_vaults)
usercmd_args_comp(
  'GitFiles',
  function(opts)
    require('fzf-lua').fzf_exec('git ls-tree -r --name-only ' .. opts.args, {
      prompt = opts.args .. ' >',
      actions = {
        ['default'] = function(selected, o)
          list_files_from_branch_action('Git', selected, o, opts.args)
        end,
      },
      previewer = false,
      preview = {
        type = 'cmd',
        fn = function(items)
          local file = require('fzf-lua').path.entry_to_file(items[1])
          return string.format('git show %s:%s | delta', opts.args, file.path)
        end,
      },
    })
  end,
  'List all git files from a branch',
  1,
  function()
    local branches = vim.fn.systemlist "git branch --sort=-committerdate --format='%(refname:short)'"
    if vim.v.shell_error == 0 then
      return vim.tbl_map(function(x)
        return x:match('[^%s%*]+'):gsub('^remotes/', '')
      end, branches)
    end
    return {}
  end
)

-- ---------------------------------------------------------------------------
-- Obsidian
-- ---------------------------------------------------------------------------

local obsidian = require 'custom.obsidian'
---Return arg completions for a CLI command, filtering out already-typed args.
---@param cli_cmd string Full CLI command name (e.g. "files" or "property:read")
---@param typed_args string[] Arguments already on the command line
---@param arg_lead string Current partial text being completed
---@return string[]
local function obsidian_get_arg_completions(cli_cmd, typed_args, arg_lead)
  local available = obsidian.cli.args[cli_cmd]
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
local function obsidian_get_completions(arg_lead, cmdline, cursor_pos)
  local parts = vim.split(cmdline, ' ', { plain = true, trimempty = true })
  local trailing_space = cmdline:sub(-1) == ' '
  local nparts = #parts

  local cmd = parts[2]
  if not obsidian.cli.cmds[cmd] then
    return {}
  end

  local subs = (type(obsidian.cli.cmds[cmd]) == 'table') and obsidian.cli.cmds[cmd] or nil

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

vim.api.nvim_create_user_command('Obsidian', function(data)
  obsidian.setup()
  obsidian.handle_command(data)
end, {
  nargs = '+',
  complete = obsidian_get_completions,
})
