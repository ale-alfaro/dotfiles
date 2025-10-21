---@module "mini.deps"
local M = {}

---@param name string
-- function M.get_plugin(name)
--   local plugins = MiniDeps.get_session()
--
-- end
--
-- ---@param name string
-- ---@param path string?
-- function M.get_plugin_path(name, path)
--   local plugin = M.get_plugin(name)
--   path = path and "/" .. path or ""
--   return plugin and (plugin.dir .. path)
-- end
--
-- ---@param plugin string
-- function M.has(plugin)
--   return M.get_plugin(plugin) ~= nil
-- end
function M.nmap(lhs, rhs, desc, opts)
  -- See `:h vim.keymap.set()`
  opts = opts or {}
  opts.desc = desc
  vim.keymap.set('n', lhs, rhs, opts)
end

function M.nmapleader(suffix, rhs, desc, opts)
  opts = opts or {}
  opts.desc = desc
  vim.keymap.set('n', '<Leader>' .. suffix, rhs, opts)
end

function M.xmapleader(suffix, rhs, desc)
  vim.keymap.set('x', '<Leader>' .. suffix, rhs, { desc = desc })
end

local gr = vim.api.nvim_create_augroup('custom-config', {})
function M.new_autocmd(event, pattern, callback, desc)
  local opts = { group = gr, callback = callback }
  if pattern ~= nil then
    opts.pattern = pattern
  end
  if desc ~= nil then
    opts.desc = desc
  end
  vim.api.nvim_create_autocmd(event, opts)
end


---@param on_attach fun(client:vim.lsp.Client, buffer)
---@param name? string
function M.lsp_on_attach(on_attach, name)
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
function M.cmd(cmd, cb, opts)
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

M.notify = require 'utils.notify'
M.pack = require 'utils.pack'
M.keymaps = require 'utils.keymaps'
M.treesitter = require 'utils.treesitter'
M.mini = require 'utils.mini'

return M
