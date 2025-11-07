local command = vim.api.nvim_create_user_command --[[@type function]]

--[[
--

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

local function ToggleLineNumbers()
  if vim.wo.relativenumber then
    vim.wo.relativenumber = false
  else
    vim.wo.relativenumber = true
  end
end
command('LineNumbers', function()
  ToggleLineNumbers()
end, { desc = 'Toggle line numbers' })

command('ToggleAutoformat', function()
  VimRc.format.toggle()
end, { desc = 'Toggle Autoformat (Global)' })

command('ToggleBufAutoformat', function()
  VimRc.format.toggle(vim.api.nvim_buf_get_current_buf())
end, { desc = 'Toggle Autoformat (Buffer)' })
-- command('ChangeFiletype', function()
--   om.ChangeFiletype()
-- end, { desc = 'Change filetype of current buffer' })

command('CopyMessage', function()
  vim.cmd [[let @+ = execute('messages')]]
end, { desc = 'Copy message output' })

command('FindAndReplace', function(opts)
  vim.api.nvim_command(string.format('silent cdo s/%s/%s', opts.fargs[1], opts.fargs[2]))
  vim.api.nvim_command 'silent cfdo update'
end, { desc = 'Find and Replace (after quickfix)', nargs = '*' })

command('FindAndReplaceUndo', function(opts)
  vim.api.nvim_command 'silent cdo undo'
end, { desc = 'Undo Find and Replace' })

-- command("GitBranchList", function()
--   om.ListBranches()
-- end, { desc = "List the Git branches in this repo" })
--
-- command("GitRemoteSync", function()
--   om.GitRemoteSync()
-- end, { desc = "Git sync remote repo" })

command('New', ':enew', { desc = 'New buffer' })


---@param desc string
---@return vim.api.keyset.user_command
local function pack_usercmd_opts(desc)
  return {
    desc = desc,
    nargs = 1,
    complete = function(ArgLead, CmdLine, CursorPos)
      -- return completion candidates as a list-like table
      return VimRc.get_packpath_dirs()
    end,
  }
end

command('PackOpen', function(opts)
  local ok, plug = pcall(vim.pack.get, { opts.fargs[1] })
  if ok then
    vim.cmd('edit ' .. plug[1].path)
  end
end, pack_usercmd_opts('Open plugin repository in pack path'))

command('PackList', function()
  VimRc.pack_list()
end, { desc = 'List plugins installed with vim.pack' })

command('PackReload', function(opts)
  local plug = { opts.fargs[1] }
  local ok, _ = pcall(vim.pack.get, plug)
  if ok then
    VimRc.pack_reload(plug)
  end
end, pack_usercmd_opts('Reload plugin'))

command('PackSync', function()
  local plugins = {}
  for _, plugin in ipairs(VimRc.added_plugins) do
    if type(plugin) == 'string' then
      plugins[plugin] = true
    elseif type(plugin) == 'table' and plugin.src then
      plugins[plugin.src] = true
    end
  end

  local to_delete = {}
  for _, plugin in ipairs(vim.pack.get()) do
    local src = plugin.spec and plugin.spec.src
    if src and not plugins[src] then
      table.insert(to_delete, plugin.spec.name)
    end
  end

  local ok, _ = pcall(vim.pack.del, to_delete)
  if not ok then
    _G.error 'Failed to delete plugins with vim.pack.del'
  end
  ok, _ = pcall(vim.pack.add, VimRc.added_plugins)
  if not ok then
    _G.error 'Failed to add plugins with vim.pack.add'
  end
  vim.pack.update()
end, { desc = 'Sync plugins' })

command('PackClean', function()
  VimRc.pack_clean()
end, { desc = 'Clean unactive plugins' })

command('PackUpdate', function()
  VimRc.pack_update()
end, { desc = 'Update active plugins' })
