---@class VimKeys
---@param mode string|string[] Mode "short-name" (see |nvim_set_keymap()|), or a list thereof.
---@param lhs string           Left-hand side |{lhs}| of the mapping.
---@param rhs string|function  Right-hand side |{rhs}| of the mapping, can be a Lua function.
---@param desc string
---@param opts? vim.keymap.set.Opts

---@class PluginSpec : vim.pack.Spec
---@field build? string|fun() Build command or function
---@field init? nil|fun(path: string, source: string, name: string) Configuration function
---@field opts? table|fun(spec: PluginSpec, opts: table): table Plugin options
---@field config? nil|fun(path: string, source: string, name: string) Configuration function
---@field keys? VimKeys[]|fun(): VimKeys[] Key mappings

M = {}
-- _G.Utils.new_autocmd({ "PackChanged" }, "*",
--   function(args)
--     local spec = args.data.spec
--     if spec and spec.name == "blink-cmp" and (args.data.kind == "update" or args.data.kind == "install") then
--       vim.notify("blink-cmp was installed or updated, building the rust library", vim.log.levels.INFO)
--
--       local source_dir = args.data.path
--       _G.Utils.cmd('cargo build --release', nil, { cwd = source_dir })
--     end
--   end,
--   {
--     desc = "Build the rust library after installing blink-cmp",
--   })

--- Sets up a single plugin based on a spec.
---@param spec vim.pack.Spec| string
function M.plugin_spec_add(spec, build, opts)
  vim.validate("spec", spec, { "string", "table" }, "Pack spec is malformed")
  if type(spec) == 'string' then
    spec = { src = src }
  end
  -- Check if it's in 'user/repo' format and not a full URL/path
  if not spec.src:match('^https?://') then
    spec.src = 'https://github.com/' .. spec.src
  end

  local plugin_name = spec.src:match '([^/]+)$'
  spec.name = plugin_name:gsub('%.nvim$', '')

  vim.pack.add({ spec })
  if build ~= nil then
    _G.Utils.new_autocmd({ "PackChanged" }, "*",
      function(args)
        local updated_spec = args.data.spec
        if updated_spec.name == plugin_name and (args.data.kind == "update" or args.data.kind == "install") then
          vim.notify(plugin_name .. " was installed or updated, doing the build_step", vim.log.levels.INFO)

          local source_dir = args.data.path
          _G.Utils.cmd(build, nil, { cwd = source_dir })
        end
      end,
      "Build step after installing" .. plugin_name)
  end
  ok, plug = pcall(require, spec.name)
  if not ok then
    _G.Utils.notify.error("Failed to load plugin " .. spec.name)
    return
  end
  opts = opts or {}
  plug.setup(opts)
end

return M
