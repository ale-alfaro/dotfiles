local M = {}



---@param name string
-- function M.get_plugin(name)
--   return require("lazy.core.config").spec.plugins[name]
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

M.format = require("custom.utils.format")
M.lsp = require("custom.utils.lsp")
M.mini = require("custom.utils.mini")
M.plugin = require("custom.utils.plugin")
M.treesitter = require("custom.utils.treesitter")

return M
