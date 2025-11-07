---@module "mini.files"
---@module "codecompanion"

local M = {}

local function get_chat()
  local codecompanion = require 'codecompanion'
  local chat = codecompanion.last_chat()

  -- Create chat if none exists
  if not chat then
    chat = codecompanion.chat()
    if not chat then
      vim.notify 'Couldnt find chat while adding context from explorer'
      return nil
    end
  end
  return chat
end

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

local function add_fs_entry_to_chat(chat, fs_entry)
  if not fs_entry or not fs_entry.fs_type or not fs_entry.path then
    vim.notify('Invalid file system entry.', vim.log.levels.WARN)
    return
  end

  local slash_commands = require 'codecompanion.strategies.chat.slash_commands'
  if fs_entry.fs_type == 'directory' then
    -- Recursively traverse the directory
    local files = vim.fn.globpath(fs_entry.path, '*', false, true)
    if files and vim.islist(files) then
      for _, path in ipairs(files) do
        slash_commands.context(chat, 'file', { path = path })
      end
    end
    -- vim.notify('Added all files in ' .. path .. ' to chat.')
  elseif fs_entry.fs_type == 'file' then
    slash_commands.context(chat, 'file', { path = fs_entry.path })
    -- Add the single file
    -- vim.notify('Added ' .. path .. ' to chat.')
  end
end

function M.add_context_from_explorer_visual(buf_id)
  if vim.fn.mode() ~= 'V' then
    return
  end
  --
  local line_1, line_2 = vim.fn.line 'v', vim.fn.line '.'
  local from_line, to_line = math.min(line_1, line_2), math.max(line_1, line_2)
  -- Compute which entries to go in: all files and only last directory
  local files, path = {}, nil
  local MiniFiles = require 'mini.files'
  for i = from_line, to_line do
    local fs_entry = MiniFiles.get_fs_entry(buf_id, i) or {}
    if fs_entry.fs_type == 'file' then
      table.insert(files, fs_entry.path)
    end
    if fs_entry.fs_type == 'directory' then
      path = fs_entry.path
    end
    if fs_entry.fs_type == nil and fs_entry.path == nil then
      local entry = vim.inspect(vim.get_bufline(buf_id, i))
      vim.notify('Line ' .. entry .. ' does not have proper format. Did you modify without synchronization?', vim.log.levels.WARN)
    end
    if fs_entry.fs_type == nil and fs_entry.path ~= nil then
      local path_resolved = vim.fn.resolve(fs_entry.path)
      local symlink_info = path_resolved == fs_entry.path and '' or (' Looks like miscreated symlink (resolved to ' .. path_resolved .. ').')
      vim.notify('Path ' .. fs_entry.path .. ' is not present on disk.' .. symlink_info, vim.log.levels.WARN)
    end
  end

  local chat = get_chat()
  if not chat then
    vim.notify('Couldnt get chat', vim.log.levels.ERROR)
    return
  end
  local slash_commands = require 'codecompanion.strategies.chat.slash_commands'
  for _, file_path in ipairs(files) do
    slash_commands.context(chat, 'file', { path = file_path })
  end

  if path ~= nil then
    add_dir_contents_as_context(chat, slash_commands, path, { '*' })
  end
  return [[<C-\><C-n>]]
end
-- local get_visual_selection = function()
--   -- React only on linewise mode, as others can be used for editing
--   -- Schedule actions because they are not allowed inside expression mapping
--   vim.schedule(function()
--     local explorer = vim.explorer_get()
--     explorer = vim.explorer_go_in_range(explorer, buf_id, from_line, to_line)
--     vim.explorer_refresh(explorer)
--   end)
--
--   -- Go to Normal mode. '\28\14' is an escaped version of `<C-\><C-n>`.
-- end
function M.add_context_from_explorer()
  local chat = get_chat()
  if not chat then
    vim.notify('Couldnt get chat', vim.log.levels.ERROR)
    return
  end
  local MiniFiles = require 'mini.files'
  local bufnr = vim.api.nvim_get_current_buf()
  local fs_entry = MiniFiles.get_fs_entry(bufnr)
  add_fs_entry_to_chat(chat, fs_entry)
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

local vectorcode = {
  description = 'Run VectorCode to retrieve the project context.',
  callback = function()
    return require('vectorcode.integrations').codecompanion.chat.make_tool('query', {
      default_num = 15,
      use_lsp = false,
      auto_submit = { ls = true, query = true },
      ls_on_start = false,
    })
  end,
}

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
  opts.memory = {
    gemini = {
      description = 'Collection of common files for all projects',
      files = { 'GEMINI.md', 'AGENTS.md' },
      is_default = true,
    },
    parsers = { gemini = require 'custom.ai.parsers.gemini' },
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
  vim.api.nvim_create_user_command('CodeCompanionTools', get_tool_list, {
    desc = 'List and log available CodeCompanion tools',
  })

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

return M
