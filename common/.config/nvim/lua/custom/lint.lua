local lint = require 'lint'
lint.linters_by_ft = {
  c = { 'clangtidy' }, -- Install: uv tool install cmakelint, repo: https://github.com/cmake-lint/cmake-lint
  cmake = { 'cmakelint' }, -- Install: uv tool install cmakelint, repo: https://github.com/cmake-lint/cmake-lint
  python = { 'ruff' },
  yaml = { 'yamlint' }, --Install: uv tool install yamllint, repo: https://github.com/adrienverge/yamllint
  bash = { 'shellcheck' },
  sh = { 'shellcheck' },
  zsh = { 'zsh', 'shellcheck' },
  ['yaml.ghaction'] = { 'actionlint' }, -- Install: go install github.com/rhysd/actionlint/cmd/actionlint@latest, repo: https://github.com/rhysd/actionlint
}

---@return string[]
function VimRc.current_linters()
  return require('lint').get_running()
end

function VimRc.filetype_linters()
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  return require('lint')._resolve_linter_by_ft(ft)
end

---@param bufnr? integer buffer for which to get the running linters. nil=all buffers
function VimRc.do_lint(bufnr)
  -- Use nvim-lint's logic first:
  -- * checks if linters exist for the full filetype first
  -- * otherwise will split filetype by "." and add all those linters
  -- * this differs from conform.nvim which only uses the first filetype that has a formatter
  local names = require('lint')._resolve_linter_by_ft(vim.bo[bufnr].filetype)

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
    require('lint').try_lint(names)
  end
end
VimRc.new_autocmd('BufWritePost', function(args)
  if not vim.api.nvim_buf_is_valid(args.buf) or vim.bo[args.buf].buftype ~= '' then
    return
  end
  if VimRc.feature_flag_check('Lint', args.buf) then
    VimRc.setTimeout(100, function()
      VimRc.do_lint(args.buf)
    end)
  end
end, 'Lint on save')

vim.api.nvim_create_user_command('ViewLinter', function()
  local cur = VimRc.current_linters()
  local ft = VimRc.filetype_linters()
  vim.notify('Current running linters: ' .. table.concat(cur, ', '))
  vim.notify('ft linters: ' .. table.concat(ft, ', '))
end, { desc = 'View Running Linters' })

vim.api.nvim_create_user_command('Lint', function()
  VimRc.do_lint()
end, { desc = 'View Running Linters' })
