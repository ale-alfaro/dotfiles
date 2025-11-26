-- Snippets.
---@return VimPackPlugin
return {
    name = 'luasnip',
    plugin = _G.plug_spec { 'L3MON4D3/LuaSnip' },
    config = function()
      local types = require 'luasnip.util.types'
      ---@diagnostic disable: undefined-field
      require ('luasnip').setup {
        -- Check if the current snippet was deleted.
        delete_check_events = 'TextChanged',
        -- Display a cursor-like placeholder in unvisited nodes
        -- of the snippet.
        ext_opts = {
          [types.insertNode] = {
            unvisited = {
              virt_text = { { '|', 'Conceal' } },
              virt_text_pos = 'inline',
            },
          },
          [types.exitNode] = {
            unvisited = {
              virt_text = { { '|', 'Conceal' } },
              virt_text_pos = 'inline',
            },
          },
          [types.choiceNode] = {
            active = {
              virt_text = { { '(snippet) choice node', 'LspInlayHint' } },
            },
          },
        },
      }

      -- Load my custom snippets:
      require('luasnip.loaders.from_vscode').lazy_load {
        paths = vim.fn.stdpath 'config' .. '/snippets',
      }

      -- Use <C-c> to select a choice in a snippet.
      vim.keymap.set({ 'i', 's' }, '<C-c>', function()
        if luasnip.choice_active() then
          require 'luasnip.extras.select_choice'()
        end
      end, { desc = 'Select choice' })
      ---@diagnostic enable: undefined-field
    end,
  keys = {
    {
      mode = { 'i' },
      lhs = '<C-r>s',
      rhs = function()
        require('luasnip.extras.otf').on_the_fly 's'
      end,
      opts = { desc = 'Insert on-the-fly snippet' },
    },
  },
}
