C = {}

function C.change_model_callback(chat)
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

function C.setup(opts)
  local keymaps = require 'codecompanion.strategies.chat.keymaps'

  opts.strategies = {
    chat = {
      adapter = 'gemini_cli',
      model = 'gemini-2.5-pro',
      keymaps = {
        next_chat = { modes = { n = '<C-n>', i = '<C-n>' } },
        clear = { modes = { n = '<C-x>', i = '<C-x>' } },
        yank_code = { modes = { n = '<C-y>', i = '<C-y>' } },
        fold_code = { modes = { n = 'zc' } },
        goto_file_under_cursor = { modes = { n = 'gf' } },
        options = {
          modes = { n = '<C-h>', i = '<C-h>' },
          callback = function()
            keymaps.options.callback()
            vim.defer_fn(function()
              vim.cmd.stopinsert()
              -- Ensure options window is wide enough for content
              vim.api.nvim_win_set_width(0, math.min(160, vim.o.columns))
            end, 1)
          end,
        },
        pin = { modes = { n = '<Leader>rp' } },
        watch = { modes = { n = '<Leader>rw' } },
        system_prompt = { modes = { n = '<Leader>ts' } },
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
      slash_commands = require 'custom.ai.prompts.slash_commands',
    }, --- chat
  }
end

return M
