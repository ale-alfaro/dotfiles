require('mini.files').setup {
  windows = {

    -- Maximum number of windows to show side by side
    max_number = math.huge,
    -- Whether to show preview of file/directory under cursor
    preview = false,
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
local minifiles_explorer_group = vim.api.nvim_create_augroup('minifiles_explorer', { clear = true })
vim.api.nvim_create_autocmd('User', {
  group = minifiles_explorer_group,
  pattern = 'MiniFilesExplorerOpen',
  callback = function()
    vim.g.minifiles_active = true
  end,
})
vim.api.nvim_create_autocmd('User', {
  group = minifiles_explorer_group,
  pattern = 'MiniFilesExplorerClose',
  callback = function()
    vim.g.minifiles_active = false
  end,
})
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
  { lhs = '<leader>vc', rhs = make_pick_core('', 'Core visits (all)'),  opts = { desc = 'Core visits (all)' } },
  { lhs = '<leader>vC', rhs = make_pick_core(nil, 'Core visits (cwd)'), opts = { desc = 'Core visits (cwd)' } },
  { lhs = '<leader>vr', rhs = make_select_path(true, 0.5),              opts = { desc = 'Frecent visits (all)' } },
  { lhs = '<leader>vR', rhs = make_select_path(false, 0.5),             opts = { desc = 'Frecent visits (cwd)' } },
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
  -- stylua: ignore end
}

-- Window with text overview. It is displayed on the right hand side. Can be used
-- for quick overview and navigation. Hidden by default. Example usage:
-- - `<Leader>mt` - toggle map window
-- - `<Leader>mf` - focus on the map for fast navigation
-- - `<Leader>ms` - change map's side (if it covers something underneath)
--
-- See also:
-- - `:h MiniMap.gen_encode_symbols` - list of symbols to use for text encoding
-- - `:h MiniMap.gen_integration` - list of integrations to show in the map
--
-- NOTE: Might introduce lag on very big buffers (10000+ lines)
-- local map = require 'mini.map'
-- map.setup {
--
--   -- Highlight integrations (none by default)
--   -- Show built-in search matches, 'mini.diff' hunks, and diagnostic entries
--   integrations = {
--     map.gen_integration.builtin_search(),
--     map.gen_integration.diff(),
--     map.gen_integration.diagnostic(),
--   },
--
--   -- Symbols used to display data
--   symbols = {
--     -- Encode symbols. See `:h MiniMap.config` for specification and
--     -- `:h MiniMap.gen_encode_symbols` for pre-built ones.
--     -- Use Braille dots to encode text
--     encode = map.gen_encode_symbols.dot '4x2',
--
--     -- Scrollbar parts for view and line. Use empty string to disable any.
--     scroll_line = '█',
--     scroll_view = '┃',
--   },
--
--   -- Window options
--   window = {
--     -- Whether window is focusable in normal way (with `wincmd` or mouse)
--     focusable = true,
--
--     -- Side to stick ('left' or 'right')
--     side = 'right',
--
--     -- Whether to show count of multiple integration highlights
--     show_integration_count = true,
--
--     -- Total width
--     width = 20,
--
--     -- Value of 'winblend' option
--     winblend = 25,
--
--     -- Z-index
--     zindex = 10,
--   },
-- }
--
-- -- stylua: ignore
-- _G.keymaps_define {
--   { lhs = '<leader>mf', rhs = '<Cmd>lua MiniMap.toggle_focus()<CR>', opts = { desc = 'Focus (toggle)' } },
--   { lhs = '<leader>mr', rhs = '<Cmd>lua MiniMap.refresh()<CR>',      opts = { desc = 'Refresh' } },
--   { lhs = '<leader>ms', rhs = '<Cmd>lua MiniMap.toggle_side()<CR>',  opts = { desc = 'Side (toggle)' } },
--   { lhs = '<leader>mt', rhs = '<Cmd>lua MiniMap.toggle()<CR>',       opts = { desc = 'Toggle' } },
-- }
--
-- for _, key in ipairs { 'n', 'N', '*', '#' } do
--   local rhs = key
--       -- Also open enough folds when jumping to the next match
--       .. 'zv'
--       .. '<Cmd>lua MiniMap.refresh({}, { lines = false, scrollbar = false })<CR>'
--   vim.keymap.set('n', key, rhs)
-- end
