VimRc.later(function()
  require('extras.completion').setup_blink()
end)

VimRc.later(function()
  require 'extras.quicker-trouble'
end)

VimRc.later(function()
  require 'extras.overseer'
end)

VimRc.later(function()
  require('render-markdown').setup(
    ---@type render.md.Settings
    {
      preset = 'obsidian',
      completions = {
        lsp = {
          enabled = true,
        },
      },
      pipe_table = {
        preset = 'round',
      },
      latex = { enabled = false },
    }
  )
  vim.api.nvim_set_hl(0, 'RenderMarkdownH1', { fg = '#fb4934' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH2', { fg = '#fe8019' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH3', { fg = '#fabd2f' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH4', { fg = '#b8bb26' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH5', { fg = '#8ec07c' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH1Bg', { fg = '#fb4934' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH2Bg', { fg = '#fe8019' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH3Bg', { fg = '#fabd2f' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH4Bg', { fg = '#b8bb26' })
  vim.api.nvim_set_hl(0, 'RenderMarkdownH5Bg', { fg = '#8ec07c' })
end)
VimRc.later(function()
    require('custom.west').setup()
end)

-- VimRc.later(function()
--   require 'extras.codecompanion'
-- end)

