return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  config = function()
    GrepCommonOpts = {
      hidden = true,
      show_empty = true,
      live = true,
      win = {
        input = {
          keys = {
            ['<c-t>'] = { 'tcd', mode = { 'n', 'i' } },
          },
        },
        list = {
          keys = {
            ['<c-t>'] = { 'tcd', mode = { 'n', 'i' } },
          },
        },
      },
    }
  end,
  -- ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    --   dashboard = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    --   notifier = {
    --     enabled = true,
    --     timeout = 3000,
    --   },
    --   picker = {
    --     hidden = true,
    --     show_empty = true,
    --   },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = {
      -- animate = {
      --   duration = { step = 15, total = 250 },
      --   easing = 'linear',
      -- },
      -- faster animation when repeating scroll after delay
      -- animate_repeat = {
      --   delay = 10, -- delay in ms before using the repeat animation
      --   duration = { step = 5, total = 50 },
      --   easing = 'linear',
      -- },
      -- what buffers to animate
      -- filter = function(buf)
      --   return vim.g.snacks_scroll ~= false and vim.b[buf].snacks_scroll ~= false and vim.bo[buf].buftype ~= 'terminal'
      -- end,
    },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    styles = {
      notification = {
        -- wo = { wrap = true } -- Wrap notifications
      },
    },
  },
  init = function()
    vim.api.nvim_create_autocmd('User', {
      pattern = 'VeryLazy',
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...)
          Snacks.debug.inspect(...)
        end
        _G.bt = function()
          Snacks.debug.backtrace()
        end
        vim.print = _G.dd -- Override print to use snacks for `:=` command
      end,
    })
  end,
}
