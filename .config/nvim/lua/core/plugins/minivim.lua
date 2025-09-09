return { -- Collection of various small independent plugins/modules
  'echasnovski/mini.nvim',

  keys = {
    {
      '<leader>m',
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
    require('mini.ai').setup {
      -- Table with textobject id as fields, textobject specification as values.
      -- Also use this to disable builtin textobjects. See |MiniAi.config|.
      custom_textobjects = {
        -- Treesitter textobjects
        f = require('mini.ai').gen_spec.treesitter { a = '@function.outer', i = '@function.inner' },
        c = require('mini.ai').gen_spec.treesitter { a = '@class.outer', i = '@class.inner' },
        o = require('mini.ai').gen_spec.treesitter { a = '@loop.outer', i = '@loop.inner' },
        i = require('mini.ai').gen_spec.treesitter { a = '@conditional.outer', i = '@conditional.inner' },
      },

      -- Module mappings. Use `''` (empty string) to disable one.
      mappings = {
        -- Main textobject prefixes
        around = 'a',
        inside = 'i',

        -- Next/last variants
        -- NOTE: These override built-in LSP selection mappings on Neovim>=0.12
        -- Map LSP selection manually to use it (see `:h MiniAi.config`)
        around_next = 'an',
        inside_next = 'in',
        around_last = 'al',
        inside_last = 'il',

        -- Move cursor to corresponding edge of `a` textobject
        goto_left = 'g[',
        goto_right = 'g]',
      },

      -- Number of lines within which textobject is searched
      n_lines = 50,

      -- How to search for object (first inside current line, then inside
      -- neighborhood). One of 'cover', 'cover_or_next', 'cover_or_prev',
      -- 'cover_or_nearest', 'next', 'previous', 'nearest'.
      search_method = 'cover_or_next',

      -- Whether to disable showing non-error feedback
      -- This also affects (purely informational) helper messages shown after
      -- idle time if user input is required.
      silent = false,
    }

    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require('mini.surround').setup {
      -- Add custom surroundings to be used on top of builtin ones. For more
      -- information with examples, see `:h MiniSurround.config`.
      custom_surroundings = nil,

      -- Duration (in ms) of highlight when calling `MiniSurround.highlight()`
      highlight_duration = 500,
      mappings = {
        add = 'sa',
        delete = 'sd',
        find = 'sf',
        find_left = 'sF',
        highlight = 'sh',
        replace = 'sr',
        update_n_lines = 'sn',

        -- Number of lines within which surrounding is searched
        n_lines = 20,

        -- Whether to respect selection type:
        -- - Place surroundings on separate lines in linewise mode.
        -- - Place surroundings on each line in blockwise mode.
        respect_selection_type = false,

        -- How to search for surrounding (first inside current line, then inside
        -- neighborhood). One of 'cover', 'cover_or_next', 'cover_or_prev',
        -- 'cover_or_nearest', 'next', 'prev', 'nearest'. For more details,
        -- see `:h MiniSurround.config`.
        search_method = 'cover',

        -- Whether to disable showing non-error feedback
        -- This also affects (purely informational) helper messages shown after
        -- idle time if user input is required.
        silent = true,
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
        mark_goto = 'g',
        mark_set = 'm',
        reset = '<BS>',
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
        use_as_default_explorer = false, -- Don't override oil as default
      },
    }

    --
    -- --[[
    --         Create mapping to show/hide dot-files ~
    --         Create an autocommand for `MiniFilesBufferCreate` event which calls
    --         `MiniFiles.refresh()` with explicit `content.filter` functions:
    --     ]]
    local show_dotfiles = true

    local filter_show = function(fs_entry)
      return true
    end

    local filter_hide = function(fs_entry)
      return not vim.startswith(fs_entry.name, '.')
    end
    local MiniFiles = require 'mini.files'
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
    -- -- Use |MiniFiles.set_bookmark()| inside `MiniFilesExplorerOpen` event: >lua
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

    -- -- Create mappings to modify target window via split ~
    -- -- Combine |MiniFiles.get_explorer_state()| and |MiniFiles.set_target_window()|: >lua

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
      local desc = 'MiniFiles Split ' .. direction
      vim.keymap.set('n', lhs, rhs, { buffer = buf_id, desc = desc })
    end

    vim.api.nvim_create_autocmd('User', {
      pattern = 'MiniFilesBufferCreate',
      callback = function(args)
        local buf_id = args.data.buf_id
        -- Tweak keys to your liking
        map_split(buf_id, '<leader>ml', 'belowright horizontal')
        map_split(buf_id, '<leader>md', 'belowright vertical')
        map_split(buf_id, '<leader>mt', 'tab')
      end,
    })
  end,
}
--
--
