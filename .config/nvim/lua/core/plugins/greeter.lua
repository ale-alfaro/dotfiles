return {
  'goolord/alpha-nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local alpha = require 'alpha'
    local dashboard = require 'alpha.themes.dashboard'

    -- Set header
    dashboard.section.header.val = {
      [[                               __                ]],
      [[  ___     ___    ___   __  __ /\_\    ___ ___    ]],
      [[ / _ `\  / __`\ / __`\/\ \/\ \\/\ \  / __` __`\  ]],
      [[/\ \/\ \/\  __//\ \_\ \ \ \_/ |\ \ \/\ \/\ \/\ \ ]],
      [[\ \_\ \_\ \____\ \____/\ \___/  \ \_\ \_\ \_\ \_\]],
      [[ \/_/\/_/\/____/\/___/  \/__/    \/_/\/_/\/_/\/_/]],
    }

    -- Set menu
    dashboard.section.buttons.val = {
      dashboard.button('f', ' ' .. ' Find file', ':Telescope find_files <CR>'),
      dashboard.button('n', ' ' .. ' New file', ':ene <BAR> startinsert <CR>'),
      dashboard.button('r', ' ' .. ' Recent files', ':Telescope oldfiles <CR>'),
      dashboard.button('g', ' ' .. ' Find text', ':Telescope live_grep <CR>'),
      dashboard.button('c', ' ' .. ' Config', ':e ~/.config/nvim/init.lua <CR>'),
      dashboard.button('q', ' ' .. ' Quit', ':qa<CR>'),
    }

    -- Send config to alpha
    alpha.setup(dashboard.opts)

    -- Disable statusline and tabline for alpha
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'alpha',
      callback = function()
        vim.opt.laststatus = 0
        vim.opt.showtabline = 0
      end,
    })

    -- Re-enable statusline and tabline when leaving alpha
    vim.api.nvim_create_autocmd('BufUnload', {
      buffer = 0,
      callback = function()
        vim.opt.laststatus = 3
        vim.opt.showtabline = 2
      end,
    })
  end,
}