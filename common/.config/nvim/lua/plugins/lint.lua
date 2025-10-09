return {
  'mfussenegger/nvim-lint',
  opts = {
    linters_by_ft = {
      markdown = { 'markdownlint' },
    },
    linters = {
      markdownlint = {
        args = { '--fix', '--disable', 'MD013', '--' },
      },
    },
  },
}
