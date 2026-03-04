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
-- Tracks defined keymaps to prevent duplicates.
-- Key is a unique string like "n:<leader>ff".
KEYS.registry = {}
KEYS.leader_clues = {}
---@param lhs string
---@param mode string
local function keymap_encode(lhs, mode)
  return mode .. ':' .. lhs
end

---@class WhichKeyGroupSpec
---@field prefix string
---@field group string

--- Defines a list of keymaps, preventing duplicates and handling conditions.
---@param keymaps KeymapSpec[]
---@param wkey_group WhichKeyGroupSpec?
function KEYS.define(keymaps, wkey_group)
  -- if wkey_group then
  --   KEYS.leader_clues[#KEYS.leader_clues + 1] = { mode = 'n', keys = wkey_group.prefix, desc = wkey_group.group }
  -- end

  for _, spec in ipairs(keymaps) do
    ---@type table
    local modes = vim._ensure_list(spec.mode or 'n')
    for _, mode in ipairs(modes) do
      local id = keymap_encode(spec.lhs, mode)
      if KEYS.registry[id] then
        VimRc.warn('Keymap already defined and was skipped: ' .. id)
        goto continue_inner
      end

      ---@type vim.keymap.set.Opts
      local opts = spec.opts or {}
      vim.keymap.set(mode, spec.lhs, spec.rhs, opts)
      -- Mark this keymap as handled
      KEYS.registry[id] = true
      ::continue_inner::
    end
  end
end

---@param keymaps KeymapSpec[]
---@param enable boolean
function KEYS.toggle(keymaps, enable)
  for _, spec in ipairs(keymaps) do
    ---@type table
    local modes = vim._ensure_list(spec.mode or 'n')
    for _, mode in ipairs(modes) do
      if enable then
        -- Set the keymap
        ---@type vim.keymap.set.Opts
        local opts = spec.opts or {}
        vim.keymap.set(mode, spec.lhs, spec.rhs, opts)
      else
        -- Unmap the key
        pcall(vim.keymap.del, mode, spec.lhs)
      end
    end
  end
end

--[[
--  Global envs table and utilities
--]]

-- M.serial = require 'custom.serialization'
M.exec = require 'custom.exec'
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
---@field keys KeymapSpec[]?
---@field wkey_group WhichKeyGroupSpec?
---@type VimPackPlugin[]
M.added_plugins = {}
---@param spec VimPackPlugin
function M.pack_add(spec)
  if spec.dependencies then
    vim.pack.add(spec.dependencies)
  end
  local plug_spec = vim._ensure_list(spec.plugin)
  vim.pack.add(plug_spec)
  if spec.config then
    spec.config()
  elseif spec.opts and type(spec.opts) == 'table' then
    require(spec.name).setup(spec.opts)
  end
  if spec.keys then
    KEYS.define(spec.keys, spec.wkey_group)
  end
  M.added_plugins[#M.added_plugins + 1] = spec
end

---@alias BuildHookCmdTypes 'shell' | 'user'
BuildHookCmdTypes = {
  shell = 'shell',
  user = 'user',
}

---@class VimPackBuildHooks
---@field plugin string
---@field build_cmd_type BuildHookCmdTypes
---@field build_cmd string

---@param build_hook VimPackBuildHooks
local function create_plugin_build_hook(build_hook)
  VimRc.check_type('build_hook', build_hook, 'table')
  local plugin = build_hook.plugin
  VimRc.check_type('plugin', plugin, 'string')
  local type = build_hook.build_cmd_type
  vim.validate('type', type, 'string')
  local cmd = build_hook.build_cmd
  vim.validate('cmd', cmd, 'string')
  local hooks = function(ev)
    -- Use available |event-data|
    local name, kind = ev.data.spec.name, ev.data.kind
    if type == BuildHookCmdTypes.shell then
      -- Run build script after plugin's code has changed
      if name == plugin and (kind == 'install' or kind == 'update') then
        vim.system(vim.fn.split(cmd), { cwd = ev.data.path })
      end
    elseif type == BuildHookCmdTypes.user then
      -- If action relies on code from the plugin (like user command or
      -- Lua code), make sure to explicitly load it first
      if name == plugin and kind == 'update' then
        if not ev.data.active then
          vim.cmd.packadd(plugin)
        end
        vim.cmd(cmd)
        require(plugin).after_update()
      end
    else
      VimRc.err 'Invalid build cmd type'
    end
  end

  -- If hooks need to run on install, run this before `vim.pack.add()`
  vim.api.nvim_create_autocmd('PackChanged', { callback = hooks })
end

---@class VimPackOpts
---@field version string?
---@field build_hook VimPackBuildHooks?

---@param p string
---@param opts VimPackOpts?
---@return vim.pack.Spec
function _G.plug(p, opts)
  local plug_name = p:match '%S+/(%S+)'
  if opts and opts.build_hook then
    create_plugin_build_hook(opts.build_hook)
    plug_name = opts.plugin or plug_name
  end
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
  VimRc.write_to_buffer(vim.split(table.concat(lines, '\n ------ \n'), '\n'), 'VimRc-packlist')
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
  VimRc.write_to_buffer(lines, 'VimRc-treesitter-list')
end
M.lsp = require 'custom.lsp'
return M
