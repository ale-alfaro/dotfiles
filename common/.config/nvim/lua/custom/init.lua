local M = {}
M.icons = require 'custom.icons'
setmetatable(M, {
  __index = function(t, k)
    ---@diagnostic disable-next-line: no-unknown
    t[k] = require('utils.' .. k)
    return t[k]
  end,
})

---@param msg string|string[]
---@param level string
local function notify(msg, level)
  msg = type(msg) == 'table' and table.concat(msg, '\n') or msg --[[@as string]]
  msg = vim.trim(msg)
  vim.notify(msg, level)
end

---@param msg string|string[]
function _G.warn(msg)
  return notify(msg, 'WARN')
end

---@param msg string|string[]
function _G.info(msg)
  return notify(msg, 'INFO')
end

---@param msg string|string[]
function _G.error(msg, var)
  local ret = notify(msg, 'ERROR')
  if var then
    return notify(var, 'ERROR')
  end
  return ret
end

function _G.fetch_env(env_name, fallback)
  fallback = fallback or ''
  local env = vim.fn.getenv(env_name)
  return env ~= vim.v.null and env or fallback
end
local env_vars = {
  ZEPHYR_BASE = { '.' },
  XDG_CONFIG_HOME = { 'hypr', 'direnv', 'zsh', 'just' },
  OBSIDIAN_HOME = { 'Sibel-Work' },
}
function _G.fetch_env_paths()
  local res = {}
  for env, paths in pairs(env_vars) do
    local expanded_env = fetch_env(env, nil)
    if expanded_env then
      for _, p in ipairs(paths) do
        if p == '.' then
          res[env] = expanded_env
        else
          res[p] = expanded_env .. '/' .. p
        end
      end
    end
  end
  return res
end

---@param json string
---@return string[]
function _G.fmt_json(json)
  local indent = vim.bo.expandtab and (' '):rep(vim.o.shiftwidth) or '\t'
  ---@type string
  -- local lines = vim.islist(json) and table.concat(json, '\n') or json
  local content = json:gsub('\n', '')
  local o = vim.json.decode(content)
  vim.print(o)
  return o
  -- local stringified = vim.json.encode(o, { indent = indent, sort_keys = true })
  -- return vim.split(stringified, '\n')
end

M.exec = require 'custom.executables'
---@class KeymapSpec
---@field lhs string
---@field rhs string|fun(args:table)
---@field mode string|string[]?
---@field opts vim.keymap.set.Opts?
---
-- Tracks defined keymaps to prevent duplicates.
-- Key is a unique string like "n:<leader>ff".
M.keymap_registry = {}

---@param lhs string
---@param mode string
local function keymap_encode(lhs, mode)
  return mode .. ':' .. lhs
end

---@param lhs string
---@param mode? string
function M.keymap_have(lhs, mode)
  local check_mode = mode or 'n'
  return M.keymap_registry[keymap_encode(lhs, check_mode)] ~= nil
end

function M.add_ft_keymaps(keys)
  vim.api.nvim_create_autocmd('FileType', {
    pattern = keys.ft,
    callback = function(event)
      if keys.rhs then
        local opts = vim.deepcopy(keys.opts or {})
        opts.buffer = event.buf
        M.safe_keymap_set(keys.mode, keys.lhs, keys.rhs, opts)
      end
    end,
  })
end

---@class WhichKeyGroupSpec
---@field prefix string
---@field group string

--- Defines a list of keymaps, preventing duplicates and handling conditions.
---@param keymaps KeymapSpec[]
---@param wkey_group WhichKeyGroupSpec?
function _G.keymaps_define(keymaps, wkey_group)
  local wkey_spec = {}
  if wkey_group then
    wkey_spec[#wkey_spec + 1] = { wkey_group.prefix, group = wkey_group.group }
  end

  for _, spec in ipairs(keymaps) do
    ---@type table
    local modes = vim._ensure_list(spec.mode or 'n')
    for _, mode in ipairs(modes) do
      local id = keymap_encode(spec.lhs, mode)
      if M.keymap_registry[id] then
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
      M.keymap_registry[id] = true
      ::continue_inner::
    end
  end

  if #wkey_spec > 1 then
    require('which-key').add(wkey_spec)
  end
end

---@param keymaps KeymapSpec[]
---@param enable boolean
function _G.keymaps_toggle(keymaps, enable)
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

function M.setTimeout(timeout, callback)
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

M.packpath = vim.fn.expand '$XDG_DATA_HOME' .. '/nvim/site/pack/core/opt'

---@return table<string>
function M.get_packpath_dirs()
  local paths = {}
  for name, type in
    vim.fs.dir(M.packpath, {
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
---@field config fun(opts: table)?
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
    _G.keymaps_define(spec.keys, spec.wkey_group)
  end
  M.added_plugins[#M.added_plugins + 1] = spec
end

---@param cmd string|string[]
---@param cb fun(output: string[], code: number)
---@param opts? {env?: table<string, string>, cwd?: string}
local function run_build_cmd(cmd, cb, opts)
  local output = {} ---@type string[]
  local id = vim.fn.jobstart(
    cmd,
    vim.tbl_extend('force', opts or {}, {
      on_stdout = function(_, data)
        output[#output + 1] = table.concat(data, '\n')
      end,
      on_exit = function(_, code)
        cb(output, code)
        if code ~= 0 then
          vim.notify(
            ('Terminal **cmd** `%s` failed with code `%d`:\n- `vim.o.shell = %q`\n\nOutput:\n%s'):format(
              cmd,
              code,
              vim.o.shell,
              vim.trim(table.concat(output, '')),
              'error'
            )
          )
        end
      end,
    })
  )
  if id <= 0 then
    _G.error(('Failed to start job `%s`'):format(cmd))
  end
  return id > 0 and id or nil
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

function M.require_config_dir(dir)
  -- ~/.config/nvim/lua/
  dir = dir or 'lua'
  local base_lua_path = vim.fs.joinpath(vim.fn.stdpath 'config', 'lua')
  -- i.e. ~/.config/nvim/lua/plugins/*.lua
  local glob_path = vim.fs.joinpath(base_lua_path, '[^0-9]*.lua')

  local paths_str = vim.fn.glob(glob_path)
  local paths_tbl = vim.split(paths_str, '\n')

  for _, path in pairs(paths_tbl) do
    -- convert absolute filename to relative
    -- ~/.config/nvim/lua/plugins/config_file.lua -> plugins/config_file
    local relfilename = vim.fs.relpath(base_lua_path, path):gsub('.lua', '')
    _G.info('Requiring: ' .. relfilename)
    require(relfilename)
  end
end

--
--

---@param what string|number|nil
---@param query? string
---@overload fun(buf?:number):boolean
---@overload fun(ft:string):boolean
---@return boolean
function M.treesitter_have(what, query)
  what = what or vim.api.nvim_get_current_buf()
  what = type(what) == 'number' and vim.bo[what].filetype or what --[[@as string]]
  local lang = vim.treesitter.language.get_lang(what)

  local parsers = require('nvim-treesitter').get_installed()
  if lang == nil or parsers[lang] == nil then
    return false
  end
  -- if query and not M.have_query(lang, query) then
  --   return false
  -- end
  return true
end

function M.treesitter_foldexpr()
  return M.treesitter_have(nil, 'folds') and vim.treesitter.foldexpr() or '0'
end

function M.tresitter_indentexpr()
  return M.treesitter_have(nil, 'indents') and require('nvim-treesitter').indentexpr() or -1
end

return M
