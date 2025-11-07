---@module "nvim-lint"
---

vim.pack.add(_G.plug_spec {
  'stevearc/conform.nvim',
  'mfussenegger/nvim-lint',
  'b0o/schemastore.nvim',
})
-- Formatting
-- See also:
-- - `:h Conform`
-- - `:h conform-options`
-- - `:h conform-formatters`
require('conform').setup {
  default_format_opts = {
    timeout_ms = 3000,
    async = false,           -- not recommended to change
    quiet = false,           -- not recommended to change
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

VimRc.linters_by_ft = {
  cmake = { 'cmakelint' }, -- Install: uv tool install cmakelint, repo: https://github.com/cmake-lint/cmake-lint
  python = { 'mypy' },
  yaml = { 'yamlint' },    --Install: uv tool install yamllint, repo: https://github.com/adrienverge/yamllint
  bash = { 'shellcheck' },
  sh = { 'shellcheck' },
  zsh = { 'zsh', 'shellcheck' },
  ['yaml.ghaction'] = { 'actionlint' }, -- Install: go install github.com/rhysd/actionlint/cmd/actionlint@latest, repo: https://github.com/rhysd/actionlint
}
function VimRc.current_linters()
  local Lint = require 'lint'
  return Lint.get_running()
end

function VimRc.filetype_linters()
  local Lint = require 'lint'
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  return Lint._resolve_linter_by_ft(ft)
end

function VimRc.do_lint()
  -- Use nvim-lint's logic first:
  -- * checks if linters exist for the full filetype first
  -- * otherwise will split filetype by "." and add all those linters
  -- * this differs from conform.nvim which only uses the first filetype that has a formatter
  local lint = require 'lint'
  local names = lint._resolve_linter_by_ft(vim.bo.filetype)

  -- Create a copy of the names table to avoid modifying the original.
  names = vim.list_extend({}, names)

  -- Add fallback linters.
  if #names == 0 then
    vim.list_extend(names, lint.linters_by_ft['_'] or {})
  end

  -- Add global linters.
  vim.list_extend(names, lint.linters_by_ft['*'] or {})

  -- Filter out linters that don't exist or don't match the condition.
  local ctx = { filename = vim.api.nvim_buf_get_name(0) }
  ctx.dirname = vim.fn.fnamemodify(ctx.filename, ':h')
  names = vim.tbl_filter(function(name)
    local linter = lint.linters[name]
    if not linter then
      _G.warn('Linter not found: ' .. name, { title = 'nvim-lint' })
      return false
    end
    return true
  end, names)

  -- Run linters.
  if #names > 0 then
    lint.try_lint(names)
  end
end

local lint = require 'lint'
lint.linters_by_ft = VimRc.linters_by_ft

_G.new_autocmd("User", function()
    if vim.g.run_linter_after_save then
      M.debounce(100, VimRc.do_lint)
    end
  end,
  { 'BufWritePost', 'BufReadPost', 'InsertLeave' },
  "Automatic linter run")


vim.api.nvim_create_user_command('ViewLinter', function()
  local cur = VimRc.current_linters()
  local ft = VimRc.filetype_linters()
  vim.notify('Current running linters: ' .. table.concat(cur, ', '))
  vim.notify('ft linters: ' .. table.concat(ft, ', '))
end, { desc = 'View Running Linters' })

vim.api.nvim_create_user_command('Lint', function()
  VimRc.do_lint()
end, { desc = 'View Running Linters' })

local prefix = '<leader>l'
_G.keymaps_define({
    { lhs = prefix .. 'l', rhs = '<cmd>Lint<cr>', opts = { desc = 'Lint' } },
  },
  { prefix = prefix, group = "Lint" })
