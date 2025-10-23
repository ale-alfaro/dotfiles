vim.pack.add {
  _G.plug('nvim-treesitter/nvim-treesitter', function()
    vim.cmd [[ TSUpdate ]]
  end),
  _G.plug 'nvim-treesitter/nvim-treesitter-textobjects',
}
-- Treesitter
VimRc.treesitter.config {
  indent = { enable = true }, ---@type TSFeat
  highlight = { enable = true }, ---@type TSFeat
  folds = { enable = true }, ---@type TSFeat
  ensure_installed = {
    'bash',
    'c',
    'cpp',
    'cmake',
    'diff',
    'dts',
    'devicetree',
    'html',
    'kconfig',
    'lua',
    'luadoc',
    'markdown',
    'python',
    'markdown_inline',
    'query',
    'vim',
    'vimdoc',
    'just',
    'json5',
    'toml',
    'ninja',
    'rst',
    'yaml',
  },
}
require 'plugin.mini-textedit'
-- require('nvim-treesitter-textobjects').setup {
--   move = {
--     enable = true,
--     set_jumps = true,
--     keys = {
--       goto_next_start = { [']f'] = '@function.outer', [']c'] = '@class.outer', [']a'] = '@parameter.inner' },
--       goto_next_end = { [']F'] = '@function.outer', [']C'] = '@class.outer', [']A'] = '@parameter.inner' },
--       goto_previous_start = { ['[f'] = '@function.outer', ['[c'] = '@class.outer', ['[a'] = '@parameter.inner' },
--       goto_previous_end = { ['[F'] = '@function.outer', ['[C'] = '@class.outer', ['[A'] = '@parameter.inner' },
--     },
--   },
-- }
