---@module "neoconf"
local M = {}

local __filepath__ = debug.getinfo(1).source:sub(2)
local __project_root__ = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(__filepath__)))

-- function M.reload_neoconf_settings()
--   local neoconf = require 'neoconf'
--   local settings = neoconf.get('neopyter', {})
--   local neopyter = require 'neopyter'
--   neopyter.config = vim.tbl_deep_extend('force', neopyter.config, settings)
-- end
--
-- function M.setup()
--   local neoconf = require 'neoconf'
--   neoconf.register {
--     name = 'neopyter',
--     on_schema = function(schema)
--       local schema_path = vim.fs.joinpath(__project_root__, 'schema', 'neoconf.json')
--       schema:set('neopyter', {
--         ['$ref'] = vim.uri_from_fname(schema_path),
--       })
--     end,
--     on_update = function()
--       M.reload_neoconf_settings()
--     end,
--   }
--   M.reload_neoconf_settings()
-- end

local neconf_config = {
  'folke/neoconf.nvim',

  ---@class Config
  opts = {
    -- name of the local settings files
    local_settings = '.neoconf.json',
    -- name of the global settings file in your Neovim config directory
    global_settings = 'neoconf.json',
    -- import existing settinsg from other plugins
    import = {
      vscode = true, -- local .vscode/settings.json
      coc = true, -- global/local coc-settings.json
      nlsp = true, -- global/local nlsp-settings.nvim json settings
    },
    -- send new configuration to lsp clients when changing json settings
    live_reload = true,
    -- set the filetype to jsonc for settings files, so you can use comments
    -- make sure you have the jsonc treesitter parser installed!
    filetype_jsonc = true,
    plugins = {
      -- configures lsp clients with settings in the following order:
      -- - lua settings passed in lspconfig setup
      -- - global json settings
      -- - local json settings
      lspconfig = {
        enabled = true,
      },
      -- configures jsonls to get completion in .neoconf.json files
      jsonls = {
        enabled = true,
        -- only show completion in json settings for configured lsp servers
        configured_servers_only = true,
      },
      -- configures lua_ls to get completion of lspconfig server settings
      lua_ls = {
        -- by default, lua_ls annotations are only enabled in your neovim config directory
        enabled_for_neovim_config = true,
        -- explicitly enable adding annotations. Mostly relevant to put in your local .neoconf.json file
        enabled = true,
      },
    },
  },
}
return {}
