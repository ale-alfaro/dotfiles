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

function M.setup(opts)
  vim.api.nvim_create_autocmd('User', {
    pattern = 'CodeCompanionChatCreated',
    callback = function(event)
      local chat = require('codecompanion').buf_get_chat(event.data.bufnr)
      if not chat then
        return
      end

      local rule_files = {
        '**/GEMINI.md',
        '**/AGENT*',
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
