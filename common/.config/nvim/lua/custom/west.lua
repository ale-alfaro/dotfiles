local M = {}
local H = {}

M.west = { 'west' }
M.setup = function()
  M.topdir = M.topdir or M.get_topdir(vim.api.nvim_get_current_buf())
  M.zephyr_base = vim.env['ZEPHYR_BASE'] or M.get_config ('zephyr.base')
  if not M.topdir or not M.zephyr_base then
    VimRc.warn 'no west workspace found'
    return
  end
  if not vim.uv.fs_stat(M.zephyr_base) then
    M.zephyr_base = vim.fs.joinpath(M.topdir, M.zephyr_base)
  end

  require('vimrc_lsp.dts').config { topdir = M.topdir, relative_zephyr_base = M.zephyr_base }
  require('vimrc_lsp.clangd').setup(M.topdir)

  vim.api.nvim_create_user_command('Wg', function()
    require('fzf-lua').live_grep {
      cwd = H.exec 'topdir' or vim.fn.getcwd(),
    }
  end, { desc = 'Live Grep west workspace' })

  vim.api.nvim_create_user_command('Wz', function()
    require('fzf-lua').files {
      cwd = M.zephyr_base or vim.fn.getcwd(),
    }
  end, { desc = 'Files west workspace' })
  vim.api.nvim_create_user_command('Wf', function()
    require('fzf-lua').files {
      cwd = H.exec 'topdir' or vim.fn.getcwd(),
    }
  end, { desc = 'Files west workspace' })
end

---
---@param subcmd string
---@param args? string[]
---@param opts? {quiet:boolean,check:boolean}
---@return string?
H.exec = function(subcmd, args, opts)
  vim.validate('subcmd', subcmd, 'string')
  vim.validate('args', args, vim.islist, true)
  vim.validate('opts', opts, 'table', true)
  args = args or {}
  opts = opts or {}
  local west = (opts.quiet ~= nil) and { 'west', '-qqq' } or { 'west' }
  local cmd = { unpack(west), subcmd, unpack(args) }
  local sysobj = vim.system(cmd, { text = true }):wait()
  if opts.check and sysobj.code ~= 0 then
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
M.get_topdir = function(dir)
  local topdir
  if not dir then
    topdir = vim.fs.root(0, { '.west' })
  elseif type(dir) == 'string' then
    topdir = vim.fs.root(dir, { '.west' })
  elseif type(dir) == 'integer' then
    topdir = vim.fs.root(vim.uri_from_bufnr(dir), { '.west' })
  end
  return topdir or H.exec('topdir', nil, { quiet = true, check = false })
end

M.get_config = function(config)
  local val = H.exec('config', { config }, { quiet = true })
  if not val then
    VimRc.warn('No config with key  ' .. config .. ' could be found')
    return
  end
  return val
end
---@return table<string,string>?
M.get_projects = function()
  local projects = H.exec('list', { '-f', vim.fn.shellescape '"{name}:{posixpath}"' })
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
