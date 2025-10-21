vim.pack.add(_G.plug_spec({'ibhagwan/fzf-lua' }))

local icons = require 'icons'
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
