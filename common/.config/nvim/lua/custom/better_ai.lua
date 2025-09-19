---@module "codecompanion"

---@type CodeCompanion.Chat.MemoryArgs
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
    gemini = require 'custom.ai.parsers.gemini',
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
--[[
--
--]]
return {
  'olimorris/codecompanion.nvim',
  dependencies = {
    'lalitmee/codecompanion-spinners.nvim', -- Spinner extension
    'nvim-lualine/lualine.nvim',
  },
  opts = function(_, opts)
    opts = opts or {}
    vim.api.nvim_create_user_command('CodeCompanionLogs', function()
      vim.cmd('split ' .. vim.fn.expand '~/.local/state/nvim/codecompanion.log')
    end, {
      desc = 'Open CodeCompanion log file',
    })
    opts.memory = memory_opts
    require('custom.ai.filepicker_context').setup(opts)
    opts.prompt_library = require 'custom.ai.prompts.prompt_library'
  end,
}
