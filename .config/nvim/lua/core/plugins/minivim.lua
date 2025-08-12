return { -- Collection of various small independent plugins/modules
  'echasnovski/mini.nvim',

  keys = {
    {
      '\\',
      function()
        local files = require 'mini.files'
        files.open(vim.api.nvim_buf_get_name(0))
      end,
      desc = 'Open mini-files file navigator',
      silent = true,
    },
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

    --

    require('mini.files').setup {

      -- Customization of shown content
      content = {
        -- Predicate for which file system entries to show
        filter = nil,
        -- What prefix to show to the left of file system entry
        prefix = nil,
        -- In which order to show file system entries
        sort = nil,
      },

      -- Module mappings created only inside explorer.
      -- Use `''` (empty string) to not create one.
      mappings = {
        close = 'q',
        go_in = 'l',
        go_in_plus = 'L',
        -- I swapped the following 2 (default go_out: h)
        -- go_out_plus: when you go out, it shows you only 1 item to the right
        -- go_out: shows you all the items to the right
        -- Default <h>
        go_out = 'H',
        -- Default <H>
        go_out_plus = '<Left>',
        mark_goto = "'",
        mark_set = 'm',
        -- Default <BS>
        reset = ',',
        -- Default @
        reveal_cwd = '.',
        show_help = '?',
        synchronize = 's',
        trim_left = '<',
        trim_right = '>',
      },
      windows = {
        preview = true,
        width_focus = 30,
        width_preview = 80,
      },

      -- General options
      options = {
        -- Whether to delete permanently or move into module-specific trash
        permanent_delete = false,
        -- Whether to use for editing directories
        use_as_default_explorer = true,
      },
    }

    --[[
            Create mapping to show/hide dot-files ~
            Create an autocommand for `MiniFilesBufferCreate` event which calls
            `MiniFiles.refresh()` with explicit `content.filter` functions:
        ]]
    --

    local show_dotfiles = true

    local filter_show = function(fs_entry)
      return true
    end

    local filter_hide = function(fs_entry)
      return not vim.startswith(fs_entry.name, '.')
    end

    local toggle_dotfiles = function()
      show_dotfiles = not show_dotfiles
      local new_filter = show_dotfiles and filter_show or filter_hide
      MiniFiles.refresh { content = { filter = new_filter } }
    end

    vim.api.nvim_create_autocmd('User', {
      pattern = 'MiniFilesBufferCreate',
      callback = function(args)
        local buf_id = args.data.buf_id
        -- Tweak left-hand side of mapping to your liking
        vim.keymap.set('n', '.', toggle_dotfiles, { buffer = buf_id })
      end,
    })

    -- Use |MiniFiles.set_bookmark()| inside `MiniFilesExplorerOpen` event: >lua

    local set_mark = function(id, path, desc)
      MiniFiles.set_bookmark(id, path, { desc = desc })
    end
    vim.api.nvim_create_autocmd('User', {
      pattern = 'MiniFilesExplorerOpen',
      callback = function()
        set_mark('c', vim.fn.stdpath 'config', 'Config') -- path
        set_mark('w', vim.fn.getcwd, 'Working directory') -- callable
        set_mark('~', '~', 'Home directory')
      end,
    })
    -- Create mappings to modify target window via split ~
    -- Combine |MiniFiles.get_explorer_state()| and |MiniFiles.set_target_window()|: >lua

    local map_split = function(buf_id, lhs, direction)
      local rhs = function()
        -- Make new window and set it as target
        local cur_target = MiniFiles.get_explorer_state().target_window
        local new_target = vim.api.nvim_win_call(cur_target, function()
          vim.cmd(direction .. ' split')
          return vim.api.nvim_get_current_win()
        end)

        MiniFiles.set_target_window(new_target)

        -- This intentionally doesn't act on file under cursor in favor of
        -- explicit "go in" action (`l` / `L`). To immediately open file,
        -- add appropriate `MiniFiles.go_in()` call instead of this comment.
      end

      -- Adding `desc` will result into `show_help` entries
      local desc = 'Split ' .. direction
      vim.keymap.set('n', lhs, rhs, { buffer = buf_id, desc = desc })
    end

    vim.api.nvim_create_autocmd('User', {
      pattern = 'MiniFilesBufferCreate',
      callback = function(args)
        local buf_id = args.data.buf_id
        -- Tweak keys to your liking
        map_split(buf_id, '<C-s>', 'belowright horizontal')
        map_split(buf_id, '<C-v>', 'belowright vertical')
        map_split(buf_id, '<C-t>', 'tab')
      end,
    })
  end,
}
