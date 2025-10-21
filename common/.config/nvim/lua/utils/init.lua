---@module "mini.deps"


---@param msg string|string[]
---@param level string
---@param comment string
local function notify(msg, level)
  msg = type(msg) == 'table' and table.concat(msg, '\n') or msg --[[@as string]]
  msg = vim.trim(msg)
  vim.notify(msg, level)
end

---@param msg string|string[]
---@param opts? snacks.notify.Opts
function _G.warn(msg, opts)
  return notify(msg, 'WARN')
end

---@param msg string|string[]
---@param opts? snacks.notify.Opts
function _G.info(msg, opts)
  return notify(msg, 'INFO')
end

---@param msg string|string[]
---@param opts? snacks.notify.Opts
function _G.error(msg, opts)
  return notify(msg, 'ERROR')
end


---@param on_attach fun(client:vim.lsp.Client, buffer)
---@param name? string
function _G.lsp_on_attach(on_attach, name)
  return vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
      local buffer = args.buf ---@type number
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and (not name or client.name == name) then
        return on_attach(client, buffer)
      end
    end,
  })
end
---@param cmd string|string[]
---@param cb fun(output: string[], code: number)
---@param opts? {env?: table<string, string>, cwd?: string}
function _G.run_cmd(cmd, cb, opts)
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
    vim.notify(('Failed to start job `%s`'):format(cmd), 'error')
  end
  return id > 0 and id or nil
end

-- Tracks defined keymaps to prevent duplicates.
-- Key is a unique string like "n:<leader>ff".
_G.keymap_registry = {}

---@param lhs string
---@param mode string
local function keymap_encode(lhs, mode)
  return mode .. ":" .. lhs
end

---@param lhs string
---@param mode? string
local function keymap_have(lhs, mode)
  local check_mode = mode or "n"
  return _G.keymap_registry[keymap_encode(lhs, check_mode)] ~= nil
end

local function add_ft_keymaps(keys)
  vim.api.nvim_create_autocmd("FileType", {
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
--- Defines a list of keymaps, preventing duplicates and handling conditions.
---@param keymaps KeymapSpec[]
function _G.keymaps_define(keymaps)
  for _, spec in ipairs(keymaps) do
    -- Skip if the condition is not met
    if spec.cond == false or (type(spec.cond) == "function" and not spec.cond()) then
      goto continue
    end

    if spec.ft then
      add_ft_keymaps(spec)
      goto continue
    end

    local modes = spec.mode or "n"
    if type(modes) == "string" then
      modes = { modes }
    end

    for _, mode in ipairs(modes) do
      local id = keymap_encode(spec.lhs, mode)
      if _G.keymap_registry[id] then
        vim.notify("Keymap already defined and was skipped: " .. id, vim.log.levels.WARN)
        goto continue_inner
      end

      if spec.rhs == false or spec.rhs == nil then
        -- Unmap the key
        pcall(vim.keymap.del, mode, spec.lhs)
      else
        -- Set the keymap
        vim.keymap.set(mode, spec.lhs, spec.rhs, spec.opts or {})
      end

      -- Mark this keymap as handled
      _G.keymap_registry[id] = true
      ::continue_inner::
    end
    ::continue::
  end
end
_G.added_plugins = {}
function _G.plug(p)
return {
	src = 'https://github.com/' .. p,
	name = p:match '%S+/(%S+)'
}
end

function _G.plug_spec(spec)
  table.insert(_G.added_plugins, spec)
	return vim.iter(spec):map(function(p) return _G.plug(p) end):totable()
end

--- @class PluginFilter
--- @field active boolean Whether plugin was added via |vim.pack.add()| to current session.

---@param names string[]
---@param active_only boolean?
local function get_plugins(active_only)
  local plugins = vim.pack.get()
  if #plugins > 0 then
      return vim.iter(plugins):filter(function(plug)
		if active_only then
		  return plug.active
		else
			return true
		end
	      end):map(function(plug)
		return plug.name
	      end):totable()
  end
end
--- Updates one or more plugins.
--- @param plugin_names? string|string[] Optional: A single plugin name or a list of plugin names to update.
--- If omitted, all plugins will be updated.
function _G.pack_update()
  local plugins_to_update = {}
  local not_found_plugins = {}
  local plugins = get_plugins(true)
  if plugins then
      vim.pack.update(plugins)
  end
end

function _G.pack_clean()
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
		print("No unused plugins.")
		return
	end

	local choice = vim.fn.confirm("Remove unused plugins?", "&Yes\n&No", 2)
	if choice == 1 then
		vim.pack.del(unused_plugins)
	end
end
