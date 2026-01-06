---@module "mini.nvim"
---
-- Add common bookmarks for every explorer. Example usage inside explorer:
-- - `'c` to navigate into your config directory
-- - `g?` to see available bookmarks
local add_marks = function()
  local env_paths = _G.fetch_env_paths()
  for name, p in pairs(env_paths) do
    if name and vim.uv.fs_stat(p) ~= nil then
      local key = vim.fn.slice(name, 0, 1)
      MiniFiles.set_bookmark(key, p, { desc = name })
    end
  end
  MiniFiles.set_bookmark('c', vim.fn.stdpath 'config', { desc = 'Config' })
  local plugin_dir = vim.fn.stdpath 'data' .. '/site/pack/core/opt'
  MiniFiles.set_bookmark('p', plugin_dir, { desc = 'Plugins' })
  MiniFiles.set_bookmark('.', vim.fn.expand '$HOME' .. '/dotfiles', { desc = 'Dotfiles' })
  MiniFiles.set_bookmark('w', vim.fn.getcwd, { desc = 'Working directory' })
end
_G.new_user_autocmd(add_marks, 'MiniFilesExplorerOpen', 'Add bookmarks')

require('mini.files').setup {
  windows = {

    -- Maximum number of windows to show side by side
    max_number = math.huge,
    -- Whether to show preview of file/directory under cursor
    preview = true,
    -- Width of focused window
    width_focus = 50,
    -- Width of non-focused window
    width_nofocus = 15,
    --
    -- Width of preview window
    width_preview = 25,
  },
  options = {
    permanent_delete = false,
    use_as_default_explorer = true,
  },

  mappings = {
    close = 'q',
    -- go_in       = 'l',
    go_in = '<Right>',
    go_in_plus = 'L',
    go_out = 'h',
    -- go_out_plus = 'H',
    go_out_plus = '<Left>',
    mark_goto = "'",
    mark_set = 'm',
    reset = '<BS>',
    reveal_cwd = '@',
    show_help = 'g?',
    synchronize = '=',
    trim_left = '<',
    trim_right = '>',
  },
}
-- local show_dotfiles = true
-- local filter_show = function(fs_entry)
--   return true
-- end
-- local filter_hide = function(fs_entry)
--   return not vim.startswith(fs_entry.name, '.')
-- end
--
-- local toggle_dotfiles = function()
--   show_dotfiles = not show_dotfiles
--   local new_filter = show_dotfiles and filter_show or filter_hide
--   require('mini.files').refresh { content = { filter = new_filter } }
-- end

-- Yank in register full path of entry under cursor
local yank_path = function()
  local path = (MiniFiles.get_fs_entry() or {}).path
  if path == nil then
    return vim.notify 'Cursor is not on valid entry'
  end
  vim.fn.setreg(vim.v.register, path)
end

-- Keep track of when the explorer is open to disable format on save.

-- Open path with system default handler (useful for non-text files)
local ui_open = function()
  vim.ui.open(MiniFiles.get_fs_entry().path)
end
-- However, some parts (like window title and height) of window config are later
-- updated internally. Use `MiniFilesWindowUpdate` event for them: >lua

_G.new_user_autocmd(function(args)
  vim.g.minifiles_active = true
  local buf_id = args.data.buf_id
  -- vim.keymap.set('n', '.', toggle_dotfiles, { buffer = buf_id, desc = 'Toggle hidden files' })
  vim.keymap.set('n', 'gy', yank_path, { buffer = buf_id, desc = 'Yank path' })
  vim.keymap.set('n', 'gX', ui_open, { buffer = buf_id, desc = 'OS open' })
end, 'MiniFilesBufferCreate', 'MiniFiles local keymaps')

--
_G.new_user_autocmd(function(event)
  local from = event.data.from
  local to = event.data.to
  local changes = {
    files = { {
      oldUri = vim.uri_from_fname(from),
      newUri = vim.uri_from_fname(to),
    } },
  }

  local clients = vim.lsp.get_clients()
  for _, client in ipairs(clients) do
    if client:supports_method 'workspace/willRenameFiles' then
      local resp = client:request_sync('workspace/willRenameFiles', changes, 1000, 0)
      if resp and resp.result ~= nil then
        vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding)
      end
    end
  end
  for _, client in ipairs(clients) do
    if client:supports_method 'workspace/didRenameFiles' then
      client:notify('workspace/didRenameFiles', changes)
    end
  end
end, 'MiniFilesActionRename', 'Rename Files')
