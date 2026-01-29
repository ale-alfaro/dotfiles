---@module "codecompanion"
---@class M
local M = {}

---@class FsEntry
---@field fs_type 'file'|'directory'|nil
---@field path string|nil

---@return CodeCompanion.Chat|nil
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

---@param chat CodeCompanion.Chat
---@param fs_entry FsEntry
local function add_fs_entry_to_chat(chat, fs_entry)
  if not fs_entry or not fs_entry.fs_type or not fs_entry.path then
    vim.notify('Invalid file system entry.', vim.log.levels.WARN)
    return
  end

  ---@type CodeCompanion.SlashCommands
  local slash_commands = require 'codecompanion.strategies.chat.slash_commands'

  if fs_entry.fs_type == 'directory' then
    -- Recursively traverse the directory
    ---@type string[]|nil
    local files = vim.fn.globpath(fs_entry.path, '*', false, true)
    if files and vim.islist(files) then
      for _, path in ipairs(files) do
        slash_commands.context(chat, 'file', { path = path })
      end
    end
  elseif fs_entry.fs_type == 'file' then
    slash_commands.context(chat, 'file', { path = fs_entry.path })
  end
end

-- MEMORY -------------------------------------------------------------------
---@class MemoryGroup
---@field description string
---@field files string[]
---@field is_default boolean|nil
---@field parser string|nil
---@field enabled boolean|nil
---

function M.setup(opts)
  ----- Autocmds -----
  vim.api.nvim_create_autocmd('User', {
    pattern = 'CodeCompanionChatCreated',
    callback = function(event)
      local chat = require('codecompanion').buf_get_chat(event.data.bufnr)
      if not chat then
        return
      end

      ---@type CodeCompanion.SlashCommands
      local slash_commands = require 'codecompanion.strategies.chat.slash_commands'
      local root_dir = MiniMisc.find_root(0, { '.git' })
      if root_dir then
        local matched_files = vim.fn.glob(root_dir .. '/' .. 'README*', true, true)
        for _, path in ipairs(matched_files) do
          slash_commands.context(chat, 'file', { path = path })
        end
      end
    end,
  })

  VimRc.codecompanion_add_context_from_explorer = function()
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
end

return M
