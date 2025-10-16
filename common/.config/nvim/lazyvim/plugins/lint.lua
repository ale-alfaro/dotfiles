---@module "lint"
---@module "lazyvim"
local pattern = '([^:]+):(%d+):(%d+): (%a+)[(.*)] %[(%a[%a-]+)%]'
local groups = { 'file', 'lnum', 'col', 'severity', 'message', 'code' }
local severities = {
  error = vim.diagnostic.severity.ERROR,
  warning = vim.diagnostic.severity.WARN,
  note = vim.diagnostic.severity.HINT,
}

return {
  {
    'mfussenegger/nvim-lint',
    event = "LazyFile",
    config = function(_, opts)
      opts = opts or {}

      opts.events = { "BufWritePost", "BufReadPost", "InsertLeave" }
      opts.linters_by_ft = {
        cmake = { 'cmakelint' },              -- Install: uv tool install cmakelint, repo: https://github.com/cmake-lint/cmake-lint
        python = { 'mypy' },
        yaml = { 'yamlint' },                 --Install: uv tool install yamllint, repo: https://github.com/adrienverge/yamllint
        zsh = { 'zsh' },
        ['yaml.ghaction'] = { 'actionlint' }, -- Install: go install github.com/rhysd/actionlint/cmd/actionlint@latest, repo: https://github.com/rhysd/actionlint
      }
      opts.linters = {
        ty = {
          cmd = 'ty',
          stdin = false,
          stream = 'stdout',
          ignore_exitcode = true,
          args = {
            'check',
            '--output-format',
            'concise',
            '--color',
            'never',
          },
          parser = require('lint.parser').from_pattern(pattern, groups, severities, { ['source'] = 'ty' },
            { end_col_offset = 0 }),
        },
      }

      require('custom.lint.better_linting').setup(opts)
      vim.api.nvim_set_keymap("n", "<leader>li", "<cmd>Lint<cr>", { desc = "Trigger linting for current file" })
    end,
  },
}
