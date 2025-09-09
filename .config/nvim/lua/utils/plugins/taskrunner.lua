return {
  'al1-ce/just.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim', -- async jobs
    'nvim-telescope/telescope.nvim', -- task picker (optional)
    'rcarriga/nvim-notify', -- general notifications (optional)
    'j-hui/fidget.nvim', -- task progress (optional)
    'al1-ce/jsfunc.nvim', -- extension library
  },

  ft = 'just',
  config = function()
    require('just').setup {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      -- for more information
      -- you can also put your configuration here
      -- if you want to override the default settings
    }
  end,
  keys = {

    {
      '<leader>rr',
      '<cmd>JustSelect<cr>',
      mode = 'n',
      desc = 'Gives you selection of all tasks in justfile.',
    },
    { '<leader>jt', '<cmd>JustCreateTemplate <cr>', desc = 'Creates template justfile with included cheatsheet' },
    {
      '<leader>jm',
      '<cmd>JustCreateMakeTemplate <cr>',
      mode = 'n',
      desc = 'Creates make-like template justfile to allow compiling only changed files.',
    },
    {
      '<leader>bc',
      '<cmd>JustStop<cr>',
      mode = 'n',
      desc = 'Stops currently running task.',
    },
  },
}
