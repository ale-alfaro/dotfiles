if VimRc.THEME == 'kanagawa' then
  vim.pack.add(_G.plug_spec {
    'rebelot/kanagawa.nvim',
  })
  vim.cmd 'colorscheme kanagawa'
elseif VimRc.THEME == 'matte-black' then
  vim.pack.add(_G.plug_spec {
    'tahayvr/matteblack.nvim',
  })
  require('matteblack').colorscheme()
else
  vim.pack.add(_G.plug_spec {
    'catppuccin/nvim',
  })
  require('catppuccin').setup {
    flavour = 'macchiato', -- latte, frappe, macchiato, mocha
    background = { -- :h background
      light = 'latte',
      dark = 'mocha',
    },
  }
end
