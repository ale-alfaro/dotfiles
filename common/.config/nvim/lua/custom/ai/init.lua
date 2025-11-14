---@module "codecompanion"

local M = {}


local function get_tool_list()
  ---@class CodeCompanion.Tools
  local tools = require 'codecompanion.strategies.chat.tools'
  local ok, is_loaded = pcall(function()
    return tools:refresh()
  end)
  if not ok then
    vim.notify("Couldn't check if tool_registry is loaded!", vim.log.levels.ERROR)
    return
  end

  if is_loaded then
    local log_message = 'Available tools: ' .. vim.inspect(tools.tools_config)
    vim.notify(log_message, vim.log.levels.INFO)
  else
    vim.notify('No tools loaded into chat', vim.log.levels.WARN)
  end
end
--
-- local vectorcode = {
--   description = 'Run VectorCode to retrieve the project context.',
--   callback = function()
--     return require('vectorcode.integrations').codecompanion.chat.make_tool('query', {
--       default_num = 15,
--       use_lsp = false,
--       auto_submit = { ls = true, query = true },
--       ls_on_start = false,
--     })
--   end,
-- }


function M.setup(opts)
  require('custom.ai.adapters').setup(opts)
  require('custom.ai.memory').setup(opts)

  require('custom.ai.prompts').setup(opts)
  ---@type CodeCompanion
  require('codecompanion').setup(opts)

  vim.cmd [[cab cc CodeCompanion]]
  vim.api.nvim_create_user_command('CodeCompanionTools', get_tool_list, {
    desc = 'List and log available CodeCompanion tools',
  })
end

return M
