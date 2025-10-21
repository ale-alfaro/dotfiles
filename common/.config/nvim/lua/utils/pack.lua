---@class VimKeys
---@param mode string|string[] Mode "short-name" (see |nvim_set_keymap()|), or a list thereof.
---@param lhs string           Left-hand side |{lhs}| of the mapping.
---@param rhs string|function  Right-hand side |{rhs}| of the mapping, can be a Lua function.
---@param desc string
---@param opts? vim.keymap.set.Opts

---@class PluginSpecPlus : vim.pack.Spec
---@field build? string Build command or function
---@field opts? table
---@field config? nil|fun(name: string, opts: table) Configuration function
---@field deps? nil|vim.pack.Spec[] Dependencies
---@field keys? VimKeys[]|fun(): VimKeys[] Key mappings

M = {}

function _G.plug(p)
return {
	src = 'https://github.com/' .. p,
	name = p:match '%S+/(%S+)'
}
end

function _G.plug_spec(spec)
	return vim.iter(spec):map(function(p) return _G.plug(p) end):totable()
end

--- @class PluginFilter
--- @field active boolean Whether plugin was added via |vim.pack.add()| to current session.

---@param names string[]
---@param active_only boolean?
function M.get_plugins(names, active_only)
  local plugins = vim.pack.get(names)
  if #plugins > 0 then
    if active_only then
      return vim.iter(plugins):filter(function(plug)
        return plug.active
      end)
    else
      return plugins
    end
  end
end

-- ---@param name string
-- ---@param path string?
function M.get_plugin_path(name, path)
  local plugin = M.get_plugin(name)
  path = path and '/' .. path or ''
  return plugin and (plugin.dir .. path)
end

--
-- ---@param plugin string
function M.has(plugin)
  return M.get_plugin(plugin) ~= nil
end

--- @param spec(vim.pack.Spec|PluginSpecPlus) Plugin specifications. String item
--- @return PluginSpecPlus Plugin specifications. String item
local function validate_plugin_spec(spec)
  vim.validate('spec', spec, { 'string', 'table' }, 'Plugin spec is malformed')
  ---@type PluginSpecPlus[]
  local plugin
  if type(spec) == 'string' then
    plugin = { src = spec }
  else
    plugin = spec
  end
  assert(plugin.src ~= nil, 'Plugin specifies no source (repo)')
  if plugin.src:match '^https?://' ~= nil then
    plugin.src = 'https://github.com/' .. plugin.src
  end
  if plugin.name == nil then
    plugin.name = plugin.src:match '^https://%S+/%S+/([^%.]+)'
  end
  return plugin
end
--- Sets up a single plugin based on a spec.
--- @param spec(vim.pack.Spec|PluginSpecPlus) Plugin specifications. String item
function M.add_plugin(spec)
  local plugin = validate_plugin_spec(spec)
  local plugin_spec = { plugin }

  -- if spec.deps and vim.islist(spec.deps) then
  --   for i = 1, #spec.deps do
  --     plugin_spec[i] = validate_plugin_spec(spec.deps[i])
  --   end
  -- end
  vim.pack.add(plugin_spec)
  -- Check if it's in 'user/repo' format and not a full URL/path
  if plugin.build ~= nil then
    _G.Utils.new_autocmd({ 'PackChanged' }, '*', function(args)
      local updated_spec = args.data.spec
      if updated_spec.name == plugin.name and (args.data.kind == 'update' or args.data.kind == 'install') then
        vim.notify(plugin.name .. ' was installed or updated, doing the build_step', vim.log.levels.INFO)

        local source_dir = args.data.path
        _G.Utils.cmd(plugin.build, function(output, ret_code)
          if ret_code ~= 0 then
            _G.Utils.notify.error('Build cmd ' .. plugin.build .. ' failed!')
          end
        end, { cwd = source_dir })
      end
    end, 'Build step after installing' .. plugin.name)
  end

  local ok, mod = pcall(require, plugin.name)
  if not ok then
    _G.Utils.notify.error('Failed to load plugin ' .. plugin.name)
    return
  end

  local opts = plugin.opts or {}
  if plugin.config then
    plugin.config(mod, opts)
  else
    mod.setup(opts)
  end
end

--- Sets up list of specs
--- @param specs (string|PluginSpecPlus)[] List of plugin specifications. String item
function M.add_plugin_spec(specs)
  if vim.islist(specs) then
    _G.Utils.notify.error 'vim.pack spec must be a list!'
    return
  end
  for i = 1, #specs do
    local plug = specs[i]
    M.add_plugin(plug)
  end
end

--- Updates one or more plugins.
--- @param plugin_names? string|string[] Optional: A single plugin name or a list of plugin names to update.
--- If omitted, all plugins will be updated.
function M.update(plugin_names)
  local plugins_to_update = {}
  local not_found_plugins = {}

  if plugin_names then
    if type(plugin_names) == 'string' then
      plugin_names = { plugin_names }
    end
    vim.validate('plugin_names', plugin_names, 'table')

    for _, name in ipairs(plugin_names) do
      local found = vim.pack.get { name = name }
      if found and #found > 0 then
        table.insert(plugins_to_update, found[1])
      else
        table.insert(not_found_plugins, name)
      end
    end
  else
    plugins_to_update = vim.pack.get()
  end

  if #not_found_plugins > 0 then
    vim.notify('Plugins not found: ' .. table.concat(not_found_plugins, ', '), vim.log.levels.WARN)
  end

  if #plugins_to_update == 0 then
    vim.notify('No plugins to update.', vim.log.levels.INFO)
    return
  end

  local function update_repo(path, name)
    if vim.fn.isdirectory(vim.fn.join_path(path, '.git')) == 1 then
      vim.notify('Updating ' .. name .. '...')
      vim.fn.jobstart('git pull', {
        cwd = path,
        on_exit = function(_, code)
          if code == 0 then
            vim.notify(name .. ' updated successfully.')
          else
            vim.notify('Failed to update ' .. name .. '.', vim.log.levels.ERROR)
          end
        end,
      })
    end
  end

  vim.notify('Updating ' .. #plugins_to_update .. ' plugin(s)...')
  for _, plugin in ipairs(plugins_to_update) do
    update_repo(plugin.path, plugin.spec.name)
  end
end

--- Removes one or more plugins.
--- @param plugin_names? string|string[] Optional: A single plugin name or a list of plugin names to remove.
--- If omitted, ALL plugins will be removed after a confirmation.
function M.remove(plugin_names)
  local plugins_to_remove = {}
  local not_found_plugins = {}

  if plugin_names then
    if type(plugin_names) == 'string' then
      plugin_names = { plugin_names }
    end
    vim.validate('plugin_names', plugin_names, 'table')

    for _, name in ipairs(plugin_names) do
      local found = vim.pack.get { name = name }
      if found and #found > 0 then
        table.insert(plugins_to_remove, found[1])
      else
        table.insert(not_found_plugins, name)
      end
    end
  else
    plugins_to_remove = vim.pack.get()
  end

  if #not_found_plugins > 0 then
    vim.notify('Plugins not found: ' .. table.concat(not_found_plugins, ', '), vim.log.levels.WARN)
  end

  if #plugins_to_remove == 0 then
    vim.notify('No plugins to remove.', vim.log.levels.INFO)
    return
  end

  local prompt
  local plugin_names_str_list = {}
  for _, p in ipairs(plugins_to_remove) do
    table.insert(plugin_names_str_list, p.spec.name)
  end

  if plugin_names then
    prompt = 'Are you sure you want to remove ' .. #plugins_to_remove .. ' plugin(s)?\n' .. table.concat(plugin_names_str_list, '\n')
  else
    prompt = '!!! WARNING !!!\nAre you sure you want to remove ALL ' .. #plugins_to_remove .. ' installed plugins?'
  end

  local choice = vim.fn.confirm(prompt, '&Yes\n&No', 2)
  if choice == 1 then
    for _, plugin in ipairs(plugins_to_remove) do
      vim.fn.delete(plugin.path, 'rf')
      vim.notify(plugin.spec.name .. ' removed successfully.')
    end
    vim.cmd 'packloadall!' -- Refresh runtime paths
  else
    vim.notify 'Removal cancelled.'
  end
end

return M
