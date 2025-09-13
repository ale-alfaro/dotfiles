return { -- Autoformat
  'stevearc/conform.nvim',
  -- keys = {
  --   {
  --     '<leader>fb',
  --     function()
  --       require('conform').format { async = true, lsp_format = 'fallback' }
  --     end,
  --     mode = '',
  --     desc = '[F]ormat [B]uffer',
  --   },
  -- },
  opts = {
    formatters_by_ft = {
      lua = { 'stylua' },
      python = { 'ruff_fix', 'ruff_format' },
      sh = { 'shfmt' },
      zsh = { 'shfmt' },
      markdown = { 'mdformat' },
      go = { 'goimports', 'gofumpt' },
      gomod = { 'goimports', 'gofumpt' },
      rust = { 'rustfmt', lsp_format = 'fallback' },
      c = { 'clang_format' },
      cpp = { 'clang_format' },
      cmake = { 'cmake_format' },
      json = { 'jq' },
      javascript = { 'prettier' },
      javascriptreact = { 'prettier' },
      typescript = { 'prettier' },
      typescriptreact = { 'prettier' },
      yaml = { 'yamlfmt' },
      just = { 'justfmt' },
      xml = { 'xmllint' },
      ['*'] = { 'codespell' },
      ['_'] = { 'trim_whitespace' },
    },
  },
}

