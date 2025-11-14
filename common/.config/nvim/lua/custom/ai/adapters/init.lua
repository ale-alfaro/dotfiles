M = {}

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

function M.setup(opts)
  opts.adapters = {
    acp = require('custom.ai.adapters.acp'),
    http = require('custom.ai.adapters.http'),
  }

  opts.strategies = {
    chat = {
      adapter = 'gemini_cli',
      roles = {
        ---@type string|fun(adapter: CodeCompanion.HTTPAdapter|CodeCompanion.ACPAdapter): string
        llm = function(adapter)
          if adapter.model then
            return string.format('%s (%s)', adapter.formatted_name, adapter.model.name)
          else
            return adapter.formatted_name
          end
        end,
      },
      opts = {
        ---@type string|fun(path: string)
        system_prompt = require 'custom.ai.prompts.sysprompt',
      }, -- opts
      keymaps = {
        close = {
          modes = { n = '<C-q>', i = '<C-q>' },
        },
        send = {
          modes = { n = '<C-s>', i = '<C-s>' },
        },
        change_model = {
          modes = { n = '<C-m>' },
          name = 'Change Model',
          callback = M.change_model_callback,
          description = 'Change the model for the current chat',
        },
      }, -- keymaps
    },
    inline = {
      adapter = 'gemini_cli',
    },
  }
end

return M
