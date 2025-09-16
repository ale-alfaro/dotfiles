return {

  setup = function()
    local function log(message)
      local log_file = vim.fn.expand '~/.local/state/nvim/codecompanion.log'
      local f = io.open(log_file, 'a')
      if f then
        f:write(message .. '\n')
        f:close()
      end
    end

    vim.api.nvim_create_user_command('CodeCompanionLogs', function()
      vim.cmd('split ' .. vim.fn.expand '~/.local/state/nvim/codecompanion.log')
    end, {
      desc = 'Open CodeCompanion log file',
    })

    -- vim.api.nvim_create_user_command('CodeCompanionTools', function()
    --   local cc = require('lazy.core.config').spec.plugins['codecompanion.nvim']
    --   if not cc or not cc.opts then
    --     vim.notify('CodeCompanion config not found', vim.log.levels.ERROR)
    --     return
    --   end
    --
    --   local tools = {}
    --   -- Assumed base tools from vectorcode
    --   vim.list_extend(tools, { 'ls', 'vectorise', 'query' })
    --
    --   if
    --     cc.opts
    --     and cc.opts.extensions
    --     and cc.opts.extensions.vectorcode
    --     and cc.opts.extensions.vectorcode.opts
    --     and cc.opts.extensions.vectorcode.opts.tool_group
    --     and cc.opts.extensions.vectorcode.opts.tool_group.extras
    --   then
    --     vim.list_extend(tools, cc.opts.extensions.vectorcode.opts.tool_group.extras)
    --   end
    --
    --   if cc.opts and cc.opts.strategies and cc.opts.strategies.chat and cc.opts.strategies.chat.tools then
    --     for tool_name, _ in pairs(cc.opts.strategies.chat.tools) do
    --       table.insert(tools, tool_name)
    --     end
    --   end
    --
    --   local log_message = 'Available tools: ' .. table.concat(tools, ', ')
    --
    --   log(log_message)
    --   vim.notify(log_message, vim.log.levels.INFO)
    -- end, {
    --   desc = 'List and log available CodeCompanion tools',
    -- })

    local spinner = require 'custom.ai_fidget_spinner'
    spinner:init()
  end,
}
