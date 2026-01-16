local M = {}
M.icons = require 'custom.icons'
setmetatable(M, {
  __index = function(t, k)
    ---@diagnostic disable-next-line: no-unknown
    t[k] = require('utils.' .. k)
    return t[k]
  end,
})

function _G.setTimeout(timeout, callback)
  local timer = vim.uv.new_timer()
  if timer ~= nil then
    timer:start(timeout, 0, function()
      timer:stop()
      timer:close()
      callback()
    end)
    return timer
  end
end

---@param msg string|string[]
function _G.info(msg)
  if M.notify then M.notify(msg, 'INFO') end
end

---@param msg string|string[]
function _G.warn(msg)
  if M.notify then M.notify(msg, 'WARN') end
end

---@param msg string|string[]
function _G.error(msg, var)
  if M.notify then M.notify(msg, 'ERROR') end
end

---@param base table|nil
---@param extra table|nil
---@return table
function _G.merge_tables(base, extra)
  return vim.tbl_deep_extend('force', base or {}, extra or {})
end

local function _fetch_env(env_name)
  local env = vim.fn.getenv(env_name)
  if env ~= vim.v.null then
    return env
  end
  return nil
end
-- 'WEST_TOPDIR'
function _G.ENV(name, fallback)
  return vim.fn.has_key(vim.fn.environ(), name) and _fetch_env(name) or fallback
end

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
  local wkey_spec = {}
  if wkey_group then
    wkey_spec[#wkey_spec + 1] = { wkey_group.prefix, group = wkey_group.group }
  end

  for _, spec in ipairs(keymaps) do
    ---@type table
    local modes = vim._ensure_list(spec.mode or 'n')
    for _, mode in ipairs(modes) do
      local id = keymap_encode(spec.lhs, mode)
      if KEYS.registry[id] then
        vim.notify('Keymap already defined and was skipped: ' .. id, vim.log.levels.WARN)
        goto continue_inner
      end

      ---@type vim.keymap.set.Opts
      local opts = spec.opts or {}
      vim.keymap.set(mode, spec.lhs, spec.rhs, opts)
      if wkey_group then
        wkey_spec[#wkey_spec + 1] = { spec.lhs, desc = opts.desc or wkey_group.prefix }
      end

      -- Mark this keymap as handled
      KEYS.registry[id] = true
      ::continue_inner::
    end
  end

  if #wkey_spec > 1 then
    require('which-key').add(wkey_spec)
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
M.exec = require 'custom.executables'

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
  vim.validate('build_hook', build_hook, 'table')
  local plugin = build_hook.plugin
  vim.validate('plugin', plugin, 'string')
  local type = build_hook.build_cmd_type
  vim.validate('type', type, 'string')
  local cmd = build_hook.build_cmd
  vim.validate('cmd', cmd, 'string')
  _G.info('Creating ' .. type .. ' build hook for ' .. plugin .. ' with cmd: ' .. cmd)
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
      _G.error('Invalid build cmd type ' .. type)
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

--- @class PluginFilter
--- @field active boolean Whether plugin was added via |vim.pack.add()| to current session.

---@param active_only boolean?
local function get_plugins(active_only)
  local plugins = vim.pack.get()
  if #plugins > 0 then
    return vim
        .iter(plugins)
        :filter(function(plug)
          if active_only then
            return plug.active
          else
            return true
          end
        end)
        :map(function(plug)
          return plug.name
        end)
        :totable()
  end
end
--- Updates one or more plugins.
--- If omitted, all plugins will be updated.
function M.pack_update()
  local plugins = get_plugins(true)
  if plugins then
    vim.pack.update(plugins)
  end
end

--- @param plugins string[] Optional: A single plugin name or a list of plugin names to update.
function M.pack_reload(plugins)
  local ok, _ = pcall(vim.pack.del, plugins)
  if not ok then
    _G.error 'Failed to delete plugins with vim.pack.del'
  end
  ok, _ = pcall(vim.pack.add, _G.plug_spec(plugins))
  if not ok then
    _G.error 'Failed to add plugins with vim.pack.add'
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
  local lines = { 'Vim.pack list:' }
  --- @type vim.pack.PlugData[]
  local plugins = vim.pack.get()
  for _, plug in ipairs(plugins) do
    lines[#lines + 1] = (' %s - `%s`'):format(plug.spec.name, plug.spec.version)
  end
  _G.info(lines)
end

--
--

return M
