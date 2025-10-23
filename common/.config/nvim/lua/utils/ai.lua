A = {}
A.parsers = require 'custom.ai.parsers'
A.prompts = require 'custom.ai.prompts'

local function add_dir_contents_as_context(chat, slash_commands, dir, globs, found_files)
  found_files = found_files or {}
  for _, rule in ipairs(globs) do
    local matched_files = vim.fn.glob(vim.fs.joinpath(dir, rule), true, true)
    for _, path in ipairs(matched_files) do
      if not vim.list_contains(found_files, path) then
        table.insert(found_files, path)
        slash_commands.context(chat, 'file', { path = path })
      end
    end
  end
end

local function change_model_callback(chat)
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

function A.setup(opts)
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
        system_prompt = A.prompts.sysprompt,
      }, -- opts
      keymaps = {
        close = {
          modes = { n = '<C-q>', i = '<C-q>' },
        },
        send = {
          modes = { n = '<C-s>', i = '<C-s>' },
        },
        change_model = {
          modes = { n = 'gm' },
          name = 'Change Model',
          callback = change_model_callback,
          description = 'Change the model for the current chat',
        },
      }, -- keymaps
    },
    inline = {
      adapter = 'gemini_cli',
    },
  }
  opts.prompt_library = A.prompts.library
  opts.memory = {
    gemini = {
      description = 'Collection of common files for all projects',
      files = { 'GEMINI.md', 'AGENTS.md' },
      is_default = true,
    },
    parsers = { gemini = A.parsers.gemini },
    opts = {
      chat = {
        enabled = true,
        condition = function(chat)
          return chat.adapter.type ~= 'acp'
        end,
        default_memory = 'gemini',
        default_params = 'watch',
      },
      show_defaults = true,
    },
  }
  require('codecompanion').setup(opts)

  vim.cmd [[cab cc CodeCompanion]]

  vim.api.nvim_create_autocmd('User', {
    pattern = 'CodeCompanionChatCreated',
    callback = function(event)
      local chat = require('codecompanion').buf_get_chat(event.data.bufnr)
      if not chat then
        return
      end

      local rule_files = {
        'GEMINI.md',
        'AGENT*',
        'README*',
      }

      local slash_commands = require 'codecompanion.strategies.chat.slash_commands'
      local buf_name = vim.api.nvim_buf_get_name(0)
      -- Fallback to current working directory if buffer is not saved
      local start_path = (buf_name ~= '' and vim.fs.dirname(buf_name)) or vim.fn.getcwd()

      if not start_path or start_path == '' then
        return
      end

      local found_files = {}
      add_dir_contents_as_context(chat, slash_commands, start_path, rule_files, found_files)

      local home_dir = vim.fn.expand '~'
      if start_path ~= home_dir then
        for dir in vim.fs.parents(start_path) do
          if dir == home_dir then
            break
          end
          add_dir_contents_as_context(chat, slash_commands, dir, rule_files, found_files)
          if vim.fn.isdirectory(vim.fs.joinpath(dir, '.git')) == 1 then
            break
          end
        end
      end
    end,
  })
end

return A
