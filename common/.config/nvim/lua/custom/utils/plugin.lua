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



--- Sets up a single plugin based on a spec.
---@param spec PluginSpec
function M.plugin_setup(spec)
  -- Run init function if it exists
  -- if spec.init then
  --   spec.init(spec)
  -- end
  -- vim.notify("Adding spec: " .. vim.inspect(spec))
  if type(spec) ~= 'table' then
    vim.notify('Plugin spec is not a table!', 'error')
    return
  end
  MiniDeps.later(function()
    local plugin_name = spec[1]:match '([^/]+)$'
    -- Strip .nvim if present for require path
    plugin_name = plugin_name:gsub('%.nvim$', '')
    local add_spec = { source = spec[1] }
    if spec.dependencies then
      add_spec.depends = spec.dependencies
    end
    MiniDeps.add(add_spec)
    local opts = spec.opts
    require(plugin_name).setup(opts)
    if spec.keys then
      local keys
      keys = spec.keys

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
  end)
end

--- Sets up a list of plugins.
---@param specs PluginSpec[]
function M.plugins_setup_all(specs)
  for _, spec in ipairs(specs) do
    M.plugin_setup(spec)
  end
end

return M
