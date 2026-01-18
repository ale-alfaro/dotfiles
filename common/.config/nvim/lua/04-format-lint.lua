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
require('custom.format').setup()
require('custom.lint').setup()

vim.api.nvim_create_user_command('FormatDisable', function(args)
  if args.bang then
    -- FormatDisable! will disable formatting just for this buffer
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
  end
end, {
  desc = 'Disable autoformat-on-save',
  bang = true,
})

vim.api.nvim_create_user_command('FormatEnable', function()
  vim.b.disable_autoformat = false
  vim.g.disable_autoformat = false
end, {
  desc = 'Re-enable autoformat-on-save',
})

vim.api.nvim_create_user_command('LintToggle', function()
  vim.g.disable_autolinting = not vim.g.disable_autolinting
end, {
  desc = 'Re-enable lint-on-save',
})
local prefix = '<leader>l'
KEYS.define({
  { lhs = prefix .. 'l', rhs = '<cmd>Lint<cr>', opts = { desc = 'Lint' } },
  { lhs = prefix .. 'f', rhs = '<cmd>Format<cr>', opts = { desc = 'Format' } },
  { lhs = prefix .. 'd', rhs = '<cmd>FormatDisable! <cr>', opts = { desc = 'FormatDisable (buffer)' } },
  { lhs = prefix .. 't', rhs = '<cmd>LintToggle<cr>', opts = { desc = 'LintToggle' } },
  { lhs = prefix .. 'v', rhs = '<cmd>ViewLinter<cr>', opts = { desc = 'View Linter(s)' } },
}, { prefix = prefix, group = 'Lint/Format' })
-- Linting
