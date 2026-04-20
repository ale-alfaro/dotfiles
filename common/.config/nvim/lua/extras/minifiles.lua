---@module 'mini.files'
---
---
vim.api.nvim_set_hl(0, 'MiniFilesSymLink', { link = 'PmenuExtra' })
---@param fs_entry MiniFilesFsEntry
---@return string, string
local prefix = function(fs_entry)
  -- Prefer 'mini.icons'
  local filetype = vim.fn.getftype(fs_entry.path)
  if filetype == 'link' then
    return VimRc.icons.os.Interface .. ' ', 'MiniFilesSymLink'
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

local minifiles_setup = function()
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
      use_as_default_explorer = false,
    },
    content = {
      prefix = prefix,
    },
    mappings = {
      close = 'q',
      go_in = '<CR>',
      go_in_plus = '<Right>',
      go_out = '-',
      go_out_plus = '<Left>',
      mark_goto = "'",
      mark_set = 'm',
      reveal_cwd = '@',
      show_help = 'g?',
      synchronize = '=',
      trim_left = '<',
      trim_right = '>',
    },
  }

  vim.api.nvim_create_autocmd('User', {
    pattern = 'MiniFilesBufferCreate',
    callback = function(args)
      local b = args.data.buf_id
      MiniClue.enable_buf_triggers(b)
      vim.keymap.set('n', 'g~', function()
        local path = (MiniFiles.get_fs_entry() or {}).path
        if path == nil then
          return vim.notify 'Cursor is not on valid entry'
        end
        vim.fn.chdir(vim.fs.dirname(path))
      end, { buffer = b, desc = 'Set cwd' })
      vim.keymap.set('n', 'gy', function()
        local path = (MiniFiles.get_fs_entry() or {}).path
        if path == nil then
          return vim.notify 'Cursor is not on valid entry'
        end
        vim.fn.setreg(vim.v.register, path)
      end, { buffer = b, desc = 'Yank path' })
      vim.keymap.set('n', 'gX', function()
        vim.ui.open(MiniFiles.get_fs_entry().path)
      end, { buffer = b, desc = 'OS open' })
    end,
  })

  vim.api.nvim_create_autocmd('User', {
    callback = function(event)
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
    end,
    pattern = 'MiniFilesActionRename',
    desc = 'Rename Files',
  })
end

local explore_quickfix = function()
  vim.cmd(vim.fn.getqflist({ winid = true }).winid ~= 0 and 'cclose' or 'copen')
end
local explore_loclist = function()
  vim.cmd(vim.fn.getloclist(0, { winid = true }).winid ~= 0 and 'lclose' or 'lopen')
end

---@return ExplorerPlugin
return {
  setup = minifiles_setup,
  open_curr_buf = function()
    MiniFiles.open(vim.api.nvim_buf_get_name(0), false)
    MiniFiles.reveal_cwd()
  end,
  open_at_cwd = '<Cmd>lua MiniFiles.open()<CR>',
  open_at_loc = function(loc)
    if MiniFiles then
      MiniFiles.open(loc)
    end
  end,
  quickfix = explore_quickfix,
  loc_list = explore_loclist,
}
