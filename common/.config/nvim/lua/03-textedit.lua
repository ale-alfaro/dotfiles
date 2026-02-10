-- Treesitter
require 'plugin.mini-textedit'

vim.pack.add {
  _G.plug('nvim-treesitter/nvim-treesitter', {
    version = 'main',
    build_hook = {
      plugin = 'nvim-treesitter',
      build_cmd = 'TSUpdate',
      build_cmd_type = 'user',
    },
  }),

  -- _G.plug('Saghen/blink.cmp', {
  --   build_hook = {
  --     plugin = 'blink.cmp',
  --     build_cmd_type = 'shell',
  --     build_cmd = 'cargo build --release',
  --   },
  -- }),
}
-- if not MiniCompletion then
--   local ok, _ = pcall(require, 'plugin.blink-cmp')
--   if not ok then
--     VimRc.error 'Failed to load blink.cmp'
--   end
-- end
if not MiniSnippets then
  -- local ok, luasnip = pcall(require, 'luasnip')
  -- if ok then
  --   luasnip.setup { enable_autosnippets = true }
  --   require('luasnip.loaders.from_lua').load { paths = '~/.config/nvim/snippets/' }
  --   -- VimRc.pack_add(luasnip)
  -- end
end
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
