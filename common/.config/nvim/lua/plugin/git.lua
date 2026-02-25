-- vim.cmd [[let g:floaterm_borderchars = "─│─│╭╮╯╰"]]
-- vim.cmd [[let s:width = "1.0"]]
-- vim.cmd [[let s:height = "1.0"]]
-- vim.cmd [[let s:autoclose = "1"]]
-- vim.cmd [[let s:command = 'lazygit']]
--
-- local function open_lazygit_popup()
--   vim.api.nvim_exec2('FloatermNew --height=1.0 --width=1.0 --autoclose=1 ', { 'lazygit' })
--   -- vim.cmd [[execute "FloatermNew --height=1.0 --width=1.0 --autoclose=1 " . s:command]]
-- end
--
-- vim.keymap.set('n', '<leader>lg', open_lazygit_popup, { silent = true })

-- Git integration for more straightforward Git actions based on Neovim's state.
-- It is not meant as a fully featured Git client, only to provide helpers that
-- integrate better with Neovim. Example usage:
-- - `<Leader>gs` - show information at cursor
-- - `<Leader>gd` - show unstaged changes as a patch in separate tabpage
-- - `<Leader>gL` - show Git log of current file
-- - `:Git help git` - show output of `git help git` inside Neovim
require('mini.git').setup()
local git_log_cmd = [[Git log --pretty=format:\%h\ \%as\ │\ \%s --topo-order]]
local git_log_buf_cmd = git_log_cmd .. ' --follow -- %'
local wkey_git_prefix = '<leader>g'
KEYS.define {
  -- { lhs = wkey_git_prefix .. 'l', rhs = '<Cmd>' .. git_log_cmd .. '<CR>', opts = { desc = 'Git Log' } },
  -- { lhs = wkey_git_prefix .. 'L', rhs = '<Cmd>' .. git_log_buf_cmd .. '<CR>', opts = { desc = 'Git Log buffer' } },
  -- { mode = { 'n', 'x' }, lhs = wkey_git_prefix .. 's', rhs = '<Cmd>lua MiniGit.show_at_cursor()<CR>', opts = { desc = 'Git Show at cursor' } },
  { lhs = wkey_git_prefix .. 's', rhs = '<cmd>FzfLua git_diff<cr>', opts = { desc = 'Search Git Diff' } },
  { lhs = wkey_git_prefix .. 'd', rhs = '<Cmd>Git diff<CR>', opts = { desc = 'Git Diff' } },
  { lhs = wkey_git_prefix .. 'c', rhs = '<CMD>FzfLua changes<CR>', opts = { desc = 'Search Git Diff (file-only)' } },
  { lhs = wkey_git_prefix .. 'h', rhs = '<cmd>FzfLua git_hunks<cr>', opts = { desc = 'Git Hunks' } },
}

local align_blame = function(au_data)
  if au_data.data.git_subcommand ~= 'blame' then
    return
  end

  -- Align blame output with source
  local win_src = au_data.data.win_source
  vim.wo.wrap = false
  vim.fn.winrestview { topline = vim.fn.line('w0', win_src) }
  vim.api.nvim_win_set_cursor(0, { vim.fn.line('.', win_src), 0 })

  -- Bind both windows so that they scroll together
  vim.wo[win_src].scrollbind, vim.wo.scrollbind = true, true
end

vim.api.nvim_create_autocmd('User', { pattern = 'MiniGitCommandSplit', callback = align_blame })
local format_summary = function(data)
  -- Utilize buffer-local table summary
  local summary = vim.b[data.buf].minigit_summary
  vim.b[data.buf].minigit_summary_string = summary.head_name or ''
end

vim.api.nvim_create_autocmd('User', { pattern = 'MiniGitUpdated', callback = format_summary })
