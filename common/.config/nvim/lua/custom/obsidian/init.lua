local M = {}
---@class obsidian.ObsidianCli
---@field cmds table<string,boolean|string[]>
---@field args table<string,string[]>
---@field obsplit fun(args:string[])
---@field get_vaults fun():string[]
---@field check_obsidian_open fun():boolean
---@field handle_command fun(data:vim.api.keyset.create_user_command.command_args)

function M.obsfiles()
  require('fzf-lua').files {
    cwd = vim.fn.expand '$OBSIDIAN_HOME',
    cwd_only = true,
    file_icons = false,
    color_icons = false,
    fd_opts = '-e md -E templates -E _maintenance -E _categories -E attachments',
    ---@type fzf-lua.ActionSpec[]
    actions = {
      ['alt-a'] = function(selected, opts)
        for _, s in ipairs(selected) do
          VimRc.info('Sel: ' .. s)
        end
      end,
      ['alt-x'] = {
        fn = function(selected, opts)
          for _, s in ipairs(selected) do
            ObsidianCli.obsplit { 'delete', 'path=' .. s }
          end
        end,
        desc = 'Delete',
        header = 'rm',
        reload = true,
      },
      ['alt-m'] = {
        fn = function(selected, opts)
          for _, s in ipairs(selected) do
            vim.ui.input({ prompt = 'New path?' }, function(n)
              ObsidianCli.obsplit { 'move', 'path=' .. s, 'to=' .. n }
            end)
          end
        end,
        desc = 'Move',
        header = 'mv',
        reload = true,
      },
      ['alt-r'] = {
        fn = function(selected, opts)
          for _, s in ipairs(selected) do
            vim.ui.input({ prompt = 'Name?' }, function(n)
              -- obs('rename', { ['path'] = s, ['name'] = n })
              ObsidianCli.obsplit { 'rename', 'path=' .. s, 'path=' .. n }
            end)
          end
        end,
        desc = 'Rename',
        header = 'Rename',
        reload = true,
      },
    },
    prompt = 'Notes',
  }
end
function M.obsgrep()
  require('fzf-lua').live_grep {
    cwd = vim.fn.expand '$OBSIDIAN_HOME',
    cwd_only = true,
    rg_opts = '--glob *.md',
    prompt = 'Live Grep',
  }
end

M.setup = function()
  local search_keys = {
    { 'o', M.obsfiles, 'Search Obsidian Files' },
    { 'O', M.obsgrep, 'Grep Obsidian Files' },
  }
  for _, k in ipairs(search_keys) do
    vim.keymap.set('n', '<leader>s' .. k[1], k[2], { desc = k[3] })
  end
end

return M
