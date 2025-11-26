vim.pack.add(_G.plug_spec { 'ibhagwan/fzf-lua' })

local icons = VimRc.icons
---@diagnostic disable-next-line: duplicate-set-field
vim.ui.select = function(items, opts, on_choice)
  local ui_select = require 'fzf-lua.providers.ui_select'

  -- Register the fzf-lua picker the first time we call select.
  if not ui_select.is_registered() then
    ui_select.register(function(ui_opts)
      if ui_opts.kind == 'luasnip' then
        ui_opts.prompt = 'Snippet choice: '
        ui_opts.winopts = {
          relative = 'cursor',
          height = 0.35,
          width = 0.3,
        }
      elseif ui_opts.kind == 'color_presentation' then
        ui_opts.winopts = {
          relative = 'cursor',
          height = 0.35,
          width = 0.3,
        }
      else
        ui_opts.winopts = { height = 0.5, width = 0.4 }
      end

      -- Use the kind (if available) to set the previewer's title.
      if ui_opts.kind then
        ui_opts.winopts.title = string.format(' %s ', ui_opts.kind)
      end

      return ui_opts
    end)
  end

  -- Don't show the picker if there's nothing to pick.
  if #items > 0 then
    return vim.ui.select(items, opts, on_choice)
  end
end
require 'plugin.fzf-lua'
require 'plugin.mini-pick'

local ok, grug = pcall(require, 'plugin.grug')
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
