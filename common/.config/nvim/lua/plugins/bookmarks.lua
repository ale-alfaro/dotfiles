return {
  'LintaoAmons/bookmarks.nvim',
  dependencies = {
    { 'kkharji/sqlite.lua' },
    { 'nvim-telescope/telescope.nvim' },
    { 'stevearc/dressing.nvim' },
    { 'GeorgesAlkhouri/nvim-aider' },
  },
  config = function()
    local opts = {
      save_file = vim.fn.stdpath('data') .. '/bookmarks.db',
      keywords = {
        ['@t'] = '󰃅', -- mark annotation startswith @t ,signs this icon as `Todo`
        ['@w'] = '', -- mark annotation startswith @w ,signs this icon as `Warn`
        ['@f'] = '픽', -- mark annotation startswith @f ,signs this icon as `Fix`
        ['@n'] = '󰎞', -- mark annotation startswith @n ,signs this icon as `Note`
      },
      treeview = {
        keymaps = {
          ['<CR>'] = {
            action = 'toggle',
            desc = 'Toggle list expansion or go to bookmark location',
          },
          ['d'] = {
            action = 'cut',
            desc = 'Cut node',
          },
          ['D'] = {
            action = 'delete',
            desc = 'Delete current node',
          },
          ['y'] = {
            action = 'copy',
            desc = 'Copy node',
          },
          ['p'] = {
            action = 'preview',
            desc = 'Preview bookmark content',
          },
          ['<C-o>'] = {
            action = function(node, info)
              if info.type == 'bookmark' then
                vim.ui.open(node.path)
              end
            end,
            desc = 'Open the current node with system default software',
          },
        },
      },
    }
    require('bookmarks').setup(opts)

    local Service = require 'bookmarks.domain.service'
    local Sign = require 'bookmarks.sign'
    local Tree = require 'bookmarks.tree'

    local function toggle_mark(input)
      Service.toggle_mark(input)
      Sign.safe_refresh_signs()
      pcall(Tree.refresh)
    end

    vim.api.nvim_create_user_command('BookmarksQuickMark', toggle_mark, {
      desc = 'Toggle bookmark for the current line into active BookmarkList (no name).',
    })
  end,
  keys = {
    { 'mm', '<cmd>BookmarksMark<cr>', desc = 'Mark current line into active BookmarkList.' },
    { 'mq', '<cmd>BookmarksQuickMark<cr>', desc = 'Mark current line into active BookmarkList (no name).' },
    { 'mo', '<cmd>BookmarksGoto<cr>', desc = 'Go to bookmark at current active BookmarkList' },
    { '<leader>bc', '<cmd>BookmarksCommands<cr>', mode = { 'n', 'v' }, desc = 'Open bookmark commands view.' },
    { '<leader>bt', '<cmd>BookmarksTree<cr>', mode = { 'n', 'v' }, desc = 'Open bookmark tree view.' },
    { '<leader>bg', '<cmd>BookmarksGrep<cr>', mode = { 'n', 'v' }, desc = 'Grep for bookmarks' },
  },
}