require 'plugin.git'
require 'plugin.codecompanion'

local ok, quicker = pcall(require, 'plugin.quicker')
if ok then
  VimRc.pack_add(quicker)
end
-- Flash
--
local ok, flash = pcall(require, 'plugin.flash')
if ok then
  VimRc.pack_add(flash)
end

vim.pack.add(_G.plug_spec {
  'obsidian-nvim/obsidian.nvim',
  'MeanderingProgrammer/render-markdown.nvim',
})
-- Obsidian is loaded in after/ftplugin/markdown.lua

local ok, render_md = pcall(require, 'render-markdown')
if ok then
  render_md.setup {
    preset = 'obsidian',
    completions = { lsp = { enabled = true } },
  }
else
  _G.error "Couldn't load render-markdown.nvim plugin"
end

local dap = require 'plugin.dap'
VimRc.pack_add(dap)
