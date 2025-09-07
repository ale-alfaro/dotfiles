function _G.get_oil_winbar()
  local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
  local dir = require('oil').get_current_dir(bufnr)
  if dir then
    return vim.fn.fnamemodify(dir, ':~')
  else
    -- If there is no current directory (e.g. over ssh), just show the buffer name
    return vim.api.nvim_buf_get_name(0)
  end
end

return {

  'stevearc/oil.nvim',

  config = function()
    local oil = require 'oil'

    local function parse_output(proc)
      local result = proc:wait()
      local ret = {}
      if result.code == 0 then
        for line in vim.gsplit(result.stdout, '\n', { plain = true, trimempty = true }) do
          -- Remove trailing slash
          line = line:gsub('/$', '')
          ret[line] = true
        end
      end
      return ret
    end

    -- build git status cache
    local function new_git_status()
      return setmetatable({}, {
        __index = function(self, key)
          local ignore_proc = vim.system({ 'git', 'ls-files', '--ignored', '--exclude-standard', '--others', '--directory' }, {
            cwd = key,
            text = true,
          })
          local tracked_proc = vim.system({ 'git', 'ls-tree', 'HEAD', '--name-only' }, {
            cwd = key,
            text = true,
          })
          local ret = {
            ignored = parse_output(ignore_proc),
            tracked = parse_output(tracked_proc),
          }

          rawset(self, key, ret)
          return ret
        end,
      })
    end
    local git_status = new_git_status()

    -- Clear git status cache on refresh
    local refresh = require('oil.actions').refresh
    local orig_refresh = refresh.callback
    refresh.callback = function(...)
      git_status = new_git_status()
      orig_refresh(...)
    end
    --[[
    -- Opens current directory of oil in a new zellij pane
    --]]
    local open_in_zellij_pane = function(direction)
      local bufnr = vim.api.nvim_get_current_buf()
      local entry = require('oil').get_cursor_entry()
      if not entry then
        vim.notify('Could not retrieve the file under cursor from oil.nvim', vim.log.levels.ERROR)
        return
      end
      vim.print('Entry:', vim.inspect(entry))

      if entry.type == 'file' then
        local cwd = oil.get_current_dir(bufnr)
        vim.fn.jobstart { 'zellij', 'action', 'new-pane', '--direction', direction, '--cwd', cwd, '--', 'nvim', entry.name }
      else
        local cwd = oil.get_current_dir(bufnr) .. entry.name
        vim.fn.jobstart { 'zellij', 'action', 'new-pane', '--direction', direction, '--cwd', cwd, '--', 'nvim', '.' }
      end
    end

    local open_left = function()
      open_in_zellij_pane 'left'
    end

    local open_down = function()
      open_in_zellij_pane 'down'
    end
    oil.setup {
      columns = { 'icon' },
      default_file_explorer = true,
      view_options = {
        show_hidden = true,
        -- Hide gitignoere files
        is_hidden_file = function(name, bufnr)
          local dir = require('oil').get_current_dir(bufnr)
          local is_dotfile = vim.startswith(name, '.') and name ~= '..'
          -- if no local directory (e.g. for ssh connections), just hide dotfiles
          if not dir then
            return is_dotfile
          end
          -- dotfiles are considered hidden unless tracked
          if is_dotfile then
            return not git_status[dir].tracked[name]
          else
            -- Check if file is gitignored
            return git_status[dir].ignored[name]
          end
        end,
      },
      win_options = {
        winbar = '%!v:lua.get_oil_winbar()',
      },
      delete_to_trash = true, -- Deletes to trash
      skip_confirm_for_simple_edits = true,
      use_default_keymaps = false,
      keymaps = {
        ['?'] = { 'actions.show_help', mode = 'n' },
        ['<CR>'] = 'actions.select',
        ['L'] = { 'actions.select', mode = 'n' },
        ['<C-p>'] = 'actions.preview',
        ['q'] = { 'actions.close', mode = 'n' },
        ['s'] = { oil.save, mode = 'n' },
        ['H'] = { 'actions.parent', mode = 'n' },
        ['<leader>:'] = {
          'actions.open_terminal',
          desc = 'Open the terminal with the current directory as an argument',
        },
        ['<leader>e'] = {
          'actions.open_external',
          desc = 'Open the current directory with external program',
        },
        -- ['_'] = { 'actions.open_cwd', mode = 'n' },
        -- ['<leader>d'] = { 'actions.cd', mode = 'n' },
        -- ['<leader>D'] = { 'actions.cd', opts = { scope = 'tab' }, mode = 'n' },
        ['.'] = { 'actions.toggle_hidden', mode = 'n' },
        ['<C-n>'] = open_left,
        ['<C-l>'] = open_left,
        ['<C-d>'] = open_down,
        ['<C-j>'] = open_down,

        ['<leader>ff'] = {
          function()
            require('telescope.builtin').find_files {
              cwd = require('oil').get_current_dir(),
            }
          end,
          mode = 'n',
          nowait = true,
          desc = 'Find files in the current directory',
        },
      },
    }
    -- vim.keymap.set('n', '\\', oil.open)
    -- vim.keymap.set(
    --   'n',
    --   '<C-\\>',
    --   oil.open {
    --     -- dir = vim.fn.expand '%:p:h',
    --     opts = { vertical = true, split = 'aboveleft' },
    --   }
    -- )
    -- vim.keymap.set('n', '<leader>ft', oil.toggle_float)
  end,
  keys = {
    {
      '\\',
      '<CMD>Oil<CR>',
      desc = 'Open oil file navigator',
      silent = true,
    },

    {
      '|',
      function()
        require('oil').open {
          -- dir = vim.fn.expand '%:p:h',
          opts = { vertical = true, split = 'aboveleft' },
        }
      end,
      desc = 'Open oil file  navigator on the sidebar',
      silent = true,
    },
  },
  -- You can pass additional opts to vim.keymap.set by using
  -- a table with the mapping as the first element.
} -- end of return
