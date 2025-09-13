return {
  {
    'ibhagwan/fzf-lua',
    keys = {
      { '<leader>sh', '<cmd>FzfLua help_tags<cr>', desc = 'Help Pages' },
      { '<leader>sk', '<cmd>FzfLua keymaps<cr>', desc = 'Key Maps' },
      { '<leader>sM', '<cmd>FzfLua man_pages<cr>', desc = 'Man Pages' },
      { '<leader>sm', '<cmd>FzfLua marks<cr>', desc = 'Jump to Mark' },
      { '<leader>sR', '<cmd>FzfLua resume<cr>', desc = 'Resume' },
    },
  },
  -- {
  --   'neovim/nvim-lspconfig',
  --   opts = function()
  --     local Keys = require('lazyvim.plugins.lsp.keymaps').get()
  --     vim.list_extend(Keys, {
  --       { 'gd', '<cmd>FzfLua lsp_definitions     jump1=true ignore_current_line=true<cr>', desc = 'Goto Definition', has = 'definition' },
  --       { 'gr', '<cmd>FzfLua lsp_references      jump1=true ignore_current_line=true<cr>', desc = 'References', nowait = true },
  --       { 'gI', '<cmd>FzfLua lsp_implementations jump1=true ignore_current_line=true<cr>', desc = 'Goto Implementation' },
  --       { 'gy', '<cmd>FzfLua lsp_typedefs        jump1=true ignore_current_line=true<cr>', desc = 'Goto T[y]pe Definition' },
  --     })
  --   end,
  -- },
  -- {
  --   'folke/todo-comments.nvim',
  --   optional = true,
  -- },
}

