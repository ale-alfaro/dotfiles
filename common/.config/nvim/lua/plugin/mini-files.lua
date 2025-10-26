---@module "mini.nvim"

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
    -- Width of preview window
    width_preview = 25,
  },
  options = {
    permanent_delete = false,
    use_as_default_explorer = true,
  },
  mappings = {
    close = 'q',
    go_in = 'l',
    go_in_plus = 'L',
    go_out = 'H',
    go_out_plus = '<Left>',
    mark_goto = 'mg',
    mark_set = 'mm',
    reset = '<BS>',
    reveal_cwd = '<C-d>',
    show_help = '?',
    synchronize = 's',
    trim_left = '<',
    trim_right = '>',
  },
}
local show_dotfiles = true
local filter_show = function(fs_entry)
  return true
end
local filter_hide = function(fs_entry)
  return not vim.startswith(fs_entry.name, '.')
end

local toggle_dotfiles = function()
  show_dotfiles = not show_dotfiles
  local new_filter = show_dotfiles and filter_show or filter_hide
  require('mini.files').refresh { content = { filter = new_filter } }
end

local minifiles_explorer_group = vim.api.nvim_create_augroup('minifiles_explorer', { clear = true })
-- Yank in register full path of entry under cursor
local yank_path = function()
  local path = (MiniFiles.get_fs_entry() or {}).path
  if path == nil then
    return vim.notify 'Cursor is not on valid entry'
  end
  vim.fn.setreg(vim.v.register, path)
end
vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesWindowOpen',
  callback = function(args)
    local win_id = args.data.win_id
    vim.g.minifiles_active = true

    -- Customize window-local settings
    vim.wo[win_id].winblend = 25
    local config = vim.api.nvim_win_get_config(win_id)
    config.border, config.title_pos = 'double', 'right'
    vim.api.nvim_win_set_config(win_id, config)
  end,
})

-- stylua:ignore
_G.keymaps_define {
  { lhs = '<leader>ed', rhs = '<Cmd>lua MiniFiles.open()<CR>', opts = { desc = '[E]xplore [D]irectory' } },
  {
    lhs = '\\',
    rhs = '<Cmd>lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>',
    opts = { desc = 'Open file explorer quick' },
  },
}
-- Keep track of when the explorer is open to disable format on save.

-- Open path with system default handler (useful for non-text files)
local ui_open = function()
  vim.ui.open(MiniFiles.get_fs_entry().path)
end
-- However, some parts (like window title and height) of window config are later
-- updated internally. Use `MiniFilesWindowUpdate` event for them: >lua

vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesWindowUpdate',
  callback = function(args)
    local config = vim.api.nvim_win_get_config(args.data.win_id)

    -- Ensure fixed height
    config.height = 30

    -- Ensure no title padding
    local n = #config.title
    config.title[1][1] = config.title[1][1]:gsub('^ ', '')
    config.title[n][1] = config.title[n][1]:gsub(' $', '')

    vim.api.nvim_win_set_config(args.data.win_id, config)
  end,
})

vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesBufferCreate',
  callback = function(args)
    local buf_id = args.data.buf_id
    vim.keymap.set('n', '.', toggle_dotfiles, { buffer = buf_id, desc = 'Toggle hidden files' })
    vim.keymap.set('n', 'gy', yank_path, { buffer = buf_id, desc = 'Yank path' })
    vim.keymap.set('n', 'gX', ui_open, { buffer = buf_id, desc = 'OS open' })
  end,
})

vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesActionRename',
  callback = function(event)
    VimRc.mini.files_on_rename(event.data.from, event.data.to)
  end,
})

local function files_on_rename(from, to, rename)
  local changes = { files = { {
    oldUri = vim.uri_from_fname(from),
    newUri = vim.uri_from_fname(to),
  } } }

  local clients = vim.lsp.get_clients()
  for _, client in ipairs(clients) do
    if client:supports_method 'workspace/willRenameFiles' then
      local resp = client:request_sync('workspace/willRenameFiles', changes, 1000, 0)
      if resp and resp.result ~= nil then
        vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding)
      end
    end
  end

  if rename then
    rename()
  end

  for _, client in ipairs(clients) do
    if client:supports_method 'workspace/didRenameFiles' then
      client:notify('workspace/didRenameFiles', changes)
    end
  end
end
