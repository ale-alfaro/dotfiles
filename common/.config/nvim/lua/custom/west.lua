local M = {}
local H = {}

M.west = 'mise exec vfox-zephyr:west -- west'
M.setup = function()
  M.topdir = M.topdir or H.west_workspace()
  if not M.topdir then
    return
  end
  vim.api.nvim_create_user_command('WestFiles', function(opts)
    local args = opts.fargs or {}
    local pattern = args[1]
    local vargs = vim.fn.join(vim.list_slice(args, 2) or {}, ' ')

    local fdq = string.format([[fd %q %s --format  "\${WEST_PROJECT_PATH}/{}"]], pattern, vargs)
    FzfLua.fzf_exec(M.west .. '-q forall -c  ' .. fdq, { cwd = H.exec 'topdir' })
  end, {
    desc = 'West Files Search',
    nargs = '+',
  })
  vim.api.nvim_create_user_command('WestGrep', function(opts)
    local args = opts.fargs or {}
    require('fzf-lua').exec {
      cmd = M.west .. ' grep ' .. vim.fn.join(args, ' '),
      multiprocess = 1, ---@type integer|boolean
      color_icons = true,
      git_icons = true,
      fzf_opts = { ['--multi'] = true, ['--scheme'] = 'path' },
      winopts = { preview = { winopts = { cursorline = false } } },
    }
  end, {
    desc = 'West Grep Search',
    nargs = '+',
  })

  vim.api.nvim_create_user_command('Wg', function()
    require('fzf-lua').live_grep {
      cwd = H.exec 'topdir' or vim.fn.getcwd(),
    }
  end, { desc = 'Live Grep west workspace' })

  vim.api.nvim_create_user_command('Wf', function()
    require('fzf-lua').files {
      cwd = H.exec 'topdir' or vim.fn.getcwd(),
    }
  end, { desc = 'Files west workspace' })
end

---
---@param subcmd string
---@param args? string[]
---@return string?
H.exec = function(subcmd, args)
  vim.validate('subcmd', subcmd, 'string')
  vim.validate('kwargs', args, 'table', true)
  args = args or {}

  local cmd = M.west .. ' ' .. subcmd .. ' '
  vim.fn.join(args, ' ')
  -- for k, v in vim.spairs(kwargs) do
  --   cmd[#cmd + 1] = k .. '=' .. v
  -- end
  local sysobj = vim.system(vim.fn.split(cmd, ' ')):wait()
  if sysobj.code ~= 0 then
    VimRc.err('West cmd failed with err: ', sysobj.stderr)
    return
  end
  local lines = vim.split(sysobj.stdout, '\n', { trimempty = true })
  if #lines == 0 then
    VimRc.warn('No output for command', { cmd = cmd })
  end
  return vim.fn.join(lines, '\n')
end

---@param dir integer|string|nil
---@return string?
H.west_workspace = function(dir)
  local topdir
  if not dir then
    topdir = vim.fs.root(0, { '.west' })
  elseif type(dir) == 'string' then
    topdir = vim.fs.root(dir, { '.west' })
  elseif type(dir) == 'integer' then
    topdir = vim.fs.root(vim.uri_from_bufnr(dir), { '.west' })
  end
  return topdir
end

H.get_projects = function()
  local projects = H.exec('list', { '-f', '"{name}:{posixpath}"' })
  if not projects then
    VimRc.warn 'No projects could be found'
    return
  end
  return vim
    .iter(projects)
    :map(function(v)
      return vim.fn.split(v, ':', false)
    end)
    :fold({}, function(acc, v)
      local n, p = v[1], v[2]
      acc[n] = p
      return acc
    end)
end

return M
