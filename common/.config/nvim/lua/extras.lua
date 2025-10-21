vim.pack.add(_G.plug_spec({
 'folke/flash.nvim',
 'folke/trouble.nvim',
}))

-- Flash
--
require('flash').setup {
      jump = { nohlsearch = true },
      prompt = {
        win_config = {
            border = 'none',
            -- Place the prompt above the statusline.
            row = -3,
        },
    },
    search = {
        exclude = {
            'flash_prompt',
            'qf',
            function(win)
                -- Non-focusable windows.
                return not vim.api.nvim_win_get_config(win).focusable
            end,
        },
    },
    modes = {
        -- Enable flash when searching with ? or /
        search = { enabled = true },
    }}

_G.Utils.keymaps.define({
  { mode = {'n' ,'o', 'x'}, lhs = 'S', rhs = function() require('flash').treesitter() end, { desc = 'Flash Treesitter' }},
  { mode = 'o', lhs = 'r', rhs = function() require('flash').treesitter_search()end, { desc = 'Treesitter Search' }},
  { mode = 'o', lhs = 'R', rhs = function()require('flash').remote() end, { desc = 'Remote Flash' }},
  { mode = 'c',  lhs = '<c-s>', rhs = function() require('flash').toggle()end , { desc = 'Flash Toggle' }},
  { mode = { 'n', 'o', 'x' }, lhs =  '<c-space>', rhs = function()
  require('flash').treesitter {
    actions = {
      ['<c-space>'] = 'next',
      ['<BS>'] = 'prev',
    },
  }
end, { desc = 'Treesitter Incremental Selection' }}})

-- Trouble
require('trouble').setup {
  modes = {
    lsp = {
      win = { position = 'right' },
    },
  },
}
_G.Utils.keymaps.define({
  { rhs = '<leader>xx', lhs = '<cmd>Trouble diagnostics toggle<cr>', { desc = 'Diagnostics (Trouble)' }},
  { rhs = '<leader>xX', lhs = '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', { desc = 'Buffer Diagnostics (Trouble)' }},
  { rhs = '<leader>cs', lhs = '<cmd>Trouble symbols toggle<cr>', { desc = 'Symbols (Trouble)' }},
  { rhs = '<leader>xS', lhs = '<cmd>Trouble lsp toggle<cr>', { desc = 'LSP references/definitions/... (Trouble)' }},
  { rhs = '<leader>xL', lhs = '<cmd>Trouble loclist toggle<cr>', { desc = 'Location List (Trouble)' }},
  { rhs = '<leader>xQ', lhs = '<cmd>Trouble qflist toggle<cr>', { desc = 'Quickfix List (Trouble)' }},
})

require('plugin.codecompanion')
