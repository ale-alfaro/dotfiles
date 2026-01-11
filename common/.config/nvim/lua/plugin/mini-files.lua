---@module "mini.nvim"
---
---@alias FsType 'file'| 'directory' | 'symlink'
---@class MiniFilesFsEntry
---@field fs_type FsType
---@field path string  -full path of an entry.
---@field name string - - basename of an entry (including extension)
---
---@param entry MiniFilesFsEntry
---@return boolean
local filter = function(entry)
  return entry.fs_type ~= 'file' or entry.name ~= '.DS_Store'
end
--- Default prefix of file system entries
---
--- - If set up |mini.icons|, use |MiniIcons.get()| for "directory"/"file" category.
--- - Otherwise:
---     - For directory return fixed icon and "MiniFilesDirectory" group name.
---     - For file try to use `get_icon()` from 'nvim-tree/nvim-web-devicons'.
---       If missing, return fixed icon and 'MiniFilesFile' group name.
---
---@param fs_entry MiniFilesFsEntry
---@return string, string
local prefix = function(fs_entry)
  -- Prefer 'mini.icons'
  local filetype = vim.fn.getftype(fs_entry.path)
  if filetype == 'link' then
    return VimRc.icons.os.Interface, 'MiniFilesFile'
  else
    local category = fs_entry.fs_type == 'directory' and 'directory' or 'file'
    if category == 'directory' then
      return VimRc.icons.os.Folder .. ' ', 'MiniFilesDirectory'
    else
      if MiniIcons ~= nil then
        local icon, hl = MiniIcons.get(category, fs_entry.path)
        return icon .. ' ', hl
      else
        -- Try falling back to 'nvim-web-devicons'
        return ' ', 'MiniFilesFile'
      end
    end
  end
end

--- Default sort of file system entries
---
--- Sort directories and files separately (alphabetically ignoring case) and
--- put directories first.
---@param entries MiniFilesFsEntry[]
---@return MiniFilesFsEntry[]
local sort = function(entries)
  local function compare_alphanumerically(e1, e2)
    -- Put directories first.
    if e1.is_dir and not e2.is_dir then
      return true
    end
    if not e1.is_dir and e2.is_dir then
      return false
    end
    -- Order numerically based on digits if the text before them is equal.
    if e1.pre_digits == e2.pre_digits and e1.digits ~= nil and e2.digits ~= nil then
      return e1.digits < e2.digits
    end
    -- Otherwise order alphabetically ignoring case.
    return e1.lower_name < e2.lower_name
  end

  local sorted = vim.tbl_map(function(entry)
    local pre_digits, digits = entry.name:match '^(%D*)(%d+)'
    if digits ~= nil then
      digits = tonumber(digits)
    end

    return {
      fs_type = entry.fs_type,
      name = entry.name,
      path = entry.path,
      lower_name = entry.name:lower(),
      is_dir = entry.fs_type == 'directory',
      pre_digits = pre_digits,
      digits = digits,
    }
  end, entries)
  table.sort(sorted, compare_alphanumerically)
  -- Keep only the necessary fields.
  return vim.tbl_map(function(x)
    return { name = x.name, fs_type = x.fs_type, path = x.path }
  end, sorted)
end
-- Add common bookmarks for every explorer. Example usage inside explorer:
-- - `'c` to navigate into your config directory
-- - `g?` to see available bookmarks
local add_marks = function()
  --
  MiniFiles.set_bookmark('c', vim.fn.stdpath 'config', { desc = 'Config' })
  local plugin_dir = vim.fn.stdpath 'data' .. '/site/pack/core/opt'
  MiniFiles.set_bookmark('p', plugin_dir, { desc = 'Plugins' })
  MiniFiles.set_bookmark('w', vim.fn.getcwd, { desc = 'Working directory' })
  local envs = { o = 'OBSIDIAN_HOME', C = 'XDG_CONFIG_HOME', z = 'ZEPHYR_BASE', W = 'WEST_TOPDIR' }
  for key, name in pairs(envs) do
    local env = ENV(name)
    if env and vim.uv.fs_stat(env) then
      MiniFiles.set_bookmark(key, env, { desc = name })
    end
  end
end
_G.new_user_autocmd(add_marks, 'MiniFilesExplorerOpen', 'Add bookmarks')

require('mini.files').setup {
  windows = {

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
  content = {

    filter = filter,
    sort = sort,
    prefix = prefix,
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

-- Yank in register full path of entry under cursor
local yank_path = function(path)
  vim.fn.setreg(vim.v.register, path)
end

vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesBufferCreate',
  callback = function(args)
    local b = args.data.buf_id
    local cur_line = vim.fn.line '.'
    -- local buf = vim.api.nvim_get_current_buf()
    local fs_entry
    if b == nil or b == 0 then
      b = vim.api.nvim_get_current_buf()
      fs_entry = MiniFiles.get_fs_entry(b, cur_line)
    else
      fs_entry = MiniFiles.get_fs_entry()
    end
    -- if fs_entry then
    --   vim.notify('fs_entry_buf: ' .. fs_entry.path)
    -- end
    -- local fs_entry = MiniFiles.get_fs_entry()
    if not fs_entry or not vim.uv.fs_stat(fs_entry.path) then
      return
    end
    -- vim.notify('fs_entry: ' .. fs_entry.path)

    local file = nil
    local dir = nil
    if fs_entry.fs_type == 'file' then
      file = fs_entry.path
      dir = vim.fs.dirname(file)
    elseif fs_entry.fs_type == 'directory' then
      dir = fs_entry.path
    else
      return
    end
    vim.keymap.set('n', 'g~', function()
      if dir then
        vim.fn.chdir(dir)
      end
    end, { buffer = b, desc = 'Set cwd' })
    vim.keymap.set('n', 'gy', function()
      yank_path(file or dir)
    end, { buffer = b, desc = 'Yank path' })
    vim.keymap.set('n', 'gX', function()
      vim.ui.open(file or dir)
    end, { buffer = b, desc = 'OS open' })
  end,
})

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
