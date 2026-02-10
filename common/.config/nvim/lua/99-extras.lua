---

vim.pack.add(_G.plug_spec {
  'stevearc/conform.nvim',
  'stevearc/overseer.nvim',
  'mfussenegger/nvim-lint',
  'b0o/schemastore.nvim',
  'MeanderingProgrammer/render-markdown.nvim',
})

require 'plugin.overseer'
local ok, quicker = pcall(require, 'plugin.quicker')
if ok then
  VimRc.pack_add(quicker)
end
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
require 'plugin.git'
require 'plugin.codecompanion'

--[[
--
--  OPTIONAL PLUGINS (DISABLED BY DEFAULT)
--]]
--
-- Flash
if vim.g.flash then
  local flash
  ok, flash = pcall(require, 'plugin.flash')
  if ok then
    VimRc.pack_add(flash)
  end
end
if vim.g.grug then
  local grug
  ok, grug = pcall(require, 'plugin.grug')
  if ok then
    VimRc.pack_add(grug)
    -- grug-far main buffers will have `filetype=grug-far`.
    -- grug-far history buffers will have `filetype=grug-far-history`
    -- grug-far help buffers will have `filetype=grug-far-help`
    _G.new_autocmd('FileType', function()
      vim.keymap.set('n', '<C-enter>', function()
        local inst = require('grug-far').get_instance(0)
        if inst then
          inst:open_location()
          inst:close()
        end
      end, { buffer = true })
    end, 'grug-far*', 'Keep one instance of grug')
  end
end

if vim.g.dap_debugging then
  local dap = require 'plugin.dap'
  VimRc.pack_add(dap)
end
