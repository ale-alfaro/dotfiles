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
KEYS.define({
  { mode = { 'n', 'v' }, lhs = wkey_prefix .. 'r', rhs = '<cmd>CodeCompanionChat RefreshCache<cr>', opts = { desc = 'CodeCompanion RefreshCache' } },
  { mode = { 'n', 'v' }, lhs = wkey_prefix .. 'a', rhs = '<cmd>CodeCompanionActions<cr>', opts = { desc = 'CodeCompanion Actions' } },
  { mode = { 'n', 'v' }, lhs = wkey_prefix .. 't', rhs = '<cmd>CodeCompanionChat Toggle<cr>', opts = { desc = 'CodeCompanionChat Toggle' } },
  { mode = { 'n', 'v' }, lhs = wkey_prefix .. 'i', rhs = '<cmd>CodeCompanionChat Add<cr>', opts = { desc = 'CodeCompanionChat Add' } },
  { mode = { 'n', 'v' }, lhs = wkey_prefix .. 'h', rhs = '<cmd>CodeCompanionHistory<cr>', opts = { desc = 'CodeCompanionHistory' } },
  { mode = { 'n', 'v' }, lhs = wkey_prefix .. 's', rhs = '<cmd>CodeCompanionSummaries<cr>', opts = { desc = 'Browse CodeCompanionSummaries' } },
}, { prefix = wkey_prefix, group = 'AI' })

_G.new_user_autocmd(function(args)
  vim.treesitter.start(args.data.bufnr, 'markdown')
end, 'CodeCompanionChatCreated', 'CodeCompanion Chat Treesitter start')
