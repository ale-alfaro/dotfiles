_G.VimRc = require 'utils'
require 'config.opts'
require 'config.autocmds'
require 'config.usercmds'
require 'config.keymaps'
if vim.fn.has 'nvim-0.12' == 1 then
  vim.pack.add(_G.plug_spec {
    -- Core from original list
    -- 'nvim-tree/nvim-web-devicons',
    'nvim-lua/plenary.nvim',
    'nvim-mini/mini.nvim',
  })
  require '00-ui'
  require '01-explorer'
  require '02-search'
  require '03-textedit'
  require '04-inline-cmp'
  require '05-lang'
  require '06-ai'
  require '07-extras'
  require '08-git'
  require '99-lsp'
else
  _G.error 'Neovim v0.12 is required for this config!'
end
