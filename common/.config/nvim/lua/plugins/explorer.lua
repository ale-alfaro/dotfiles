---@module "lazyvim"
return {
  {
    'nvim-mini/mini.files',
    keys = {
      {
        '\\',
        function()
          local MiniFiles = require 'mini.files'
          if not MiniFiles.close() then
            MiniFiles.open(vim.api.nvim_buf_get_name(0), true)
          end
        end,
        desc = 'Open mini.files (Directory of Current File)',
      },
      {
        '<leader>\\',
        function()
          local MiniFiles = require 'mini.files'
          if not MiniFiles.close() then
            MiniFiles.open(vim.uv.cwd(), true)
          end
        end,
        desc = 'Open mini.files (cwd)',
      },
    },

    config = function(_, opts)
      require('mini.files').setup(opts)
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
        require('mini.files').refresh { content = { filter = new_filter } }
      end

      local map_split = function(buf_id, lhs, direction, close_on_file)
        local rhs = function()
          local MiniFiles = require 'mini.files'
          local fs_entry = MiniFiles.get_fs_entry()
          if not fs_entry then
            return
          end

          local wezterm = require 'custom.wezterm.wezterm_terminal'
          local Direction = require('smart-splits.types').Direction

          local wezterm_direction
          if direction == 'horizontal' then
            wezterm_direction = Direction.down
          elseif direction == 'vertical' then
            wezterm_direction = Direction.right
          else
            return
          end

          if fs_entry.is_dir then
            wezterm.split_pane(wezterm_direction, fs_entry.path, 30)
          else
            wezterm.spawn_nvim_inst(wezterm_direction, fs_entry.path)
          end

          if close_on_file and not fs_entry.is_dir then
            MiniFiles.close()
          end
        end

        local desc = 'Open in wezterm ' .. direction .. ' split'
        if close_on_file then
          desc = desc .. ' and close'
        end
        vim.keymap.set('n', lhs, rhs, { buffer = buf_id, desc = desc })
      end

      -- Set focused directory as current working directory
      local files_set_cwd = function()
        local path = (MiniFiles.get_fs_entry() or {}).path
        if path == nil then
          return vim.notify 'Cursor is not on valid entry'
        end
        vim.fn.chdir(vim.fs.dirname(path))
      end

      -- Yank in register full path of entry under cursor
      local yank_path = function()
        local path = (MiniFiles.get_fs_entry() or {}).path
        if path == nil then
          return vim.notify 'Cursor is not on valid entry'
        end
        vim.fn.setreg(vim.v.register, path)
      end
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesWindowOpen',
        callback = function(args)
          local win_id = args.data.win_id

          -- Customize window-local settings
          vim.wo[win_id].winblend = 25
          local config = vim.api.nvim_win_get_config(win_id)
          config.border, config.title_pos = 'double', 'right'
          vim.api.nvim_win_set_config(win_id, config)
        end,
      })

      -- Open path with system default handler (useful for non-text files)
      local ui_open = function()
        vim.ui.open(MiniFiles.get_fs_entry().path)
      end
      -- However, some parts (like window title and height) of window config are later
      -- updated internally. Use `MiniFilesWindowUpdate` event for them: >lua

      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesWindowUpdate',
        callback = function(args)
          local config = vim.api.nvim_win_get_config(args.data.win_id)

          -- Ensure fixed height
          config.height = 30

          -- Ensure no title padding
          local n = #config.title
          config.title[1][1] = config.title[1][1]:gsub('^ ', '')
          config.title[n][1] = config.title[n][1]:gsub(' $', '')

          vim.api.nvim_win_set_config(args.data.win_id, config)
        end,
      })
      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesBufferCreate',
        callback = function(args)
          local buf_id = args.data.buf_id

          vim.keymap.set('n', opts.mappings and opts.mappings.toggle_hidden or '.', toggle_dotfiles, { buffer = buf_id, desc = 'Toggle hidden files' })

          vim.keymap.set('n', 'gy', yank_path, { buffer = buf_id, desc = 'Yank path' })
          vim.keymap.set('n', 'gcd', files_set_cwd, { buffer = buf_id, desc = 'Set cwd' })
          vim.keymap.set('n', 'gX', ui_open, { buffer = buf_id, desc = 'OS open' })

          map_split(buf_id, opts.mappings and opts.mappings.go_in_horizontal or '<C-w>s', 'horizontal', false)
          map_split(buf_id, opts.mappings and opts.mappings.go_in_vertical or '<C-w>v', 'vertical', false)
          map_split(buf_id, opts.mappings and opts.mappings.go_in_horizontal_plus or '<C-w>S', 'horizontal', true)
          map_split(buf_id, opts.mappings and opts.mappings.go_in_vertical_plus or '<C-w>V', 'vertical', true)
        end,
      })

      vim.api.nvim_create_autocmd('User', {
        pattern = 'MiniFilesActionRename',
        callback = function(event)
          Snacks.rename.on_rename_file(event.data.from, event.data.to)
        end,
      })
    end,
    opts = function(_, opts)
      opts.windows = {

        -- Maximum number of windows to show side by side
        max_number = math.huge,
        -- Whether to show preview of file/directory under cursor
        preview = true,
        -- Width of focused window
        width_focus = 50,
        -- Width of non-focused window
        width_nofocus = 15,
        -- Width of preview window
        width_preview = 25,
      }
      opts.options = {
        permanent_delete = false,
        use_as_default_explorer = true,
      }
      opts.mappings = {
        close = 'q',
        go_in = 'l',
        go_in_plus = 'L',
        go_out = 'H',
        go_out_plus = '<Left>',
        mark_goto = 'mg',
        mark_set = 'mm',
        reset = '<BS>',
        reveal_cwd = '<C-d>',
        show_help = '?',
        synchronize = 's',
        trim_left = '<',
        trim_right = '>',
      }
    end,
  },
}
