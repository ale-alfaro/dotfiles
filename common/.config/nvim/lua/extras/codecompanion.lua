vim.pack.add {
  { src = 'https://github.com/olimorris/codecompanion.nvim', version = vim.version.range '^18.0.0' },
  { src = 'https://github.com/lalitmee/codecompanion-spinners.nvim' },
  { src = 'https://github.com/ravitemer/codecompanion-history.nvim' },
}
-- CodeCompanion
--
local codecompanion = require 'codecompanion'
local config = require 'custom.ai'
codecompanion.setup(config)
local wkey_prefix = '<leader>a'
local keys = {
  { { 'n', 'v' }, wkey_prefix .. 'r', '<cmd>CodeCompanionChat RefreshCache<cr>', { desc = 'CodeCompanion RefreshCache' } },
  { { 'n', 'v' }, wkey_prefix .. 'a', '<cmd>CodeCompanionActions<cr>', { desc = 'CodeCompanion Actions' } },
  { { 'n', 'v' }, wkey_prefix .. 't', '<cmd>CodeCompanionChat Toggle<cr>', { desc = 'CodeCompanionChat Toggle' } },
  { { 'n', 'v' }, wkey_prefix .. 'i', '<cmd>CodeCompanionChat Add<cr>', { desc = 'CodeCompanionChat Add' } },
  { { 'n', 'v' }, wkey_prefix .. 'h', '<cmd>CodeCompanionHistory<cr>', { desc = 'CodeCompanionHistory' } },
  { { 'n', 'v' }, wkey_prefix .. 's', '<cmd>CodeCompanionSummaries<cr>', { desc = 'Browse CodeCompanionSummaries' } },
}
for _, k in ipairs(keys) do
  vim.keymap.set(unpack(k))
end
