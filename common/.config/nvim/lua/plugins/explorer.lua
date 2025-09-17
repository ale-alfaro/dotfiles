return {
  {
    'echasnovski/mini.files',
    keys = {
      {
        '\\',
        function()
          require('mini.files').open(vim.api.nvim_buf_get_name(0), true)
        end,
        desc = 'Open mini.files (Directory of Current File)',
      },
      {
        '<leader>\\',
        function()
          require('mini.files').open(vim.uv.cwd(), true)
        end,
        desc = 'Open mini.files (cwd)',
      },
    },
    opts = function(_, opts)
      opts.options = {
        permanent_delete = false,
        use_as_default_explorer = false,
      }
      opts.mappings = {
        close = 'q',
        go_in = 'l',
        go_in_plus = 'L',
        go_out = 'H',
        go_out_plus = '<Left>',
        mark_goto = 'g',
        mark_set = 'm',
        reset = '<BS>',
        reveal_cwd = '.',
        show_help = '?',
        synchronize = 's',
        trim_left = '<',
        trim_right = '>',
      }
    end,
  },
  {
    'folke/snacks.nvim',
    opts = {
      picker = {
        sources = {
          explorer = {
            win = {
              list = {
                keys = {
                  ['<C-c>'] = {
                    'toggle_cwd',
                    mode = { 'n', 'i' },
                  },
                },
                ['<ESC>'] = '',
                ['H'] = 'explorer_up',
                ['<cr>'] = 'toggle_node',
                ['<BS>'] = '',
                ['C'] = 'explorer_close_all',
                ['s'] = 'explorer_update',
                ['q'] = 'cancel',
                ['.'] = 'toggle_hidden',
              },
            },

            -- ignored = true,
            hidden = true,
            actions = {
              explorer_paste = function(picker, item) --[[Override]]
                local Tree = require 'snacks.explorer.tree'
                local files = vim.split(vim.fn.getreg(vim.v.register or '+') or '', '\n', { plain = true })
                files = vim.tbl_filter(function(file)
                  -- NOTE: Use `vim.uv.fs_stat` instead of `vim.fn.filereadable`
                  return file ~= '' and vim.uv.fs_stat(file) ~= nil
                end, files)
                if #files == 0 then
                  return Snacks.notify.warn(('The `%s` register does not contain any files'):format(vim.v.register or '+'))
                end
                local dir = picker:dir()
                -- NOTE: Prefer parent when directory is closed
                if item.dir and not item.open then
                  dir = vim.fs.dirname(dir)
                end
                -- NOTE: Replace `Snacks.picker.util.copy`
                for _, file in ipairs(files) do
                  -- BUG: Prevent pasting inside itself
                  if file == dir then
                    Snacks.notify.warn(string.format('Skip recursive copy: %s', file))
                  else
                    local dst = vim.fs.joinpath(dir, vim.fn.fnamemodify(file, ':t'))
                    local dst_unique = dst
                    local count = 0
                    while vim.uv.fs_stat(dst_unique) do
                      count = count + 1
                      dst_unique = string.format('%s (copy %d)', dst, count)
                    end
                    Snacks.picker.util.copy_path(file, dst_unique)
                  end
                end
                Tree:refresh(dir)
                Tree:open(dir)
                picker:update { target = dir }
              end,
            }, -- actions

            icons = {
              git = {
                staged = '●',
                added = 'A',
                deleted = 'D',
                ignored = '',
                modified = 'M',
                renamed = 'R',
                untracked = 'U',
              },
            },
          }, -- explorer
        },
      },
    },
  },
}
