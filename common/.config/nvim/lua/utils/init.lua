local M = {}

setmetatable(M, {
  __index = function(t, k)
    -- if M.deprecated[k] then
    --   return M.deprecated[k]()
    -- end
    ---@diagnostic disable-next-line: no-unknown
    t[k] = require('utils.' .. k)
    -- M.deprecated.decorate(k, t[k])
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
function _G.error(msg)
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
---@class KeymapSpec
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

local function add_ft_keymaps(keys)
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
--- Defines a list of keymaps, preventing duplicates and handling conditions.
---@param keymaps KeymapSpec[]
function _G.keymaps_define(keymaps)
  for _, spec in ipairs(keymaps) do
    -- Skip if the condition is not met
    if spec.cond == false or (type(spec.cond) == 'function' and not spec.cond()) then
      goto continue
    end

    if spec.ft then
      add_ft_keymaps(spec)
      goto continue
    end

    local modes = spec.mode or 'n'
    if type(modes) == 'string' then
      modes = { modes }
    end

    for _, mode in ipairs(modes) do
      local id = keymap_encode(spec.lhs, mode)
      if M.keymap_registry[id] then
        vim.notify('Keymap already defined and was skipped: ' .. id, vim.log.levels.WARN)
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
      M.keymap_registry[id] = true
      ::continue_inner::
    end
    ::continue::
  end
end

M.added_plugins = {}

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
local function create_plugin_build_hook(plug_name, build)
  vim.api.nvim_create_autocmd('PackChanged', {
    pattern = '*',
    callback = function(ev)
      _G.info(ev.data)
      _G.info(ev.data.spec.name .. ' has been updated.')
      if ev.data.spec.name == plug_name and ev.data.spec.kind ~= 'deleted' then
        if type(build) == 'string' then
          run_build_cmd(build, function(output, retcode)
            if retcode ~= 0 then
              _G.error('Build command failed for plugin ' .. plug_name)
              _G.error('Output:' .. output)
            end
          end, { cwd = ev.data.path })
          -- vim.system(vim.fn.split(build), { cwd = ev.data.path}):wait()
        elseif type(build) == 'function' then
          vim.schedule(build)
        else
          _G.error('Build hook for plugin ' .. plug_name .. ' is not a string nor function')
        end
      end
    end,
  })
end
function _G.plug(p, build)
  local plug_name = p:match '%S+/(%S+)'
  if build then
    create_plugin_build_hook(plug_name, build)
  end
  return {
    src = 'https://github.com/' .. p,
    name = plug_name,
  }
end

---@param spec string[]
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

--
return M
