
require('codediff').setup {
  diff = {
    layout = 'side-by-side',
    disable_inlay_hints = true,
    max_computation_time_ms = 5000,
    hide_merge_artifacts = false,
    conflict_result_position = 'bottom',
    conflict_result_height = 30,
    conflict_result_width_ratio = { 1, 1, 1 },
    jump_to_first_change = true,
    highlight_priority = 100,
    compute_moves = true,
    compact_context_lines = 3,
    compact_sync_folds = true,
    cycle_hunks_across_files = true,
  },
  explorer = {
    position = 'left',
    hidden = true,
    width = 40,
    height = 15,
    auto_refresh = true,
    auto_open_on_cursor = false,
    indent_markers = true,
    icons = {
      folder_closed = '',
      folder_open = '',
    },
    view_mode = 'list',
    flatten_dirs = true,
    file_filter = {
      ignore = { '.git/**', '.jj/**' },
    },
    status_right_margin = 1,
    visible_groups = {
      staged = true,
      unstaged = true,
      conflicts = true,
    },
  },
    keymaps = {
      view = {
        quit = "q",
        toggle_explorer = "<leader>et",
        focus_explorer = "<leader>ef",
}

}
}


require('mini.git').setup {

  -- General CLI execution
  job = {
    -- Path to Git executable
    git_executable = 'git',

    -- Timeout (in ms) for each job before force quit
    timeout = 30000,
  },

  -- Options for `:Git` command
  command = {
    -- Default split direction
    split = 'vertical',
  },
}
local git_keys = {
  { 'a', '<cmd>FzfLua git_status<cr>', 'Add/Status' },
  { 'd', '<cmd>FzfLua git_diff<cr>', 'Diff' },
  { 'h', '<Cmd>FzfLua git_hunks<CR>', 'Hunks' },
  { 'b', '<cmd>FzfLua git_blame<cr>', 'Blame' },
  { 'B', '<cmd>Git blame --porcelain -- %<cr>', 'Blame (MiniGit)' },
  { 'l', '<cmd>Git log --oneline<cr>', 'Log (MiniGit)' },
  { 's', '<cmd>Git status<cr>', 'Status (MiniGit)' },
  { 'c', '<cmd>Git commit<cr>', 'Commit (MiniGit)' },
  { 'D', '<cmd>Git diff<cr>', 'Diff (MiniGit)' },
  { 'b', '<cmd>FzfLua git_bcommits<cr>', 'Buf Commits' },
  { 'C', '<cmd>FzfLua git_commits<cr>', 'Commits' },
}

for _, k in ipairs(git_keys) do
  vim.keymap.set('n', '<leader>g' .. k[1], k[2], { desc = k[3] })
end
-- git.setup_git_blame()
-- git.setup_git_conflict()
local diff = require 'mini.diff'
diff.setup {

  -- Source(s) for how reference text is computed/updated/etc
  -- Uses content from Git index by default
  source = { diff.gen_source.git(), diff.gen_source.save() },
  view = {
    style = 'sign',
    signs = { add = '+', change = '~', delete = '-' },
  },
}
local diff_keys = {
  { 't', '<cmd>lua MiniDiff.toggle_overlay()<cr>', 'Toggle overlay' },
  { 'c', '<cmd>CodeDiff HEAD<cr>', 'HEAD' },
  { 'h', '<cmd>CodeDiff history<cr>', 'History' },
}

for _, k in ipairs(diff_keys) do
  vim.keymap.set('n', '<leader>d' .. k[1], k[2], { desc = k[3] })
end
VimRc.keymap_clues = vim.list_extend(VimRc.keymap_clues, {
  { mode = 'n', keys = '<Leader>g', desc = '+Git' },
  { mode = 'x', keys = '<Leader>g', desc = '+Git' },
  { mode = 'n', keys = '<Leader>d', desc = '+Diff' },
})
vim.api.nvim_create_autocmd('User', {
  pattern = 'CodeDiffOpen',
  callback = function()
    if MiniClue then
        MiniClue.ensure_buf_triggers(0)
    end
    if MiniDiff then
        MiniDiff.disable(0)
    end
  end,
})
vim.api.nvim_create_autocmd('User', {
  pattern = 'CodeDiffClose',
  callback = function()
    if MiniDiff then
        MiniDiff.enable(0)
    end
  end,
})
