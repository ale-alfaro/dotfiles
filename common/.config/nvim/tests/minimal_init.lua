-- Minimal init for running tests via mini.test
-- Usage: nvim --headless --noplugin -u tests/minimal_init.lua -c "lua MiniTest.run()" -c "qa!"

-- Add project root to rtp so require('custom.*') works
vim.cmd([[let &rtp.=','.getcwd()]])

-- Load mini.nvim (packpath already includes it via site)
vim.cmd('packadd mini.nvim')

-- Setup mini.test
require('mini.test').setup()

-- Provide FeatureFlags stub so format.lua can call setup()
---@class FeatureFlag
---@field name string
---@field enabled boolean
_G.FeatureFlags = {
  entries = {},
}
FeatureFlags.__index = FeatureFlags

function FeatureFlags:add(feature)
  if type(feature) == 'string' then
    feature = { name = feature, enabled = false }
  end
  self.entries[feature.name] = feature
  return feature
end

function FeatureFlags:get(name)
  return self.entries[name] or self:add { name = name, enabled = false }
end

function FeatureFlags:set(name, enable)
  local f = self:get(name)
  f.enabled = enable or false
end
