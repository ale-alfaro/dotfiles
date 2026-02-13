--[[
--
--  OPTIONAL PLUGINS (DISABLED BY DEFAULT)
--]]
if not MiniCompletion then
  _G.plug('Saghen/blink.cmp', {
    build_hook = {
      plugin = 'blink.cmp',
      build_cmd_type = 'shell',
      build_cmd = 'cargo build --release',
    },
  })
  local ok, _ = pcall(require, 'plugin.blink-cmp')
  if not ok then
    VimRc.error 'Failed to load blink.cmp'
  end
end
if not MiniSnippets then
  _G.plug('/blink.cmp', {
    build_hook = {
      plugin = 'blink.cmp',
      build_cmd_type = 'shell',
      build_cmd = 'cargo build --release',
    },
  })
  local ok, luasnip = pcall(require, 'luasnip')
  if ok then
    luasnip.setup { enable_autosnippets = true }
    require('luasnip.loaders.from_lua').load { paths = '~/.config/nvim/snippets/' }
    -- VimRc.pack_add(luasnip)
  end
end
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
