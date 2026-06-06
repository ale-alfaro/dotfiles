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
vim.api.nvim_set_hl(0, '@markup.heading.1.markdown', { fg = '#e46876' })
vim.api.nvim_set_hl(0, '@markup.heading.2.markdown', { fg = '#ff9e3b' })
vim.api.nvim_set_hl(0, '@markup.heading.3.markdown', { fg = '#e6c384' })
vim.api.nvim_set_hl(0, '@markup.heading.4.markdown', { fg = '#7fb4ca' })
require('custom.obsidian').setup()
