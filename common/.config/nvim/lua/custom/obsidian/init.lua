---@class obsidian.ObsidianCli
---@field cmds table<string,boolean|string[]>
---@field args table<string,string[]>
---@field obsplit fun(args:string[])
---@field get_vaults fun():string[]
---@field check_obsidian_open fun():boolean
---@field handle_command fun(data:vim.api.keyset.create_user_command.command_args)

---@param path string
local function obsfiles(path)
  require('fzf-lua').files {
    cwd = path,
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
      ['ctrl-x'] = {
        fn = function(selected, opts)
          for _, s in ipairs(selected) do
            ObsidianCli.obsplit { 'delete', 'path=' .. s }
          end
        end,
        desc = 'Delete',
        header = 'rm',
        reload = true,
      },
      ['ctrl-m'] = {
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
      ['ctrl-r'] = {
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
---@param path string
local function obsgrep(path)
  require('fzf-lua').live_grep {
    cwd = path,
    cwd_only = true,
    rg_opts = '--glob *.md',
    prompt = 'Live Grep',
  }
end

---@param path string
local function obscleanup(path)
  local orphans = ObsidianCli.exec 'orphans'
  local deadends = ObsidianCli.exec 'deadends'
  local unresolved = ObsidianCli.exec 'unresolved'
  require('fzf-lua').exec {
    prompt = 'Live Grep',
  }
end
local function obs_vault_usercmd()
  local obs_vault_cmd = function(name, cb)
    vim.api.nvim_create_user_command('Obs' .. name, function(ev)
      local name = (ev.fargs or {})[1]
      local vaults = ObsidianCli.get_vaults()

      local path = vaults[name]
      if not path then
        error('Vault not found in `obsidian vaults`: ' .. name, 2)
      end
      cb(path)
    end, { desc = 'Obsidian Vault' .. name, nargs = 1, complete = ObsidianCli.get_vaults })
  end
  -- obs_vault_cmd('Health', require('custom.obsidian.health').open)
  obs_vault_cmd('Files', obsfiles)
  obs_vault_cmd('Grep', obsgrep)
  obs_vault_cmd('Cleanup', obscleanup)
end

-- ---------------------------------------------------------------------------
-- Dispatch
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Setup
-- ---------------------------------------------------------------------------

return {
  setup = function()
    ObsidianCli = ObsidianCli or require 'custom.obsidian.cli'
    ObsidianCli.setup()
    vim.api.nvim_create_autocmd('BufRead', {
      pattern = '	BufRead $OBSIDIAN_HOME/**/*.md',
      callback = function(ev)
        local obsidian_vault_root = vim.fs.root(ev.buf, { '.obsidian' })
        local obsidian_conf = vim.fs.joinpath(obsidian_vault_root, '.obsidian', 'app.json')
        if obsidian_vault_root and vim.uv.fs_stat(obsidian_conf) then
          obs_vault_usercmd()
        end
      end,
    })
  end,
}
