return {
  'mrjones2014/smart-splits.nvim',
  lazy = false,
  -- init = function()
  --   vim.g.smart_splits_multiplexer_integration = 'wezterm'
  -- end,
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
  },
    -- stylua: ignore
    keys = {
    --   -- resizing splits
      {'<A-h>', function() require('smart-splits').resize_left()  end, desc = 'Resize left'},
      {'<A-j>', function() require('smart-splits').resize_down()  end, desc = 'Resize down'},
      {'<A-k>', function() require('smart-splits').resize_up()    end, desc = 'Resize up'},
      {'<A-l>', function() require('smart-splits').resize_right() end, desc = 'Resize right'},
    --   -- moving between splits
      {'<C-h>', function() require('smart-splits').move_cursor_left()  end, desc = 'Move window left'},
      {'<C-j>', function() require('smart-splits').move_cursor_down()  end, desc = 'Move window down'},
      {'<C-k>', function() require('smart-splits').move_cursor_up()    end, desc = 'Move window up'},
      {'<C-l>', function() require('smart-splits').move_cursor_right() end, desc = 'Move window right'},
    --   -- swapping buffers between windows
      {'<leader><leader>h', function() require('smart-splits').swap_buf_left()  end, desc = 'Swap buffer left'},
      {'<leader><leader>j', function() require('smart-splits').swap_buf_down()  end, desc = 'Swap buffer down'},
      {'<leader><leader>k', function() require('smart-splits').swap_buf_up()    end, desc = 'Swap buffer up'},
      {'<leader><leader>l', function() require('smart-splits').swap_buf_right() end, desc = 'Swap buffer right'},
      },
}
