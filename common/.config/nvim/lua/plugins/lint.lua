return {
  'mfussenegger/nvim-lint',
  event = { 'BufReadPre', 'BufNewFile' },
  opts = {
    linters_by_ft = {
      markdown = { 'markdownlint' },
      python = { 'ruff' },
      fish = { 'fish' },
    },
    linters = {
      pylint = {
        cmd = 'uvx',
        args = { 'pylint' },
      },
      ruff = {
        cmd = 'uvx',
        args = { 'ruff', 'check' },
      },
      markdownlint = {
        args = { '--fix', '--disable', 'MD013', '--' },
      },
    },
  },
  config = function(_, opts)
    require('lint').linters_by_ft = opts.linters_by_ft
    local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost' }, {
      group = lint_augroup,
      callback = function()
        if vim.bo.modifiable then
          require('lint').try_lint()
        end
      end,
    })
  end,
}
