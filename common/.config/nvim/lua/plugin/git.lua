-- Git integration for more straightforward Git actions based on Neovim's state.
-- It is not meant as a fully featured Git client, only to provide helpers that
-- integrate better with Neovim. Example usage:
-- - `<Leader>gs` - show information at cursor
-- - `<Leader>gd` - show unstaged changes as a patch in separate tabpage
-- - `<Leader>gL` - show Git log of current file
-- - `:Git help git` - show output of `git help git` inside Neovim
require('mini.git').setup()

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

local wkey_prefix = '<leader>d'
KEYS.define({
  -- General & Navigation
  -- stylua:ignore
  { lhs = wkey_prefix .. 'c', rhs = '<cmd>FzfLua changes<cr>', opts = { desc = 'Search Git Diff (file-only)' } },
  { lhs = wkey_prefix .. 'h', rhs = '<cmd>FzfLua git_hunks<cr>', opts = { desc = 'Git Hunks' } },
  { lhs = wkey_prefix .. 's', rhs = '<cmd>FzfLua git_diff<cr>', opts = { desc = 'Search Git Diff' } },
  { lhs = wkey_prefix .. 't', rhs = '<Cmd>lua MiniDiff.toogle_overlay()<CR>', opts = { desc = 'Diff Toggle Overlay' } },
  { lhs = wkey_prefix .. 'd', rhs = '<Cmd>Git diff<CR>', opts = { desc = 'Diff' } },
}, { prefix = wkey_prefix, group = 'Diff' })
