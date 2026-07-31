--[[
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
  vim.api.nvim_create_user_command(name, cb, { desc = desc, nargs = 0 })
end
usercmd('ToggleFormat', function()
  vim.g.autoformat = not vim.g.autoformat
  vim.notify(string.format('%s formatting...', vim.g.autoformat and 'Enabling' or 'Disabling'), vim.log.levels.INFO)
end, 'Toggle conform.nvim auto-formatting')

usercmd('ToggleInlayHints', function()
  vim.g.inlay_hints = not vim.g.inlay_hints
  vim.notify(string.format('%s inlay hints...', vim.g.inlay_hints and 'Enabling' or 'Disabling'), vim.log.levels.INFO)

  local mode = vim.api.nvim_get_mode().mode
  vim.lsp.inlay_hint.enable(vim.g.inlay_hints and (mode == 'n' or mode == 'v'))
end, 'Toggle inlay hints')

usercmd('BufInfo', function()
  local bufnr = vim.api.nvim_get_current_buf()
  for _, name in ipairs {
    'filetype',
    'buftype',
    'bufhidden',
    'buflisted',
    'swapfile',
    'modifiable',
  } do
    MiniMisc.put('Option: ', { name = name, val = vim.api.nvim_get_option_value(name, { scope = 'local', buf = bufnr }) })
  end
end, 'Print current buffer Ft')
usercmd('Scratch', VimRc.scratch_split, 'Open a scratch buffer')

---@param name string
---@param cb string|fun(args: vim.api.keyset.create_user_command.command_args) Replacement command to execute when this user command is executed. When called
---@param desc string
---@param nargs integer|string
local usercmd_args = function(name, cb, desc, nargs)
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
usercmd_args('Sh', function(opts)
  local cmd = opts.args
  local output = vim.fn.system(cmd)
  VimRc.show_in_split {
    'Cmd: ' .. cmd,
    '---------',
    unpack(vim.split(output or '', '\n')),
  }
end, 'redirect Shell output to scratch buffer', '+')
usercmd_args('Cmd', function(opts)
  local cmd = opts.args
  local output = vim.api.nvim_exec2(cmd, { output = true }).output
  VimRc.show_in_split {
    'Cmd: ' .. cmd,
    '---------',
    unpack(vim.split(output or '', '\n')),
  }
end, 'redirect Neovim command output to scratch buffer', '+')

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
    .iter(plugins)
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

  if arg == 'open' then
    vim.ui.select(vim.pack.get(), {
      prompt = 'Plugin:',
      format_item = function(item)
        return item.path
      end,
      preview_item = function(item)
        local lines = { 'This is ' .. vim.inspect(item) }
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.bo[buf].bufhidden = 'wipe'
        return { buf = buf }
      end,
    }, function(sel)
      vim.cmd.edit(sel)
    end)
  elseif arg == 'clean' then
    vim.pack.del(inactive)
  elseif string.find(arg, '^up') then
    vim.pack.update()
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
end, 'vim.pack Interface', 1, { 'open', 'list', 'update', 'clean' })

usercmd('SwapDel', function()
  vim.cmd [[!rm $XDG_STATE_HOME/nvim/swap/*.swp ]]
  VimRc.info 'Deleted swap dir'
end, 'Delete current buffer swapfile')
usercmd_args_comp('Lsp', function(args)
  local arg = (args.fargs or {})[1]
  if arg == 'actions' then
    require('tiny-code-action').code_action {
      filter = function(action, client)
        local client_name = client.name
        local kind = action.kind
        local title = action.title
        VimRc.info(string.format('Client: %q, Kind: %q, CodeAction: %q', client_name, kind, title))
      end,
    }
  elseif arg == 'log' then
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
end, 'Lsp Commands', 1, { 'actions', 'log', 'clean', 'info' })

usercmd('RstToMd', function()
  local steps = {
    [[%s/\v(.+)\n\*+$/## \1/]], -- text + *** underline  -> ## heading
    [[%s/\v(.+)\n\=+$/### \1/]], -- text + === underline  -> ### heading
    [[%s/\v:\w+:\w+://g]], -- strip :role:word: inline markup
    [[%s/\v^\.\.\s+(\w.*)/<!-- \1 -->/g]], -- .. directive/comment  -> HTML comment
  }
  for _, cmd in ipairs(steps) do
    pcall(vim.cmd, cmd) -- a "Pattern not found" (E486) won't abort the rest
  end
end, 'Convert Current Buffer from ReStructured Text to Markdown')
usercmd('LazyGitEdit', function()
  vim.g.autoformat = false
  if MiniDiff then
    MiniDiff.toggle_overlay(0)
  end
end, 'Edit cmd for LazyGit')
