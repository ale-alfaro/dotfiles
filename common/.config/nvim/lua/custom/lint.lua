VimRc.linters_by_ft = {
  cmake = { 'cmakelint' }, -- Install: uv tool install cmakelint, repo: https://github.com/cmake-lint/cmake-lint
  python = { 'mypy' },
  yaml = { 'yamlint' }, --Install: uv tool install yamllint, repo: https://github.com/adrienverge/yamllint
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
      VimRc.warn('Linter not found: ' .. name)
      return false
    end
    return true
  end, names)

  -- Run linters.
  if #names > 0 then
    lint.try_lint(names)
  end
end

VimRc.autolint_events = { 'BufWritePost', 'BufReadPost', 'InsertLeave' }

local lint = require 'lint'
lint.linters_by_ft = VimRc.linters_by_ft
vim.g.disabled_autolinting = true
local aug = vim.api.nvim_create_augroup('Lint', { clear = true })
vim.api.nvim_create_autocmd(VimRc.autolint_events, {
  desc = 'Lint on save',
  pattern = '*',
  group = aug,
  callback = function(args)
    if not vim.api.nvim_buf_is_valid(args.buf) or vim.bo[args.buf].buftype ~= '' then
      return
    end
    if not vim.g.disabled_autolinting then
      VimRc.setTimeout(100, VimRc.do_lint)
    end
  end,
})

vim.api.nvim_create_user_command('ViewLinter', function()
  local cur = VimRc.current_linters()
  local ft = VimRc.filetype_linters()
  vim.notify('Current running linters: ' .. table.concat(cur, ', '))
  vim.notify('ft linters: ' .. table.concat(ft, ', '))
end, { desc = 'View Running Linters' })

vim.api.nvim_create_user_command('Lint', function()
  VimRc.do_lint()
end, { desc = 'View Running Linters' })
