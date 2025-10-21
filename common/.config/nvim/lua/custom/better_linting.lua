---@module "lint"
local M = {}

function M.current_linters()
  local Lint = require 'lint'
  return Lint.get_running()
end

function M.filetype_linters()
  local Lint = require 'lint'
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  return Lint._resolve_linter_by_ft(ft)
end

function M.do_lint()
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
    ---@type lint.Linter|fun():lint.Linter
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

function M.setup(opts)
  local lint = require 'lint'

  function M.debounce(ms, fn)
    local timer = vim.uv.new_timer()
    return function(...)
      local argv = { ... }
      timer:start(ms, 0, function()
        timer:stop()
        vim.schedule_wrap(fn)(unpack(argv))
      end)
    end
  end

  for name, linter in pairs(opts.linters) do
    if type(linter) == 'table' and type(lint.linters[name]) == 'table' then
      lint.linters[name] = vim.tbl_deep_extend('force', lint.linters[name], linter)
      if type(linter.prepend_args) == 'table' then
        lint.linters[name].args = lint.linters[name].args or {}
        vim.list_extend(lint.linters[name].args, linter.prepend_args)
      end
    else
      lint.linters[name] = linter
    end
  end
  lint.linters_by_ft = opts.linters_by_ft
  vim.api.nvim_create_autocmd(opts.events, {
    group = vim.api.nvim_create_augroup('nvim-lint', { clear = true }),
    callback = M.debounce(100, M.do_lint),
  })

  vim.api.nvim_create_user_command('ViewLinter', function()
    local cur = M.current_linters()
    local ft = M.filetype_linters()
    vim.notify('Current running linters: ' .. table.concat(cur, ', '))
    vim.notify('ft linters: ' .. table.concat(ft, ', '))
  end, {
    desc = 'View Running Linters',
  })

  vim.api.nvim_create_user_command('Lint', function()
    M.do_lint()
  end, {
    desc = 'Run Linter',
  })
end

return M
