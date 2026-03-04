vim.pack.add(_G.plug_spec {
  'stevearc/conform.nvim',
  'stevearc/overseer.nvim',
  'mfussenegger/nvim-lint',
  'b0o/schemastore.nvim',
  'MeanderingProgrammer/render-markdown.nvim',
})

local miniclue = require 'mini.clue'
miniclue.enable_all_triggers()
miniclue.setup {
  triggers = {
    -- Builtins.
    { mode = { 'n', 'x' }, keys = 'g' },
    { mode = { 'n', 'x' }, keys = '`' },
    { mode = { 'n', 'x' }, keys = '"' },
    { mode = { 'i', 'c' }, keys = '<C-r>' },
    { mode = 'n', keys = '<C-w>' },
    { mode = 'i', keys = '<C-x>' },
    { mode = 'n', keys = 'z' },
    -- Leader triggers.
    { mode = { 'n', 'x' }, keys = '<leader>' },
    -- Moving between stuff.
    { mode = 'n', keys = '[' },
    { mode = 'n', keys = ']' },
  },
  clues = {
    -- Leader/movement groups.
    { mode = { 'n', 'x' }, keys = '<leader>a', desc = '+ai' },
    { mode = { 'n', 'x' }, keys = '<leader>c', desc = '+code' },
    { mode = { 'n', 'x' }, keys = '<leader>f', desc = '+find' },
    { mode = 'n', keys = '<leader>b', desc = '+buffers' },
    { mode = 'n', keys = '<leader>d', desc = '+debug' },
    { mode = 'n', keys = '<leader>t', desc = '+tabs' },
    { mode = 'n', keys = '<leader>x', desc = '+loclist/quickfix' },
    { mode = 'n', keys = '[', desc = '+prev' },
    { mode = 'n', keys = ']', desc = '+next' },
    -- Builtins.
    miniclue.gen_clues.g(),
    miniclue.gen_clues.marks(),
    miniclue.gen_clues.registers(),
    miniclue.gen_clues.windows(),
    miniclue.gen_clues.z(),
  },
  window = {
    delay = 500,
  },
}
require 'extras.overseer'
require 'extras.quicker'
require('render-markdown').setup(
  ---@type render.md.Settings
  {
    preset = 'obsidian',
    completions = {
      lsp = {
        enabled = true,
      },
    },
    pipe_table = {
      preset = 'round',
    },
  }
)
-- Formatting
-- See also:
-- - `:h Conform`
-- - `:h conform-options`
-- - `:h conform-formatters`
vim.g.disable_autoformat = false
require 'custom.format'
vim.g.disabled_autolinting = false
require 'custom.lint'

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
require 'extras.git'
require 'extras.optional.grug'
-- require 'extras.codecompanion'
