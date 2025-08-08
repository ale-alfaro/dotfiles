return { -- Collection of various small independent plugins/modules
  'echasnovski/mini.nvim',

  keys = {
    { '\\', ':lua MiniFiles.open()<CR>', desc = 'Open mini-files file navigator', silent = true },
  },
  config = function()
    -- Better Around/Inside textobjects
    --
    -- Examples:
    --  - va)  - [V]isually select [A]round [)]paren
    --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
    --  - ci'  - [C]hange [I]nside [']quote
    require('mini.ai').setup { n_lines = 500 }

    -- Basic configurations for life improvements such as:
    --  * Save with Ctrl-s
    --  * Highlight on yank
    --  ...dsdsa
    -- It will only set the options that are not already set
    require('mini.basics').setup {
      options = {
        extra_ui = true,
      },
      mappings = {
        option_toggle_prefix = '[[|]]',
        windows = true,
        move_with_alt = true,
      },
      autocommands = {
        relnum_in_visual_mode = true,
      },
    }

    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require('mini.surround').setup {
      mappings = {
        add = '<leader>sa',
        delete = '<leader>sd',
        find = 'gsf',
        find_left = 'gsF',
        highlight = 'gsh',
        replace = 'gsr',
        update_n_lines = 'gsn',
      },
    }
    -- Comment Lines!
    -- 'gc' to toggle comment on a line for visual and normal mode
    --
    require('mini.comment').setup()

    -- Simple and easy statusline.
    --  You could remove this setup call if you don't like it,
    --  and try some other statusline plugin
    -- local statusline = require 'mini.statusline'
    -- -- set use_icons to true if you have a Nerd Font
    -- statusline.setup { use_icons = vim.g.have_nerd_font }
    --
    -- -- You can configure sections in the statusline by overriding their
    -- -- default behavior. For example, here we set the section for
    -- -- cursor location to LINE:COLUMN
    -- ---@diagnostic disable-next-line: duplicate-set-field
    -- statusline.section_location = function()
    --   return '%2l:%-2v'
    -- end

    -- ... and there is more!
    --  Check out: https://github.com/echasnovski/mini.nvim
  end,
}
