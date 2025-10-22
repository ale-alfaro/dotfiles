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

  require 'ui'
  require 'explorer'
  require 'search'
  require 'textedit'
  require 'inline_cmp'
  require 'lsp'
  require 'lang'
  require 'extras'
else
  _G.error 'Neovim v0.12 is required for this config!'
end
