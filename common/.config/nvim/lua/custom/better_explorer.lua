---@module "lazyvim"
---
return {
  {
    'folke/snacks.nvim',
    keys = {
      { '<leader>e',  false }, --desc = "Explorer Snacks (root dir)", remap = true },
      { '<leader>E',  false }, --desc = "Explorer Snacks (cwd)", remap = true },
      { '<leader>fe', false },
      { '<leader>fE', false },
    },
    opts = {
      explorer = {
        enabled = false,
      },
    },
  },
  {
    'folke/snacks.nvim',

    keys = {
      {
        '<leader>fe',
        function()
          Snacks.explorer { cwd = LazyVim.root() }
        end,
        desc = 'Explorer Snacks (root dir)',
      },
      {
        '<leader>fE',
        function()
          Snacks.explorer()
        end,
        desc = 'Explorer Snacks (cwd)',
      },
      { '<leader>e', '<leader>fe', desc = 'Explorer Snacks (root dir)', remap = true },
      { '<leader>E', '<leader>fE', desc = 'Explorer Snacks (cwd)',      remap = true },
    },
    opts = {
      picker = {
        sources = {
          explorer = {
            win = {
              list = {
                keys = {

                  ['<C-d>'] = 'tcd',
                  ['<ESC>'] = '',
                  ['H'] = 'explorer_up',
                  ['<cr>'] = 'toggle_recursive',
                  ['<BS>'] = '',
                  ['C'] = 'explorer_close_all',
                  ['s'] = 'explorer_update',
                  ['q'] = 'cancel',
                  ['.'] = 'toggle_hidden',
                  ['w'] = 'wezterm_split',
                }, --keys
              },   -- list
            },     -- win

            -- ignored = true,
            hidden = true,
            actions = {
              ---@param item snacks.picker.Item
              wezterm_split = function(p, item)
                if not item then
                  return
                end

                local wezterm = require 'custom.wezterm.wezterm_terminal'
                local Direction = require('smart-splits.types').Direction

                if item.dir then
                  wezterm.split_pane(Direction.down, item.file, 30)
                else
                  wezterm.spawn_nvim_inst(Direction.down, item.file)
                end
              end,
              toggle_cwd = function(p)
                local root = LazyVim.root { buf = p.input.filter.current_buf, normalize = true }
                local cwd = vim.fs.normalize((vim.uv or vim.loop).cwd() or '.')
                local current = p:cwd()
                p:set_cwd(current == root and cwd or root)
                p:find()
              end,
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
              toggle_recursive = function(picker, item)
                local Actions = require 'snacks.explorer.actions'
                local Tree = require 'snacks.explorer.tree'

                local get_children = function(node)
                  local children = {}
                  for _, child in pairs(node.children) do
                    table.insert(children, child)
                  end
                  return children
                end

                local refresh = function()
                  Actions.update(picker, { refresh = true })
                end

                ---@param node snacks.picker.explorer.Node
                local function toggle_recursive(node)
                  Tree:toggle(node.path)
                  refresh()
                  vim.schedule(function()
                    local children = get_children(node)
                    if #children ~= 1 then
                      return
                    end
                    local child = children[1]
                    if not child.dir then
                      return
                    end
                    toggle_recursive(child)
                  end)
                end

                --

                local node = Tree:node(item.file)
                if not node then
                  return
                end

                if node.dir then
                  toggle_recursive(node)
                else
                  picker:action 'confirm'
                end
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
