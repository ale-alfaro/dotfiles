return {
  {
    'mrjones2014/smart-splits.nvim',
    lazy = false,
    dependencies = {
      'folke/snacks.nvim',
    },
    -- init = function()
    --   vim.g.smart_splits_multiplexer_integration = 'wezterm'
    -- end,
    -- stylua: ignore
    keys = {
      --   -- resizing splits
      { '<A-h>',      function() require('smart-splits').resize_left() end,       desc = 'Resize left' },
      { '<A-j>',      function() require('smart-splits').resize_down() end,       desc = 'Resize down' },
      { '<A-k>',      function() require('smart-splits').resize_up() end,         desc = 'Resize up' },
      { '<A-l>',      function() require('smart-splits').resize_right() end,      desc = 'Resize right' },
      --   -- moving between splits
      { '<C-h>',      function() require('smart-splits').move_cursor_left() end,  desc = 'Move window left' },
      { '<C-j>',      function() require('smart-splits').move_cursor_down() end,  desc = 'Move window down' },
      { '<C-k>',      function() require('smart-splits').move_cursor_up() end,    desc = 'Move window up' },
      { '<C-l>',      function() require('smart-splits').move_cursor_right() end, desc = 'Move window right' },
      --   -- swapping buffers between windows
      { '<leader>wt', '<cmd>WeztermTerm<cr>',                                     desc = 'Spawn Terminal (Wezterm)' },
      { '<leader>ws', '<cmd>WeztermWorkspace<cr>',                                desc = 'Switch Workspace (Wezterm)' },
    },
    opts = function(_, opts)
      opts = opts or {}
      opts = {
        -- Ignored buffer types (only while resizing)
        ignored_buftypes = {
          'snacks_picker_list',
          'codecompanion',
        },
        -- Ignored filetypes (only while resizing)
        ignored_filetypes = { 'snacks_picker_list', 'codecompanion' },
        -- the default number of lines/columns to resize by at a time
        --   -- for example `10<A-h>` will `resize_left` by `(10 * config.default_amount)`
        default_amount = 3,
        -- when moving cursor between splits left or right,
        -- place the cursor on the same row of the *screen*
        -- regardless of line numbers. False by default.
        -- Can be overridden via function parameter, see Usage.
        move_cursor_same_row = true,
      }
      opts.at_edge = 'wrap'
      opts.log_level = 'debug'
      require('custom.wezterm.wezterm_terminal').setup()
    end,
  },
}
