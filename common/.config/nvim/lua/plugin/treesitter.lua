
-- Extend and create a/i textobjects, like `:h a(`, `:h a'`, and more).
-- Contains not only `a` and `i` type of textobjects, but also their "next" and
-- "last" variants that will explicitly search for textobjects after and before
-- cursor. Example usage:
-- - `ci)` - *c*hange *i*inside parenthesis (`)`)
-- - `di(` - *d*elete *i*inside padded parenthesis (`(`)
-- - `yaq` - *y*ank *a*round *q*uote (any of "", '', or ``)
-- - `vif` - *v*isually select *i*inside *f*unction call
-- - `cina` - *c*hange *i*nside *n*ext *a*rgument
-- - `valaala` - *v*isually select *a*round *l*ast (i.e. previous) *a*rgument
--   and then again reselect *a*round new *l*ast *a*rgument
--
-- See also:
-- - `:h text-objects` - general info about what textobjects are
-- - `:h MiniAi-builtin-textobjects` - list of all supported textobjects
-- - `:h MiniAi-textobject-specification` - examples of custom textobjects

-- require('mini.extra').setup()

local gen_ai_spec = require('mini.extra').gen_ai_spec

-- local builtin_textobjects = {
--   -- Use balanced pair for brackets. Use opening ones to possibly remove edge
--   -- whitespace from `i` textobject.
--   ['('] = { '%b()', '^.%s*().-()%s*.$' },
--   [')'] = { '%b()', '^.().*().$' },
--   ['['] = { '%b[]', '^.%s*().-()%s*.$' },
--   [']'] = { '%b[]', '^.().*().$' },
--   ['{'] = { '%b{}', '^.%s*().-()%s*.$' }%,
--   ['}'] = { '%b{}', '^.().*().$' },
--   ['<'] = { '%b<>', '^.%s*().-()%s*.$' },
--   ['>'] = { '%b<>', '^.().*().$' },
--   -- Use special "same balanced" pattern to select quotes in pairs
--   ["'"] = { "%b''", '^.().*().$' },
--   ['"'] = { '%b""', '^.().*().$' },
--   ['`'] = { '%b``', '^.().*().$' },
--   -- Derived from user prompt
--   ['?'] = MiniAi.gen_spec.user_prompt(),
--   -- Argument
--   ['a'] = MiniAi.gen_spec.argument(),
--   -- Brackets
--   ['b'] = { { '%b()', '%b[]', '%b{}' }, '^.().*().$' },
--   -- Function call
--   ['f'] = MiniAi.gen_spec.function_call(),
--   -- Tag
--   ['t'] = { '<(%w-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' },
--   -- Quotes
--   ['q'] = { { "%b''", '%b""', '%b``' }, '^.().*().$' },
-- }

local spec_treesitter = require('mini.ai').gen_spec.treesitter
local spec_user_prompt = require('mini.ai').gen_spec.user_prompt
local spec_pair = require('mini.ai').gen_spec.pair
local spec_func = require('mini.ai').gen_spec.function_call
require('mini.ai').setup {
  custom_textobjects = {
    B = gen_ai_spec.buffer(),
    D = gen_ai_spec.diagnostic(),
    I = gen_ai_spec.indent(),
    L = gen_ai_spec.line(),
    N = gen_ai_spec.number(),
    F = spec_treesitter { a = '@function.outer', i = '@function.inner' },
    o = spec_treesitter {
      a = { '@conditional.outer', '@loop.outer' },
      i = { '@conditional.inner', '@loop.inner' },
    },
    f = spec_func { name_pattern = '[%w_%.%>%<]' },
    p = spec_user_prompt(),
    ['|'] = spec_pair('|', '|', { type = 'non-balanced' }),
  },
}
vim.pack.add {
  _G.plug('nvim-treesitter/nvim-treesitter', {
    version = 'main',
    build_hook = {
      plugin = 'nvim-treesitter',
      build_cmd = 'TSUpdate',
      build_cmd_type = 'user',
    },
  }),
}
local tresitter_ft = {
  'bash',
  'c',
  'cpp',
  'cmake',
  'diff',
  'devicetree',
  'json',
  'just',
  'kconfig',
  'lua',
  'luadoc',
  'luap',
  'markdown',
  'markdown_inline',
  'ninja',
  'printf',
  'python',
  'query',
  'regex',
  'rst',
  'toml',
  'tera',
  'vim',
  'vimdoc',
  'xml',
  'yaml',
}

require('nvim-treesitter').setup()
require('nvim-treesitter').install(tresitter_ft)
vim.g.treesitter_folds = true
vim.api.nvim_create_autocmd('FileType', {
  pattern = tresitter_ft,
  callback = function()
    vim.treesitter.start()
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    if vim.g.treesitter_folds then
      vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      vim.wo[0][0].foldmethod = 'expr'
    end
  end,
  desc = 'Nvim-treesitter activation',
})
local query = vim.treesitter.query

-- register custom predicates (overwrite existing; needed for CI)

---@param match table<integer,TSNode[]>,
---@param pattern integer
---@param bufnr integer|string
---@param pred any[]
---@param metadata vim.treesitter.query.TSMetadata
---@return boolean?
query.add_predicate('is-mise?', function(match, pattern, bufnr, pred, metadata)
  local filepath = vim.api.nvim_buf_get_name(tonumber(bufnr) or 0)
  local filename = vim.fn.fnamemodify(filepath, ':t')
  return string.match(filename, '.*mise.*%.toml$') ~= nil
end, { force = true, all = false })
require 'custom.treesitter'
