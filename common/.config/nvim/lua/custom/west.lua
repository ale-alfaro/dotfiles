local M = {}
local H = {}

M.setup = function()
  if not H.is_west_workspace() then
    return
  end
  vim.api.nvim_create_user_command('West', function(opts)
    local args = opts.fargs or {}
    local west = 'mise exec pipx:west -- west'
    local params = vim.list_slice(args, 2) or ''
    if args[1] == 'Files' then
      require('fzf-lua').files {
        cmd = west .. ' forall -c "fd . --absolute-path"',
        multiprocess = 1, ---@type integer|boolean
        color_icons = true,
        git_icons = true,
        fzf_opts = { ['--multi'] = true, ['--scheme'] = 'path' },
        winopts = { preview = { winopts = { cursorline = false } } },
      }
    elseif args[1] == 'Grep' then
      require('fzf-lua').grep {
        cmd = west .. 'grep',
        multiprocess = 1, ---@type integer|boolean
        color_icons = true,
        git_icons = true,
        fzf_opts = { ['--multi'] = true, ['--scheme'] = 'path' },
        winopts = { preview = { winopts = { cursorline = false } } },
      }
    end
  end, {
    desc = 'West Workspace Search',
    nargs = 1,
    complete = function()
      return { 'Files', 'Grep' }
    end,
  })

  vim.api.nvim_create_user_command('Wg', function()
    require('fzf-lua').live_grep {
      cwd = H.exec('topdir')[1] or vim.fn.getcwd(),
    }
  end, { desc = 'Live Grep west workspace' })

  vim.api.nvim_create_user_command('WestGrep', function(ev)
    local proj = (ev.fargs or {})[1]
    if not proj then
      return
    end
    local projects = H.get_projects()
    local path = projects[proj]
    if not path then
      error('Project not found in workspace: ' .. path)
    end

    require('fzf-lua').live_grep { cwd = path }
  end, {
    desc = 'Grep West Project',
    nargs = 1,
    complete = function()
      return vim.tbl_keys(H.get_projects() or {})
    end,
  })
end

---
---@param subcmd string
---@param args? string[]
---@param kwargs? table<string,string|number|nil>
---@return string[]
H.exec = function(subcmd, args, kwargs)
  vim.validate('subcmd', subcmd, 'string')
  vim.validate('kwargs', args, 'table', true)
  vim.validate('kwargs', kwargs, 'table', true)
  args = args or {}
  kwargs = kwargs or {}
  local cmd = { 'mise', 'exec', 'pipx:west', '--', 'west', subcmd, unpack(args) }
  for k, v in vim.spairs(kwargs) do
    cmd[#cmd + 1] = k .. '=' .. v
  end
  local sysobj = vim.system(cmd):wait()
  if sysobj.code ~= 0 then
    VimRc.err('West cmd failed with err: ', sysobj.stderr)
    return
  end
  local lines = vim.split(sysobj.stdout, '\n', { trimempty = true })
  if #lines == 0 then
    VimRc.warn('No output for command', { cmd = cmd })
  end
  return lines
end

---@return boolean
H.is_west_workspace = function()
  local lines = H.exec 'topdir'
  if not lines or #lines < 1 or vim.uv.fs_stat(lines[#lines]) == nil then
    VimRc.warn 'Not in a workspace'
    return false
  end
  return true
end

H.get_projects = function()
  local projects = H.exec('list', { '-f', '"{name}:{posixpath}"' })
  if not projects then
    VimRc.warn 'No projects could be found'
    return
  end
  return vim
    .iter(projects)
    -- .iter(vim.fn.systemlist [[west list -f "{name}:{posixpath}" ]])
    :map(function(v)
      return vim.split(v, ':', { keepempty = false })
    end)
    :fold({}, function(acc, v)
      local n, p = v[1], v[2]
      acc[n] = p
      return acc
    end)
end

return M
