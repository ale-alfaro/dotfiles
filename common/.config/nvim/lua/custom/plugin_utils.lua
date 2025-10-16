---@module "mini.deps"

---@class PluginSpec
---@field 1 string The plugin repository (e.g., 'owner/repo')
---@field dependencies? string[]|table[] List of dependencies
---@field hooks? table Hooks for MiniDeps
---@field checkout? string Branch/tag to checkout
---@field build? string|fun() Build command or function
---@field opts? table|fun(spec: PluginSpec, opts: table): table Plugin options
---@field config? boolean|fun(spec: PluginSpec, opts: table) Configuration function
---@field keys? table[]|fun(spec: PluginSpec, opts: table): table[] Key mappings
---@field lazy? boolean If true, load with MiniDeps.later()
---@field event? string|string[] Lazy-load on event
---@field cmd? string|string[] Lazy-load on command
---@field ft? string|string[] Lazy-load on filetype
---@field init? fun(spec: PluginSpec) Function to run before setup
---@field load_if_args? boolean Load with `now` if Neovim started with file arguments
--[[

Each plugin dependency is managed based on its specification (a.k.a. "spec").
See |MiniDeps-overview| for some examples.

Specification can be a single string which is inferred as:
- Plugin <name> if it doesn't contain "/".
- Plugin <source> otherwise.

Primarily, specification is a table with the following fields:

- <source> `(string|nil)` - field with URI of plugin source used during creation
  or update. Can be anything allowed by `git clone`.
  Default: `nil` to rely on source set up during install.
  Notes:
    - It is required for creating plugin, but can be omitted afterwards.
    - As the most common case, URI of the format "user/repo" (if it contains
      valid characters) is transformed into "https://github.com/user/repo".

- <name> `(string|nil)` - directory basename of where to put plugin source.
  It is put in "pack/deps/opt" subdirectory of `config.path.package`.
  Default: basename of <source> if it is present, otherwise should be
  provided explicitly.

- <checkout> `(string|nil)` - checkout target used to set state during update.
  Can be anything supported by `git checkout` - branch, commit, tag, etc.
  Default: `nil` for default branch (usually "main" or "master").

- <monitor> `(string|nil)` - monitor branch used to track new changes from
  different target than `checkout`. Should be a name of present Git branch.
  Default: `nil` for default branch (usually "main" or "master").

- <depends> `(table|nil)` - array of plugin specifications (strings or tables)
  to be added prior to the target.
  Default: `nil` for no dependencies.

- <hooks> `(table|nil)` - table with callable hooks to call on certain events.
  Possible hook names:
    - <pre_install>   - before creating plugin directory.
    - <post_install>  - after  creating plugin directory (before |:packadd|).
    - <pre_checkout>  - before making change in existing plugin.
    - <post_checkout> - after  making change in existing plugin.
  Each hook is executed with the following table as an argument:
    - <path> (`string`)   - absolute path to plugin's directory
      (might not yet exist on disk).
    - <source> (`string`) - resolved <source> from spec.
    - <name> (`string`)   - resolved <name> from spec.
  Default: `nil` for no hooks.
--]]
local M = {}

local add, now, later

--- Initializes the utility with MiniDeps functions.
---@param deps { add: function, now: function, later: function }
function M.init(deps)
  add = deps.add
  now = deps.now
  later = deps.later
end

--- Sets up a single plugin based on a spec.
---@param spec PluginSpec
function M.setup(spec)
  -- Run init function if it exists
  -- if spec.init then
  --   spec.init(spec)
  -- end
  vim.notify("Adding spec: " .. vim.inspect(spec))
  if type(spec) ~= 'table' then
    vim.notify("Plugin spec is not a table!", "error")
    return
  end
  ---@type 
  -- 1. Add the plugin with MiniDeps
  local add_spec = { source = spec[1] }
  if spec.dependencies then add_spec.depends = spec.dependencies end
  if spec.config then add_spec.hooks = { post_install = spec.hooks } end
  if spec.version then add_spec.checkout = spec.version end
  -- if spec.build then add_spec.build = spec.build end
  add(add_spec)

  -- 2. Define configuration logic
  local do_config = function()
    -- Extract plugin name from 'owner/repo'
    local plugin_name = spec[1]:match '([^/]+)$'
    -- Strip .nvim if present for require path
    plugin_name = plugin_name:gsub('%.nvim$', '')

    -- Determine opts
    local opts
    if type(spec.opts) == 'function' then
      opts = spec.opts(spec, {})
    else
      opts = spec.opts
    end

    -- Determine how to configure
    if spec.config == true then
      require(plugin_name).setup(opts)
    elseif type(spec.config) == 'function' then
      spec.config(spec, opts)
    elseif opts then
      require(plugin_name).setup(opts)
    end

    -- 3. Setup keymaps
    if spec.keys then
      local keys
      if type(spec.keys) == 'function' then
        keys = spec.keys(spec, {})
      else
        keys = spec.keys
      end

      for _, key_spec in ipairs(keys) do
        local lhs = key_spec[1]
        local rhs = key_spec[2]

        if rhs == false then
          -- Unmap key
          local modes = key_spec.mode or { 'n', 'v', 'o', 'x', 'i', 'c' }
          if type(modes) == 'string' then
            if modes == '' then
              modes = { 'n', 'v', 'o', 'x', 'i', 'c', 's', 't', 'l', '!' }
            else
              modes = { modes }
            end
          end
          for _, m in ipairs(modes) do
            pcall(vim.keymap.del, m, lhs)
          end
        else
          -- Map key
          local key_opts = vim.deepcopy(key_spec)
          key_opts[1] = nil
          key_opts[2] = nil
          local mode = key_opts.mode or 'n'
          key_opts.mode = nil
          vim.keymap.set(mode, lhs, rhs, key_opts)
        end
      end
    end
  end

  -- 4. Schedule configuration
  local loader = later
  local is_lazy = spec.event or spec.cmd or spec.ft or spec.lazy

  if spec.load_if_args then
    loader = vim.fn.argc(-1) > 0 and now or later
  elseif not is_lazy then
    loader = now
  end
  loader(do_config)
end

--- Sets up a list of plugins.
---@param specs PluginSpec[]
function M.setup_all(specs)
  for _, spec in ipairs(specs) do
    M.setup(spec)
  end
end

return M
