_G.VimRc = require 'utils'
require 'config.opts'
require 'config.autocmds'
require 'config.usercmds'
require 'config.keymaps'
if vim.fn.has 'nvim-0.12' == 1 then
  vim.pack.add(_G.plug_spec {
    'nvim-lua/plenary.nvim',
    'nvim-mini/mini.nvim',
  })
  require '00-ui'
  require '01-explorer'
  require '02-search'
  require '03-textedit'
  require '04-format-lint'
  require '05-extras'
  require '99-lsp'
else
  _G.error 'Neovim v0.12 is required for this config!'
end
