local git = require 'extras.minigit'
git.setup()
git.setup_git_blame()
git.setup_git_conflict()
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
require('octo').setup {
  -- or "fzf-lua" or "snacks" or "default"
  picker = 'fzf-lua',
  -- bare Octo command opens picker of commands
  enable_builtin = true,
}
VimRc.keymap_clues[#VimRc.keymap_clues + 1] = { mode = 'n', keys = '<Leader>g', desc = '+Git' }
VimRc.keymap_clues[#VimRc.keymap_clues + 1] = { mode = 'x', keys = '<Leader>g', desc = '+Git' }
local diff_keys = {
  { 't', '<cmd>lua MiniDiff.toggle_overlay()<cr>', 'Toggle overlay' },
  {
    'q',
    function()
      vim.fn.setqflist(MiniDiff.export 'qf')
    end,
    'QuickFix',
  },
}

for _, k in ipairs(diff_keys) do
  vim.keymap.set('n', '<leader>d' .. k[1], k[2], { desc = k[3] })
end
VimRc.keymap_clues[#VimRc.keymap_clues + 1] = { mode = 'n', keys = '<Leader>d', desc = '+Diff' }
