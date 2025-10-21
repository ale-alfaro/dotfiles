
vim.pack.add(_G.plug_spec({
 'nvim-treesitter/nvim-treesitter',
 'nvim-treesitter/nvim-treesitter-textobjects',
}))
-- Treesitter
require('nvim-treesitter')
    .install({
      'bash',
      'c',
      'cpp',
      'cmake',
      'diff',
      'html',
      'kconfig',
      'lua',
      'luadoc',
      'markdown',
      'python',
      'markdown_inline',
      'query',
      'vim',
      'vimdoc',
      'just',
      'json5',
      'toml',
      'ninja',
      'rst',
      'yaml',
    })
    :wait(300000) -- max. 5 minutes

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'zsh', 'lua', 'bash', 'just' },
  callback = function()
    -- syntax highlighting, provided by Neovim
    vim.treesitter.start()
    -- folds, provided by Neovim
    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    -- indentation, provided by nvim-treesitter
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

require('nvim-treesitter-textobjects').setup {
  move = {
    enable = true,
    set_jumps = true,
    keys = {
      goto_next_start = { [']f'] = '@function.outer', [']c'] = '@class.outer', [']a'] = '@parameter.inner' },
      goto_next_end = { [']F'] = '@function.outer', [']C'] = '@class.outer', [']A'] = '@parameter.inner' },
      goto_previous_start = { ['[f'] = '@function.outer', ['[c'] = '@class.outer', ['[a'] = '@parameter.inner' },
      goto_previous_end = { ['[F'] = '@function.outer', ['[C'] = '@class.outer', ['[A'] = '@parameter.inner' },
    },
  },
}
require('mini.extra').setup()
local ai = require 'mini.ai'
ai.setup {
  n_lines = 500,
  custom_textobjects = {
    o = ai.gen_spec.treesitter { -- code block
      a = { '@block.outer', '@conditional.outer', '@loop.outer' },
      i = { '@block.inner', '@conditional.inner', '@loop.inner' },
    },
    f = ai.gen_spec.treesitter { a = '@function.outer', i = '@function.inner' }, -- function
    c = ai.gen_spec.treesitter { a = '@class.outer', i = '@class.inner' },       -- class
    t = { '<([%p%w]-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' },          -- tags
    d = { '%f[%d]%d+' },                                                         -- digits
    e = {                                                                        -- Word with case
      { '%u[%l%d]+%f[^%l%d]', '%f[%S][%l%d]+%f[^%l%d]', '%f[%P][%l%d]+%f[^%l%d]', '^[%l%d]+%f[^%l%d]' },
      '^().*()$',
    },
    g = _G.Utils.mini.ai_buffer,                              -- buffer
    u = ai.gen_spec.function_call(),                          -- u for "Usage"
    U = ai.gen_spec.function_call { name_pattern = '[%w_]' }, -- without dot in function name
  },
}
require 'plugin.blink-cmp'
require('mini.align').setup()
-- require('mini.bracketed').setup()
require('mini.bufremove').setup()
_G.Utils.keymaps.define {
  { lhs = '<leader>bd', rhs = '<Cmd>lua MiniBufremove.delete()<CR>',         opts = { desc = 'Delete' } },
  { lhs = '<leader>bD', rhs = '<Cmd>lua MiniBufremove.delete(0, true)<CR>',  opts = { desc = 'Delete!' } },
  { lhs = '<leader>bw', rhs = '<Cmd>lua MiniBufremove.wipeout()<CR>',        opts = { desc = 'Wipeout' } },
  { lhs = '<leader>bW', rhs = '<Cmd>lua MiniBufremove.wipeout(0, true)<CR>', opts = { desc = 'Wipeout!' } },
}
require('mini.comment').setup()
require('mini.indentscope').setup()
-- require('mini.move').setup()
_G.Utils.mini.pairs {
  modes = { insert = true, command = true, terminal = false },
  -- skip autopair when next character is one of these
  skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
  -- skip autopair when the cursor is inside these treesitter nodes
  skip_ts = { 'string' },
  -- skip autopair when next character is closing pair
  -- and there are more closing pairs than opening pairs
  skip_unbalanced = true,
  -- better deal with markdown code blocks
  markdown = true,
}
-- require('mini.splitjoin').setup()
require('mini.surround').setup {
  mappings = {
    add = 'gsa',            -- Add surrounding in Normal and Visual modes
    delete = 'gsd',         -- Delete surrounding
    find = 'gsf',           -- Find surrounding (to the right)
    find_left = 'gsF',      -- Find surrounding (to the left)
    highlight = 'gsh',      -- Highlight surrounding
    replace = 'gsr',        -- Replace surrounding
    update_n_lines = 'gsn', -- Update `n_lines`
  },
}
