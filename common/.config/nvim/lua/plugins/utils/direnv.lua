return {
  'NotAShelf/direnv.nvim',
  lazy = true,
  event = 'BufReadPre',
  opts = {
    autoload = true,
    enable = true,
  },
  config = function(_, opts)
    require('direnv').setup(opts)
  end,
}
