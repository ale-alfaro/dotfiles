local M = require 'custom.utils'
M.debug_mode = false
M.icons = require 'custom.icons'

M.THEME = 'kanagawa'
--[[
--  Global keymaps object for defining and toggling keys
--]]
_G.KEYS = {}
---@class KeymapSpec
---@field lhs string
---@field rhs string|fun(args:table)
---@field mode string|string[]?
---@field opts vim.keymap.set.Opts?
---

--[[
--  Global envs table and utilities
--]]

-- M.serial = require 'custom.serialization'
---@param lines string[]
---@param bufname string
M.write_to_buffer = function(lines, bufname)
  local bufnr = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_name(bufnr, bufname .. '#' .. bufnr)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.cmd.sbuffer { bufnr, mods = { tab = vim.fn.tabpagenr() } }
end

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
---@return table<string>
function M.get_packpath_dirs()
  local paths = {}
  local packpath = vim.fn.expand '$XDG_DATA_HOME' .. '/nvim/site/pack/core/opt'
  for name, type in
    vim.fs.dir(packpath, {
      skip = function(dir_name)
        if not string.match(dir_name, '^nvim') then
          return true
        else
          return false
        end
      end,
    })
  do
    if type == 'directory' then
      table.insert(paths, name)
    end
  end
  return paths
end

---@class VimPackPlugin
---@field name string
---@field plugin vim.pack.Spec
---@field dependencies vim.pack.Spec?
---@field opts table?
---@field config fun()?
---@field keys table<string,string|function,string>?
---@type VimPackPlugin[]
M.added_plugins = {}
---@param spec VimPackPlugin
function M.pack_add(spec)
  if spec.dependencies then
    vim.pack.add(spec.dependencies)
  end
  local plug_spec = vim._ensure_list(spec.plugin)
  if spec.config then
    vim.pack.add(plug_spec)
    spec.config()
  elseif spec.opts and type(spec.opts) == 'table' then
    require(spec.name).setup(spec.opts)
  end
  if spec.keys and vim.islist(spec.keys) then
    for _, k in ipairs(spec.keys) do
      if vim.islist(k) and #k == 3 then
        vim.keymap.set('n', k[1], k[2], { desc = k[3] })
      end
    end
  end
  M.added_plugins[#M.added_plugins + 1] = spec
end

---@class VimPackOpts
---@field version string?

---@param p string
---@param opts VimPackOpts?
---@return vim.pack.Spec
function _G.plug(p, opts)
  local plug_name = p:match '%S+/(%S+)'
  ---@type vim.pack.Spec
  local plug = {
    src = 'https://github.com/' .. p,
    name = plug_name,
  }
  if opts and opts.version then
    plug.version = opts.version
  end
  return plug
end

---@param spec string[]
---@return vim.pack.Spec
function _G.plug_spec(spec)
  table.insert(M.added_plugins, spec)
  return vim
    .iter(spec)
    :map(function(p)
      return _G.plug(p)
    end)
    :totable()
end
---@class FilterOpts
---@field names string[]?
---@field filter_fn fun(p:vim.pack.PlugData):boolean|nil
---@field output_names boolean?
---
---@param opts FilterOpts?
---@return string[]
M.get_plugins = function(opts)
  vim.validate('opts', opts, 'table', true, 'FilterOpts')
  opts = vim.tbl_extend('force', { names = nil, filter_fn = nil, output_names = true }, opts or {})
  ---@type FilterOpts

  return vim
    .iter(vim.pack.get(opts.names))
    :map(function(p)
      local pname = opts.output_names and p.spec.name or p
      if type(opts.filter_fn) == 'callable' then
        return pname and opts.filter_fn(p) or nil
      end
      return pname
    end)
    :totable()
end

--- @param plugins string[] Optional: A single plugin name or a list of plugin names to update.
function M.pack_reload(plugins)
  local ok, _ = pcall(vim.pack.del, plugins)
  if not ok then
    VimRc.err 'Failed to delete plugins with vim.pack.del'
  end
  ok, _ = pcall(vim.pack.add, _G.plug_spec(plugins))
  if not ok then
    VimRc.err 'Failed to add plugins with vim.pack.add'
  end
end

function M.pack_clean()
  local active_plugins = {}
  local unused_plugins = {}

  for _, plugin in ipairs(vim.pack.get()) do
    active_plugins[plugin.spec.name] = plugin.active
  end

  for _, plugin in ipairs(vim.pack.get()) do
    if not active_plugins[plugin.spec.name] then
      table.insert(unused_plugins, plugin.spec.name)
    end
  end

  if #unused_plugins == 0 then
    print 'No unused plugins.'
    return
  end

  local choice = vim.fn.confirm('Remove unused plugins?', '&Yes\n&No', 2)
  if choice == 1 then
    vim.pack.del(unused_plugins)
  end
end

function M.pack_list()
  ---@type vim.pack.PlugData[]
  local plugins = M.get_plugins { output_names = false }
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
  M.write_to_buffer(vim.split(table.concat(lines, '\n ------ \n'), '\n'), 'VimRc-packlist')
end

function M.treesitter_list()
  ---@type vim.pack.PlugData[]
  local installed = require('nvim-treesitter').get_installed()
  local available = vim
    .iter(require('nvim-treesitter.config').get_available())
    :filter(function(parser)
      return not vim.list_contains(installed, parser)
    end)
    :totable()
  ---@type string[]
  local lines = vim
    .iter({ 'Installed Parser/Grammars:', '--------------------', installed, 'Available Parser/Grammars:', '-------------------- ', available })
    :flatten(2)
    :totable()
  M.write_to_buffer(lines, 'VimRc-treesitter-list')
end

---@class FeatureFlagOpts
---@field local boolean?
---@field toggle_hook fun(enabled: boolean, bufnr:integer, data:table)?
---
---
---@class FeatureFlag
---@field name string
---@field gl_enabled boolean
---@field opts FeatureFlagOpts?
---
---@type FeatureFlag
FeatureFlag = {}
---@method
---@param o FeatureFlag
function FeatureFlag:new(o)
  o = o or {} -- create object if user does not provide one
  setmetatable(o, self)
  self.__index = self
  return o
end
---@class vimrc.FeatureFlags
---@field entries table<string, FeatureFlag>
_G.FeatureFlags = {
  entries = {},
}
FeatureFlags.__index = FeatureFlags

---@param feature FeatureFlag|string
---@return FeatureFlag
function FeatureFlags:add(feature)
  vim.validate('feature', feature, { 'table', 'string' })
  local name
  if type(feature) == 'string' then
    name = feature
    feature = FeatureFlag:new { name = name, gl_enabled = false }
  else
    name = feature.name
  end

  self.entries[name] = feature
  local usercmd_name = name .. 'Toggle'
  vim.api.nvim_create_user_command(usercmd_name, function(args)
    local flag = FeatureFlags:get(name)
    local enable = not flag.gl_enabled
    local opts = flag.opts or {}
    FeatureFlags:set(flag.name, enable)
    if vim.is_callable(opts.toggle_hook) then
      opts.toggle_hook(enable, vim.api.nvim_get_current_buf(), args)
    end
  end, {
    desc = 'Toggle feature flag for ' .. name,
  })
  return feature
end

---@param name string
---@return FeatureFlag
function FeatureFlags:get(name)
  -- clear nodes on change tick, calling any methods on invalid nodes causes
  -- neovim to hard crash
  local entry = self.entries[name]
  if not entry then
    return FeatureFlags:add { name = name, gl_enabled = false }
  end
  return entry
end

---@param name string
---@param enable boolean?
function FeatureFlags:set(name, enable)
  local fflag = self:get(name)
  fflag.gl_enabled = enable or false
  self.entries[name] = fflag
end

---@comment Get the lsp configuration in the current working directory
---@param loc string
---@return string[]
M.lsp_configs_get = function(loc)
  local lsp_dir = ''
  if type(loc) == 'string' and vim.uv.fs_stat(loc) then
    lsp_dir = vim.fs.joinpath(loc, 'lsp')
  else
    lsp_dir = vim.fs.joinpath(vim.fn.getcwd(), 'lsp')
  end
  if not vim.uv.fs_stat(lsp_dir) then
    VimRc.err('LSP folder ' .. lsp_dir .. ' doesnt contain a lsp directory!')
    return {}
  end
  local lsps = {}
  for name, type in vim.fs.dir(lsp_dir) do
    if type == 'file' then
      lsps[#lsps + 1] = name:gsub('(%w+)%.lua', '%1')
    end
  end
  return lsps
end

---@class VimRcLspSetup
---@field on_attach fun(client:vim.lsp.Client,bufnr:number)
---@field keymaps? table
---

---@return table<string, VimRcLspSetup?>
M.lsp_setups_get = function()
  local lsps = {}
  local lsp_config_dir = vim.fs.joinpath(vim.fs.dirname(VimRc.env['MYVIMRC']), 'lsp')
  for fname, type in vim.fs.dir(lsp_config_dir) do
    local lsp_name = fname:gsub('(%w+)%.lua', '%1')
    lsps[#lsps + 1] = lsp_name
  end
  return lsps
end
M.enable_workspace_lsps = function(workspace_topdir)
  local nvim_dir = vim.fs.joinpath(workspace_topdir, '.nvim')

  local lsps = M.local_configs_get(nvim_dir)
  if lsps and #lsps > 0 then
    VimRc.info(string.format('Enabling lsps in workspace %s :\n %s', workspace_topdir, table.concat(lsps, '\n')))
    vim.lsp.enable(lsps)
  else
    VimRc.err('Couldnt find any lsp configs in ' .. nvim_dir)
  end
end
---@param client vim.lsp.Client
---@param bufnr integer
---@param method vim.lsp.protocol.Method.ClientToServer.Request
---@param params table
---@param handler lsp.Handler
function M.lsp_request_method(client, bufnr, method, params, handler)
  vim.validate('method', method, 'string')
  vim.validate('params', params, 'table', true)
  vim.validate('handler', handler, 'function')
  vim.validate('bufnr', bufnr, 'number')

  if client and client:supports_method(method, bufnr) then
    client:request(method, params, handler, bufnr)
  end
end
return M
