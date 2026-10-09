---@module 'fzf-lua'

local M = {}
local H = {}
M.setup = function()
  local topdir = H.topdir()
  if topdir  then
    vim.g.west_topdir = topdir
    require('vimrc_lsp.clangd').setup(topdir)
  end

  vim.api.nvim_create_user_command('Wg', function()
    require('fzf-lua').live_grep {
      cwd = H.topdir(),
    }
  end, { desc = 'Live Grep west workspace' })

  vim.api.nvim_create_user_command('Wf', function()
    require('fzf-lua').files {
      cwd = H.topdir(),
    }
  end, { desc = 'Files west workspace' })

  vim.api.nvim_create_user_command('Ws', function()
    require('fzf-lua').files {
      cwd = H.topdir(),
    }
  end, { desc = 'Files west workspace' })

  local overseer = require("overseer")
  if not overseer then
    vim.notify("Overseer not loaded", vim.log.levels.ERROR)
    return
  end
  vim.api.nvim_create_user_command('WestBuild', function(ev)

    local cmd = string.format('west build -p=auto -d %q', (ev.fargs or {'build'})[1])
    local task = overseer.new_task({
      name = "west build incremental",
      cmd = cmd,
      components = {

        "default_west",
      },
    })
    task:start()
  end, { 
  nargs = '*',
  desc = "Incremental Build" })



  vim.api.nvim_create_user_command('WestClean', function()
    local task = overseer.new_task({
      name = "West Build Pristine",
      cmd = "mise makeprg:aria --clean always",
      components = {
        "default_west",
        {
          "on_output_write_file",
          filename = "build_diag.txt",
        },
      },
    })
    task:start()
  end, {   nargs = '*', desc = "Clean Build" })
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
  local cmd = { "west", subcmd, unpack(args) }
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
H.topdir = function(dir)
  dir = dir or vim.api.nvim_buf_get_name(0)

  local topdir = vim.g.west_topdir or vim.fs.root(dir, { '.west' })
  return topdir or H.exec('topdir', nil, {  check = false })
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
H.get_projects = function()
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
