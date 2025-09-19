---@module "codecompanion"
-- ADD ANY NEW ADAPTERS HERE
--   http = {
--     ['Gemini'] = function()
--       return require('codecompanion.adapters').extend('gemini', {
--         name = 'Gemini',
--         schema = { model = { default = 'gemini-2.5-flash' } },
--       })
--     end,
--     ['LlamaCPP'] = function()
--       return require('codecompanion.adapters').extend('openai_compatible', {
--         env = {
--           url = 'http://127.0.0.1:8080',
--           api_key = 'TERM',
--           chat_url = '/v1/chat/completions',
--         },
--         schema = { cache_prompt = { default = true, mapping = 'parameters' } },
--       })
--     end,
--     ['Ollama'] = function()
--       return require('codecompanion.adapters').extend('ollama', {
--         env = {
--           url = os.getenv 'OLLAMA_HOST',
--           api_key = 'TERM',
--         },
--         name = 'Ollama',
--         schema = {
--           num_ctx = { default = 64000 },
--           -- model = { default = {"qwen3:8b-q4_K_M-dynamic-thinking"} },
--           -- think = { default = true },
--         },
--       })
--     end,
--   },
--
local M = {}

function M.change_model_callback(chat)
  local util = require 'codecompanion.utils'

  local function select_opts(prompt, conditional)
    return {
      prompt = prompt,
      kind = 'codecompanion.nvim',
      format_item = function(item)
        if conditional == item then
          return '* ' .. item
        end
        return '  ' .. item
      end,
    }
  end

  if chat.adapter.type == 'http' then
    vim.notify 'Not supported'
    return
    -- Select a command
  elseif chat.adapter.type == 'acp' then
    local commands = chat.adapter.commands
    if not commands or vim.tbl_count(commands) < 2 then
      return
    end

    commands = vim
      .iter(commands)
      :map(function(key, _)
        if type(key) == 'string' then
          return key
        end
      end)
      :filter(function(key)
        return key ~= 'selected'
      end)
      :totable()
    table.sort(commands)

    vim.ui.select(commands, select_opts('Select a Command', commands), function(selected_command)
      if not selected_command then
        return
      end
      local selected = chat.adapter.commands[selected_command]
      chat.adapter.commands.selected = selected
      util.fire('ChatModel', { bufnr = chat.bufnr, model = selected })
      chat:update_metadata()
    end)
  end
end

return M
