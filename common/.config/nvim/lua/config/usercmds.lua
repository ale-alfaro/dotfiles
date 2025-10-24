local command = vim.api.nvim_create_user_command --[[@type function]]

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
command('PackOpen', function(opts)
  local ok, plug = pcall(vim.pack.get, { opts.fargs[1] })
  if ok then
    vim.cmd('edit ' .. plug[1].path)
  end
end, { desc = 'Open plugin repository in pack path', nargs = 1 })

command('PackList', function()
  VimRc.pack_list()
end, { desc = 'List plugins installed with vim.pack' })
command('PackReload', function(opts)
  local plug = { opts.fargs[1] }
  local ok, _ = pcall(vim.pack.get, plug)
  if ok then
    VimRc.pack_reload(plug)
  end
end, { desc = 'Open plugin repository in pack path', nargs = 1 })
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
