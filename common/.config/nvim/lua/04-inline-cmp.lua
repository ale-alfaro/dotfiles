vim.pack.add { _G.plug('Saghen/blink.cmp', 'cargo build --release') }
require 'plugin.blink-cmp'

vim.pack.add(_G.plug_spec {
  'L3MON4D3/LuaSnip',
  'rafamadriz/friendly-snippets',
})
require 'plugin.luasnip'
