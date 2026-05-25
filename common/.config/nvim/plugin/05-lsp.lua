-- Set up LSP servers.
VimRc.now_if_args(function()
  vim.diagnostic.config {
    severity_sort = true,
    float = {
      border = 'rounded',
      source = 'if_many',
      underline = true,
    },
    virtual_text = {
      spacing = 2,
      source = 'if_many',
      prefix = 'o',
    },
    -- Disable signs in the gutter.
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = 'E',
        [vim.diagnostic.severity.WARN] = 'W',
        [vim.diagnostic.severity.INFO] = 'I',
        [vim.diagnostic.severity.HINT] = 'H',
      },
    },
  }
  local cmp = require 'extras.completion'
  cmp.setup_mini_snippets()
  cmp.setup_blink()
  -- or equivalently

  require('vimrc_lsp').setup()
  require('custom.format').setup()
end)
