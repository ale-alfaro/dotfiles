require 'plugin.mini-files'

-- stylua:ignore
local wkey_prefix = '<leader>e'
KEYS.define({
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
    lhs = wkey_prefix .. 'o',
    rhs = '<Cmd>e $OBSIDIAN_HOME<CR>',
    opts = { desc = 'Edit Obsidian' },
  },
  {
    mode = { 'n', 'v', 'x' },
    lhs = wkey_prefix .. '.',
    rhs = '<Cmd>e $HOME/dotfiles<CR>',
    opts = { desc = 'Edit Dotfiles' },
  },
  {
    mode = { 'n', 'v', 'x' },
    lhs = wkey_prefix .. 'j',
    rhs = '<Cmd>e $JUST_HOME<CR>',
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
    mode = { 'n', 'v', 'x' },
    lhs = wkey_prefix .. 'w',
    rhs = '<Cmd>e $ZEPHYR_BASE<CR>',
    opts = { desc = 'Explore Zephyr Base' },
  },
  {
    lhs = '\\',
    rhs = '<Cmd>lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>',
    opts = { desc = 'Open file explorer shortcut' },
  },
}, { group = 'Explore/Edit', prefix = wkey_prefix })
