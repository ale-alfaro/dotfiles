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
    go_in = '<Right>',
    go_in_plus = 'L',
    go_out = 'H',
    go_out_plus = '<Left>',
    mark_goto = '<C-g>',
    mark_set = '<C-m>',
    reset = '<BS>',
    reveal_cwd = '<C-d>',
    show_help = '?',
    synchronize = '<C-s>',
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

-- Yank in register full path of entry under cursor
local yank_path = function()
  local path = (MiniFiles.get_fs_entry() or {}).path
  if path == nil then
    return vim.notify 'Cursor is not on valid entry'
  end
  vim.fn.setreg(vim.v.register, path)
end

-- stylua:ignore
local wkey_prefix = '<leader>e'
_G.keymaps_define({
  { lhs = wkey_prefix .. 'x', rhs = '<Cmd>lua MiniFiles.open()<CR>', opts = { desc = 'File Explorer (cwd)' } },
  { lhs = wkey_prefix .. 'c', rhs = '<Cmd>lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>', opts = { desc = 'File Explorer' } },
  {
    mode = { 'n', 'v', 'x' },
    lhs = wkey_prefix .. 'v',
    rhs = '<Cmd>edit $MYVIMRC<CR>',
    opts = { desc = 'Edit $MYVIMRC' },
  },
  {
    mode = { 'n', 'v', 'x' },
    lhs = wkey_prefix .. 'z',
    rhs = '<Cmd>e $ZDOTDIR<CR>',
    opts = { desc = 'Edit .zshrc' },
  },
  {
    mode = { 'n', 'v', 'x' },
    lhs = wkey_prefix .. 'j',
    rhs = '<Cmd>e $JUSTFILES_HOME<CR>',
    opts = { desc = 'Edit Global JustFiles' },
  },
  {
    mode = { 'n', 'v', 'x' },
    lhs = wkey_prefix .. 'd',
    rhs = '<Cmd>e $XDG_CONFIG_HOME/direnv<CR>',
    opts = { desc = 'Edit Direnv config' },
  },
  {
    mode = { 'n', 'v', 'x' },
    lhs = wkey_prefix .. 'h',
    rhs = '<Cmd>e $XDG_CONFIG_HOME/hypr/hyprland<CR>',
    opts = { desc = 'Edit Hyprland Config' },
  },
  {
    lhs = '\\',
    rhs = '<Cmd>lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>',
    opts = { desc = 'Open file explorer shortcut' },
  },
}, { group = 'Explore/Edit', prefix = wkey_prefix })
-- Keep track of when the explorer is open to disable format on save.

-- Open path with system default handler (useful for non-text files)
local ui_open = function()
  vim.ui.open(MiniFiles.get_fs_entry().path)
end
-- However, some parts (like window title and height) of window config are later
-- updated internally. Use `MiniFilesWindowUpdate` event for them: >lua

_G.new_autocmd('User', function(args)
  vim.g.minifiles_active = true
  local buf_id = args.data.buf_id
  vim.keymap.set('n', '.', toggle_dotfiles, { buffer = buf_id, desc = 'Toggle hidden files' })
  vim.keymap.set('n', 'gy', yank_path, { buffer = buf_id, desc = 'Yank path' })
  vim.keymap.set('n', 'gX', ui_open, { buffer = buf_id, desc = 'OS open' })
end, 'MiniFilesBufferCreate', 'MiniFiles local keymaps')

--
-- _G.new_autocmd('User', function(event)
--   local from = event.data.from
--   local to = event.data.to
--   local changes = {
--     files = { {
--       oldUri = vim.uri_from_fname(from),
--       newUri = vim.uri_from_fname(to),
--     } }
--   }
--
--   local clients = vim.lsp.get_clients()
--   for _, client in ipairs(clients) do
--     if client:supports_method 'workspace/willRenameFiles' then
--       local resp = client:request_sync('workspace/willRenameFiles', changes, 1000, 0)
--       if resp and resp.result ~= nil then
--         vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding)
--       end
--     end
--   end
--
--   -- if rename then
--   --   rename()
--   -- end
--
--   for _, client in ipairs(clients) do
--     if client:supports_method 'workspace/didRenameFiles' then
--       client:notify('workspace/didRenameFiles', changes)
--     end
--   end
-- end, 'MiniFilesActionRename', "Rename Files")
