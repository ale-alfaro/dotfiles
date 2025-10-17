---@module "mini.deps"

---@class VimKeys
---@param mode string|string[] Mode "short-name" (see |nvim_set_keymap()|), or a list thereof.
---@param lhs string           Left-hand side |{lhs}| of the mapping.
---@param rhs string|function  Right-hand side |{rhs}| of the mapping, can be a Lua function.
---@param desc string
---@param opts? vim.keymap.set.Opts

---@class PluginSpec
---@field source string The plugin repository (e.g., 'owner/repo')
---@field dependencies? string[]|table[] List of dependencies
---@field build? string|fun() Build command or function
---@field init? nil|fun(path: string, source: string, name: string) Configuration function
---@field opts? table|fun(spec: PluginSpec, opts: table): table Plugin options
---@field config? nil|fun(path: string, source: string, name: string) Configuration function
---@field keys? VimKeys[]|fun(): VimKeys[] Key mappings
---@field checkout? string Git checkout target (branch, tag, commit)

local M = {}

local setup_logic = function(spec, opts)
  local plugin_name = spec.source:match '([^/]+)$'
  plugin_name = plugin_name:gsub('%.nvim$', '')

  -- if _G.Utils.has_vim_pack then
  --   if spec.init then
  --     spec.init()
  --   end
  -- end

  local ok, plugin = pcall(require, plugin_name)
  if not ok then
    return
  end

  -- if _G.Utils.has_vim_pack then
  --   if spec.config then
  --     spec.config()
  --   end
  -- end

  if opts then
    if type(plugin.setup) == 'function' then
      if type(spec.opts) == 'table' then
        plugin.setup(spec.opts)
      else
        plugin.setup()
      end
    else
      vim.notify('Plugin ' .. plugin_name .. ' has options but no setup function!')
    end
  end

  if spec.keys then
    for _, key in ipairs(spec.keys) do
      local mode = key.mode or 'n'
      local key_opts = {}
      if key.desc then
        key_opts.desc = key.desc
      end
      vim.keymap.set(mode, key[1], key[2], key_opts)
    end
  end
end
--- Sets up a single plugin based on a spec.
---@param spec PluginSpec | string
function M.plugin_spec_add(spec)
  if _G.Utils.has_vim_pack then
    if type(spec) == 'string' then
      vim.pack.add('https://github.com/' .. spec)
      return
    end

    if type(spec) ~= 'table' and spec.source ~= nil then
      vim.notify('Plugin spec is not a table!', 'error')
      return
    end

    local source = 'https://github.com/' .. spec.source
    -- Add plugin to manager
    if spec.dependencies then
      for _, dep_spec in ipairs(spec.dependencies) do
        if type(dep_spec) == 'string' then
          vim.pack.add('https://github.com/' .. dep_spec)
        end
      end
    end

    -- Check if it's in 'user/repo' format and not a full URL/path
    -- if not source:match('^https?://') and not source:match('^/') and source:match('^[%w_.-]+/[%w_.-]+$') then
    --   source = 'https://github.com/' .. source
    -- end
    if spec.checkout ~= nil then
      if spec.checkout then
        vim.pack.add {
          src = source,
          version = spec.checkout,
        }
      end
    else
      local add_spec = { source = spec.source }
      if spec.checkout then
        add_spec.checkout = spec.checkout
      end
      if spec.dependencies then
        add_spec.depends = spec.dependencies
      end

      add_spec.hooks = {}
      if spec.build then
        if type(spec.build) == 'string' then
          local build_cmd = '!' .. spec.build
          add_spec.hooks.post_checkout = function()
            vim.cmd(build_cmd)
          end
          add_spec.hooks.post_install = function()
            vim.cmd(build_cmd)
          end
        else
          add_spec.hooks.post_checkout = spec.build
          add_spec.hooks.post_install = spec.build
        end
      end
      if spec.init then
        add_spec.hooks.pre_install = spec.init
      end
      if spec.config then
        add_spec.hooks.post_install = spec.config
      end
      MiniDeps.add(add_spec)
    end
  end
end

---@param name string
---@param opts table?
function M.plugin_setup(plugin, opts)
  -- Setup logic
  local plugin_setup_logic = function()
    if opts and type(opts) == 'table' then
      plugin.setup(opts)
    else
      plugin.setup()
    end
  end
  if _G.Utils.has_vim_pack then
    vim.defer_fn(plugin_setup_logic, 0)
  else
    -- For MiniDeps, init and config are handled by hooks.
    -- So only need to handle opts and keys.
    MiniDeps.later(plugin_setup_logic)
  end
end

--- Sets up a list of plugins.
---@param specs (PluginSpec|string)[]
function M.plugins_setup_all(specs)
  for _, spec in ipairs(specs) do
    M.plugin_spec_add(spec)

    local plugin_name = spec.source:match '([^/]+)$'
    plugin_name = plugin_name:gsub('%.nvim$', '')

    local ok, plugin = pcall(require, plugin_name)
    if not ok then
      return
    end
    if plugin ~= nil and plugin.setup ~= nil then
      M.plugin_setup(plugin, spec.opts)
    end

    if spec.keys then
      for _, key in ipairs(spec.keys) do
        local mode = key.mode or 'n'
        local key_opts = {}
        if key.desc then
          key_opts.desc = key.desc
        end
        vim.keymap.set(mode, key[1], key[2], key_opts)
      end
    end
  end
end

return M
