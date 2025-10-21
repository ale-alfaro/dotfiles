_G.Config = {}
require 'utils.init'
require 'config.opts'
require 'config.autocmds'
require 'config.usercmds'
require 'config.keymaps'
if vim.fn.has 'nvim-0.12' == 1 then
  vim.pack.add (_G.plug_spec({
    -- Core from original list
    'nvim-tree/nvim-web-devicons' ,
    'nvim-lua/plenary.nvim' ,
    'L3MON4D3/LuaSnip' ,
    'rafamadriz/friendly-snippets' ,
    'nvim-mini/mini.nvim' ,
    'Saghen/blink.cmp' ,
  }))

  require 'ui'
  require 'explorer'
  require 'search'
  require 'lsp'
  require 'lang'
  require 'extras'
  require 'textedit'
else
  vim.notify('Neovim v0.12 is required for this config!', "error")
end
