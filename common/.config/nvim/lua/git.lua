-- Git integration for more straightforward Git actions based on Neovim's state.
-- It is not meant as a fully featured Git client, only to provide helpers that
-- integrate better with Neovim. Example usage:
-- - `<Leader>gs` - show information at cursor
-- - `<Leader>gd` - show unstaged changes as a patch in separate tabpage
-- - `<Leader>gL` - show Git log of current file
-- - `:Git help git` - show output of `git help git` inside Neovim
require('mini.git').setup()

-- Autohighlight word under cursor with a customizable delay.
-- Word boundaries are defined based on `:h 'iskeyword'` option.
--
-- It is not enabled by default because its effects are a matter of taste.
-- Uncomment next line (use `gcc`) to enable.
-- later(function() require('mini.cursorword').setup() end)

-- Work with diff hunks that represent the difference between the buffer text and
-- some reference text set by a source. Default source uses text from Git index.
-- Also provides summary info used in developer section of 'mini.statusline'.
-- Example usage:
-- - `ghip` - apply hunks (`gh`) within *i*nside *p*aragraph
-- - `gHG` - reset hunks (`gH`) from cursor until end of buffer (`G`)
-- - `ghgh` - apply (`gh`) hunk at cursor (`gh`)
-- - `gHgh` - reset (`gH`) hunk at cursor (`gh`)
-- - `<Leader>go` - toggle overlay
--
-- See also:
-- - `:h MiniDiff-overview` - overview of how module works
-- - `:h MiniDiff-diff-summary` - available summary information
-- - `:h MiniDiff.gen_source` - available built-in sources
require('mini.diff').setup()

_G.Utils.keymaps.define {
  -- General & Navigation
  -- stylua:ignore
  { lhs = '<leader>dt', rhs = '<Cmd>lua MiniDiff.toogle_overlay()<CR>', opts = { desc = 'Diff Toggle Overlay' } },
  { lhs = '<leader>dc', rhs = '<Cmd>lua MiniGit.show_at_cursor()<CR>',  opts = { desc = 'Diff Showw at Cursor' } },
  { lhs = '<leader>dd', rhs = '<Cmd>Git diff<CR>',                      opts = { desc = 'Diff' } },
  { lhs = '<leader>da', rhs = '<Cmd>Git diff --cached<CR>',             opts = { desc = 'Added Diff' } },
}
