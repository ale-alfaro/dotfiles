vim.pack.add {
  _G.plug('nvim-treesitter/nvim-treesitter', function()
    vim.cmd [[ TSUpdate ]]
  end),
  _G.plug 'nvim-treesitter/nvim-treesitter-textobjects',
}



-- Treesitter
require('nvim-treesitter.configs').setup{
  indent = { enable = true }, ---@type TSFeat
  highlight = { enable = true }, ---@type TSFeat
  folds = { enable = true }, ---@type TSFeat
  ensure_installed = {
    'bash',
    'c',
    'cpp',
    'cmake',
    'diff',
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
    'gitignore',
    'vimdoc',
    'just',
    'json5',
    'toml',
    'ninja',
    'rst',
    'yaml',
  },
}


vim.cmd [[ set foldmethod=expr ]]
vim.cmd [[set foldexpr=nvim_treesitter#foldexpr()]]

-- vim.api.nvim_create_autocmd('FileType', {
--   group = vim.api.nvim_create_augroup('treesitter', { clear = true }),
--   callback = function(ev)
--     local ft, lang = ev.match, vim.treesitter.language.get_lang(ev.match)
--     if not VimRc.treesitter_have(ft) then
--       return
--     end
--     -- highlighting
--     local ok, _ = pcall(vim.treesitter.start)
--     if not ok then
--       _G.error("Couldn't not start treesitter for filetype: " .. ft .. ' lang: ' .. lang)
--       return
--     end
--     -- indents
--     vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
--     -- indentation, provided by nvim-treesitter
--     vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
--   end,
-- })
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
require 'plugin.mini-textedit'
