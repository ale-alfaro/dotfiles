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
}

local ensure_installed = {
  'bash',
  'c',
  'cpp',
  'cmake',
  'diff',
  'devicetree',
  'jsdoc',
  'json',
  'jsonc',
  'json5',
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
  'vim',
  'vimdoc',
  'xml',
  'yaml',
}

require('nvim-treesitter').setup {
  ensure_installed = ensure_installed,
  highlighter = true,
}

_G.new_autocmd('FileType', function(ev)
  local ft, lang = ev.match, vim.treesitter.language.get_lang(ev.match)
  -- if not VimRc.treesitter_have(ft) then
  --   return
  -- end
  -- highlighting
  local ok, _ = pcall(vim.treesitter.start)
  if not ok then
    _G.error("Couldn't not start treesitter for filetype: " .. ft .. ' lang: ' .. lang)
    return
  end
  -- indents
  vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  -- indentation, provided by nvim-treesitter
  vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end, 'Nvim-Treesitter start')

local ok, luasnip = pcall(require, 'plugin.luasnip')
if ok then
  VimRc.pack_add(luasnip)
end

local ok, _ = pcall(require, 'plugin.blink-cmp')
if not ok then
  _G.error 'Failed to load blink.cmp'
end
