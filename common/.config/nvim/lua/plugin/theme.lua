if VimRc.THEME == 'matte-black' then
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
