-- with lazy.nvim
return {
  'LintaoAmons/bookmarks.nvim',
  -- pin the plugin at specific version for stability
  -- backup your bookmark sqlite db when there are breaking changes (major version change)
  tag = '3.2.0',
  dependencies = {
    { 'kkharji/sqlite.lua' },
    { 'nvim-telescope/telescope.nvim' }, -- currently has only telescopes supported, but PRs for other pickers are welcome
    { 'stevearc/dressing.nvim' }, -- optional: better UI
    { 'GeorgesAlkhouri/nvim-aider' }, -- optional: for Aider integration
  },
  config = function()
    local opts = {

      treeview = {
        keymaps = {

          ['<CR>'] = {
            action = 'toggle',
            desc = 'Toggle list expansion or go to bookmark location',
          },
          -- ["o"] = {
          --   action = "goto",
          --   desc = "Go to bookmark location in previous window"
          -- },
          ['<C-o>'] = {
            action = function(node, info)
              if info.type == 'bookmark' then
              end
            end,
            desc = 'Open the current node with system default software',
          },
        },
      },
    } -- check the "./lua/bookmarks/default-config.lua" file for all the options
    require('bookmarks').setup(opts) -- you must call setup to init sqlite db

    local Service = require 'bookmarks.domain.service'
    -- local Node = require("bookmarks.domain.node")
    -- local Location = require("bookmarks.domain.location")
    local Sign = require 'bookmarks.sign'
    local Tree = require 'bookmarks.tree'

    -- Toggle boomark
    ---@param input string
    local function toggle_mark(input)
      Service.toggle_mark(input)
      Sign.safe_refresh_signs()
      pcall(Tree.refresh)
    end

    vim.api.nvim_create_user_command('BookmarksQuickMark', toggle_mark, {
      desc = 'Toggle bookmark for the current line into active BookmarkList (no name).',
    })
    -- Automatically switching Active Bookmark List based on repo
    --   local find_or_create_project_bookmark_group = function() local project_root = require('project_nvim.project').get_project_root()
    --     if not project_root then
    --       return
    --     end
    --
    --     local project_name = string.gsub(project_root, '^' .. os.getenv 'HOME' .. '/', '')
    --     local Repo = require 'bookmarks.domain.repo'
    --     local bookmark_list = nil
    --
    --     for _, bl in ipairs(Repo.find_lists()) do
    --       if bl.name == project_name then
    --         bookmark_list = bl
    --         break
    --       end
    --     end
    --
    --     if not bookmark_list then
    --       bookmark_list = Service.create_list(project_name)
    --     end
    --     Service.set_active_list(bookmark_list.id)
    --     require('bookmarks.sign').safe_refresh_signs()
    --   end
    --   vim.api.nvim_create_autocmd({ 'VimEnter', 'BufEnter' }, {
    --     group = vim.api.nvim_create_augroup('BookmarksGroup', {}),
    --     pattern = { '*' },
    --     callback = find_or_create_project_bookmark_group,
    --   })
  end,

  keys = {
    {
      'mm',
      '<cmd>BookmarksMark<cr>',
      desc = 'Mark current line into active BookmarkList.',
    },
    { 'mq', '<cmd>BookmarksQuickMark<cr>', desc = 'Mark current line into active BookmarkList (no name).' },
    {
      'mo',
      '<cmd>BookmarksGoto<cr>',
      desc = 'Go to bookmark at current active BookmarkList',
    },
    {
      '<leader>bc',
      '<cmd>BookmarksCommands<cr>',
      mode = { 'n', 'v' },
      desc = 'Open bookmark commands view.',
    },
    {
      '<leader>bt',
      '<cmd>BookmarksTree<cr>',
      mode = { 'n', 'v' },
      desc = 'Open bookmark tree view.',
    },
    {
      '<leader>bg',
      '<cmd>BookmarksGrep<cr>',
      mode = { 'n', 'v' },
      desc = 'Grep for bookmarks',
    },
  },
}

-- run :BookmarksInfo to see the running status of the plugin
