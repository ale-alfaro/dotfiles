_G.VimRc = require 'custom'
require 'config.opts'
require 'config.autocmds'
require 'config.usercmds'
require 'config.keymaps'
if vim.fn.has 'nvim-0.12' == 1 then
  require '00-ui'
  require '01-explorer'
  require '02-search'
  require '03-textedit'
  require '05-lsp'
  require '99-extras'
else
  VimRc.error 'Neovim v0.12 is required for this config!'
end
