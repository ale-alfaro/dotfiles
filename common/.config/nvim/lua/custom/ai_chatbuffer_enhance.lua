local function log_to_file(message)
  local log_file = vim.fn.expand '~/.local/state/nvim/codecompanion.log'
  local f = io.open(log_file, 'a')
  if f then
    f:write(message .. '\n')
    f:close()
  end
end
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

-- MEMORY -------------------------------------------------------------------
local memory_opts = {
  gemini = {
    description = 'Collection of common files for all projects',
    files = {
      'GEMINI.md',
      'AGENTS.md',
      -- { path = 'GEMINI.md', parser = 'gemini' },
      -- { path = '~/.gemini/GEMINI.md', parser = 'gemini' },
    },
    is_default = true,
  },
  parsers = {
    gemini = require 'custom.helpers.parsers.gemini',
  },
  opts = {
    chat = {
      enabled = true, -- Automatically add memory to new chat buffers?

      ---Function to determine if memory should be added to a chat buffer
      ---This requires `enabled` to be true
      ---@param chat CodeCompanion.Chat
      ---@return boolean
      condition = function(chat)
        return chat.adapter.type ~= 'acp'
      end,

      default_memory = 'gemini', -- The memory groups to load
      default_params = 'watch', -- watch|pin - when adding a buffer to the chat
    },
    show_defaults = true, -- Show the default memory files in the action palette?
  },
}

return {
  'olimorris/codecompanion.nvim',
  opts = function(_, opts)
    opts = opts or {}
    -- opts.strategies.chat.tools = {
    --   vectorcode = {
    --     description = 'Run VectorCode to retrieve the project context.',
    --     callback = function()
    --       return require('vectorcode.integrations').codecompanion.chat.make_tool('query', {
    --         default_num = 15,
    --         use_lsp = true,
    --         auto_submit = { ls = true, query = true },
    --         ls_on_start = false,
    --       })
    --     end,
    --   },
    -- }
    --
    -- slash_commands = {
    --   codebase = require('vectorcode.integrations').codecompanion.chat.make_slash_command(),
    -- },
    vim.api.nvim_create_user_command('CodeCompanionLogs', function()
      vim.cmd('split ' .. vim.fn.expand '~/.local/state/nvim/codecompanion.log')
    end, {
      desc = 'Open CodeCompanion log file',
    })

    vim.api.nvim_create_user_command('CodeCompanionTools', get_tool_list, {
      desc = 'List and log available CodeCompanion tools',
    })

    vim.cmd [[cab cc CodeCompanion]]
    -- vim.notify(vim.inspect(opts))
    opts.memory = memory_opts
    -- opts.display.chat.show_settings = true
    local vecprompts = require 'custom.prompts.vectorcode'
    opts.prompt_library = require 'custom.prompts.prompt_library'
    vim.tbl_deep_extend('force', opts.prompt_library, vecprompts)
    local spinner = require 'custom.helpers.ai_fidget_spinner'
    spinner:init()
  end,
}
