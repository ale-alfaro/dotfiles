return {
  'mfussenegger/nvim-lint',
  opts = {
    linters_by_ft = {
      markdown = { 'markdownlint' },
      python = { 'ruff' },
    },
    linters = {
      ruff = {
        cmd = 'uv',
        args = { 'run', 'ruff', 'check' },
      },
      markdownlint = {
        args = { '--fix', '--disable', 'MD013', '--' },
      },
    },
  },
}
