local pattern = '([^:]+):(%d+):(%d+):(%d+):(%d+): (%a+): (.*) %[(%a[%a-]+)%]'
local groups = { 'file', 'lnum', 'col', 'end_lnum', 'end_col', 'severity', 'message', 'code' }
local severities = {
  error = vim.diagnostic.severity.ERROR,
  warning = vim.diagnostic.severity.WARN,
  note = vim.diagnostic.severity.HINT,
}

return {
  {
    'mfussenegger/nvim-lint',
    event = 'LazyFile',
    opts = {
      -- Event to trigger linters
      events = { 'BufWritePost', 'BufReadPost', 'InsertLeave' },
      linters_by_ft = {
        cmake = { 'cmakelint' }, -- Install: uv tool install cmakelint, repo: https://github.com/cmake-lint/cmake-lint
        python = { 'ruff', 'ty' },
        yaml = { 'yamlint' }, --Install: uv tool install yamllint, repo: https://github.com/adrienverge/yamllint
        zsh = { 'zsh' },
        ['yaml.ghaction'] = { 'actionlint' }, -- Install: go install github.com/rhysd/actionlint/cmd/actionlint@latest, repo: https://github.com/rhysd/actionlint
      },
      -- LazyVim extension to easily override linter options
      -- or add custom linters.
      ---@type table<string,table>
      linters = {
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
          parser = require('lint.parser').from_pattern(pattern, groups, severities, { ['source'] = 'ty' }, { end_col_offset = 0 }),
        },
        -- just = {
        --
        --   command = 'just',
        --   args = { '--fmt', '--unstable', '-f', '$FILENAME' },
        --   stdin = false,
        --   ignore_exitcode = true,
        --   parser = require('lint.parser').from_pattern(pattern, groups, nil, {
        --     ['source'] = 'cmakelint',
        --     ['severity'] = vim.diagnostic.severity.WARN,
        --   }),
        -- },
      },
    },
  },
}
