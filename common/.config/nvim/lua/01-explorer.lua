require 'plugin.mini-files'

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

local make_select_path = function(select_global, recency_weight)
  local visits = require 'mini.visits'
  local sort = visits.gen_sort.default { recency_weight = recency_weight }
  local select_opts = { sort = sort }
  return function()
    local cwd = select_global and '' or vim.fn.getcwd()
    visits.select_path(cwd, select_opts)
  end
end

local make_pick_core = function(cwd, desc)
  return function()
    local sort_latest = MiniVisits.gen_sort.default { recency_weight = 1 }
    local local_opts = { cwd = cwd, filter = 'core', sort = sort_latest }
    MiniExtra.pickers.visit_paths(local_opts, { source = { name = desc } })
  end
end
-- - `:h MiniVisits-overview` - overview of how module works
-- - `:h MiniVisits-examples` - examples of common setups
require('mini.visits').setup()
-- v is for 'Visits'. Common usage:
local prefix = '<leader>v'

-- stylua: ignore
_G.keymaps_define({
  { lhs = prefix .. 'l', rhs = '<Cmd>lua MiniVisits.add_label("core")<CR>',    opts = { desc = 'Add to core' }, },
  { lhs = prefix .. 'L', rhs = '<Cmd>lua MiniVisits.remove_label("core")<CR>', opts = { desc = 'Remove from core' }, },
  { lhs = prefix .. 'c', rhs = make_pick_core('', 'Core visits (all)'),        opts = { desc = 'Core visits (all)' } },
  { lhs = prefix .. 'C', rhs = make_pick_core(nil, 'Core visits (cwd)'),       opts = { desc = 'Core visits (cwd)' } },
  { lhs = prefix .. 'r', rhs = make_select_path(true, 0.5),                    opts = { desc = 'Frecent visits (all)' } },
  { lhs = prefix .. 'R', rhs = make_select_path(false, 0.5),                   opts = { desc = 'Frecent visits (cwd)' } },
}, { prefix = prefix, group = 'Visits' })

-- Smart Splits
require('smart-splits').setup {
  ignored_buftypes = { 'codecompanion' },
  ignored_filetypes = { 'codecompanion' },
  default_amount = 3,
  move_cursor_same_row = true,
}
_G.keymaps_define {
  -- stylua: ignore start
  { lhs = '<A-h>',      rhs = function() require('smart-splits').resize_left() end,       opts = { desc = 'Resize left' } },
  { lhs = '<A-j>',      rhs = function() require('smart-splits').resize_down() end,       opts = { desc = 'Resize down' } },
  { lhs = '<A-k>',      rhs = function() require('smart-splits').resize_up() end,         opts = { desc = 'Resize up' } },
  { lhs = '<A-l>',      rhs = function() require('smart-splits').resize_right() end,      opts = { desc = 'Resize right' } },
  { lhs = '<C-h>',      rhs = function() require('smart-splits').move_cursor_left() end,  opts = { desc = 'Move window left' } },
  { lhs = '<C-j>',      rhs = function() require('smart-splits').move_cursor_down() end,  opts = { desc = 'Move window down' } },
  { lhs = '<C-k>',      rhs = function() require('smart-splits').move_cursor_up() end,    opts = { desc = 'Move window up' } },
  { lhs = '<C-l>',      rhs = function() require('smart-splits').move_cursor_right() end, opts = { desc = 'Move window right' } },
  { lhs = '<leader>wt', rhs = function() VimRc.wezterm_spawn_terminal() end,              opts = { desc = 'Spawn wezterm terminal' } },
  -- stylua: ignore end
}
