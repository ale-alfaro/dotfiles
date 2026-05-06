---@class obsidian.CLI
---@field cmds table<string,boolean|string[]>
---@field args table<string,string[]>
---@field obsplit fun(args:string[])
---@field get_vaults fun():string[]
---@field check_obsidian_open fun():boolean
---@field handle_command fun(data:vim.api.keyset.create_user_command.command_args)
local CLI = require 'custom.obsidian.cli'

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
            CLI.obsplit { 'delete', 'path=' .. s }
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
              CLI.obsplit { 'move', 'path=' .. s, 'to=' .. n }
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
              CLI.obsplit { 'rename', 'path=' .. s, 'path=' .. n }
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
  local orphans = obs 'orphans'
  local deadends = obs 'deadends'
  local unresolved = obs 'unresolved'
  require('fzf-lua').exec {
    prompt = 'Live Grep',
  }
end
local function obs_vault_usercmd()
  local obs_vault_cmd = function(name, cb)
    vim.api.nvim_create_user_command('Obs' .. name, function(ev)
      local name = (ev.fargs or {})[1]
      local vaults = CLI.get_vaults()

      local path = vaults[name]
      if not path then
        error('Vault not found in `obsidian vaults`: ' .. name, 2)
      end
      cb(path)
    end, { desc = 'Obsidian Vault' .. name, nargs = 1, complete = CLI.get_vaults })
  end
  -- obs_vault_cmd('Health', require('custom.obsidian.health').open)
  obs_vault_cmd('Files', obsfiles)
  obs_vault_cmd('Grep', obsgrep)
  -- obs_vault_cmd('Cleanup', obscleanup)
end

-- ---------------------------------------------------------------------------
-- Dispatch
-- ---------------------------------------------------------------------------

---Handle the :Obsidian user command.
---@param data vim.api.keyset.create_user_command.command_args
local function handle_command(data)
  local fargs = data.fargs
  if #fargs == 0 then
    CLI.obsplit {}
    --- check if vault commands already exist or not
    if not vim.api.nvim_get_commands({ builtin = false })['ObsFiles'] then
      VimRc.info 'Creating obsidian vault user commands'
      obs_vault_usercmd()
    end
    return
  end

  local cmd = fargs[1]
  if not CLI.cmds[cmd] then
    VimRc.err('Unknown command: ' .. cmd)
    return
  end
  local valid_args = CLI.args[cmd]
  local remaining_args = vim.list_slice(fargs, 2)
  for _, tok in ipairs(remaining_args) do
    tok = tok:match '%w+?='
    if not vim.list_contains(valid_args, tok) then
      VimRc.err('Invalid argument ' .. tok .. ' for cmd ' .. cmd)
      return
    end
  end

  CLI.obsplit(fargs)
end
-- ---------------------------------------------------------------------------
-- Setup
-- ---------------------------------------------------------------------------

return {
  setup = function()
    vim.api.nvim_create_user_command('Obsidian', function(data)
      handle_command(data)
    end, {
      nargs = '*',
    })
    if not CLI.check_obsidian_open() then
      VimRc.warn 'Obsidian UI must be open, run Obsidian command first to get the rest of the user commands '
      return
    end
    obs_vault_usercmd()
  end,
}
