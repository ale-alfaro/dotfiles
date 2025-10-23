require 'plugin.mini-files'

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
-- - `<Leader>vv` - add    "core" label to current file.
-- - `<Leader>vV` - remove "core" label to current file.
-- - `<Leader>vc` - pick among all files with "core" label.
--
_G.keymaps_define {
  -- General & Navigation
  -- stylua: ignore
  {
    lhs = '<leader>vl',
    rhs = '<Cmd>lua MiniVisits.add_label()<CR>',
    opts = { desc = 'Add label' },
  },
  {
    lhs = '<leader>vL',
    rhs = '<Cmd>lua MiniVisits.remove_label()<CR>',
    opts = { desc = 'Remove label' },
  },
  { lhs = '<leader>vc', rhs = make_pick_core('', 'Core visits (all)'), opts = { desc = 'Core visits (all)' } },
  { lhs = '<leader>vC', rhs = make_pick_core(nil, 'Core visits (cwd)'), opts = { desc = 'Core visits (cwd)' } },
  { lhs = '<leader>vr', rhs = make_select_path(true, 0.5), opts = { desc = 'Frecent visits (all)' } },
  { lhs = '<leader>vR', rhs = make_select_path(false, 0.5), opts = { desc = 'Frecent visits (cwd)' } },
}


-- Smart Splits
require('smart-splits').setup {
  ignored_buftypes = { 'codecompanion' },
  ignored_filetypes = { 'codecompanion' },
  default_amount = 3,
  move_cursor_same_row = true,
}
_G.keymaps_define {
  -- stylua: ignore start
  { lhs = '<A-h>', rhs = function() require('smart-splits').resize_left() end,       opts = { desc = 'Resize left' } },
  { lhs = '<A-j>', rhs = function() require('smart-splits').resize_down() end,       opts = { desc = 'Resize down' } },
  { lhs = '<A-k>', rhs = function() require('smart-splits').resize_up() end,         opts = { desc = 'Resize up' } },
  { lhs = '<A-l>', rhs = function() require('smart-splits').resize_right() end,      opts = { desc = 'Resize right' } },
  { lhs = '<C-h>', rhs = function() require('smart-splits').move_cursor_left() end,  opts = { desc = 'Move window left' } },
  { lhs = '<C-j>', rhs = function() require('smart-splits').move_cursor_down() end,  opts = { desc = 'Move window down' } },
  { lhs = '<C-k>', rhs = function() require('smart-splits').move_cursor_up() end,    opts = { desc = 'Move window up' } },
  { lhs = '<C-l>', rhs = function() require('smart-splits').move_cursor_right() end, opts = { desc = 'Move window right' } },
  { lhs = '<leader>ms', rhs = function() VimRc.wezterm_spawn_terminal() end, opts = { desc = 'Move window right' } },
  -- stylua: ignore end
}
