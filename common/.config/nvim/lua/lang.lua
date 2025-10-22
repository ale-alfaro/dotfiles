vim.pack.add(_G.plug_spec {
  'stevearc/conform.nvim',
  'mfussenegger/nvim-lint',
  'benomahony/uv.nvim',
  'b0o/schemastore.nvim',
})
-- Formatting
-- See also:
-- - `:h Conform`
-- - `:h conform-options`
-- - `:h conform-formatters`
require('utils.format').setup {
  default_format_opts = {
    timeout_ms = 3000,
    async = false, -- not recommended to change
    quiet = false, -- not recommended to change
    lsp_format = 'fallback', -- not recommended to change
  },
  formatters = {
    shfmt = {
      prepend_args = { '-i', '2', '-ci' },
    },
    just = {
      env = {
        JUST_UNSTABLE = 1,
      },
    },
  },
  formatters_by_ft = {
    lua = { 'stylua' },
    fish = { 'fish_indent' },
    sh = { 'shfmt' },
    -- # Example of using shfmt with extra args
    python = {
      -- To fix auto-fixable lint errors.
      'ruff_fix',
      -- To run the Ruff formatter.
      'ruff_format',
      -- To organize the imports.
      'ruff_organize_imports',
    },
    zsh = { 'shfmt' },
    markdown = { 'mdformat' },
    yaml = { 'yamlfmt' },
    -- ['*'] = { 'codespell' },
    ['_'] = { 'trim_whitespace' },
  },
}

-- Linting

local pattern = '([^:]+):(%d+):(%d+): (%a+)[(.*)] %[(%a[%a-]+)%]'
local groups = { 'file', 'lnum', 'col', 'severity', 'message', 'code' }
local severities = {
  error = vim.diagnostic.severity.ERROR,
  warning = vim.diagnostic.severity.WARN,
  note = vim.diagnostic.severity.HINT,
}
local opts = {
  linters_by_ft = {
    cmake = { 'cmakelint' }, -- Install: uv tool install cmakelint, repo: https://github.com/cmake-lint/cmake-lint
    python = { 'mypy' },
    yaml = { 'yamlint' }, --Install: uv tool install yamllint, repo: https://github.com/adrienverge/yamllint
    bash = { 'shellcheck' },
    sh = { 'shellcheck' },
    zsh = { 'zsh', 'shellcheck' },
    ['yaml.ghaction'] = { 'actionlint' }, -- Install: go install github.com/rhysd/actionlint/cmd/actionlint@latest, repo: https://github.com/rhysd/actionlint
  },
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
  },
  events = { 'BufWritePost', 'BufReadPost', 'InsertLeave' },
}
require('custom.better_linting').setup(opts)

require('uv.init').setup {
  keymaps = {
    prefix = '<leader>x',  -- Main prefix for uv commands
    commands = true,       -- Show uv commands menu (<leader>x)
    run_file = false,      -- Run current file (<leader>xr)
    run_selection = false, -- Run selected code (<leader>xs)
    run_function = false,  -- Run function (<leader>xf)
    venv = true,           -- Environment management (<leader>xe)
    init = true,           -- Initialize uv project (<leader>xi)
    add = true,            -- Add a package (<leader>xa)
    remove = true,         -- Remove a package (<leader>xd)
    sync = false,          -- Sync packages (<leader>xc)
    sync_all = false,      -- Sync all packages, extras and groups (<leader>xC)
  },
}
require('custom.python.uv').setup()
