vim.pack.add {
  { src = 'https://github.com/olimorris/codecompanion.nvim', version = 'main' },
  { src = 'https://github.com/lalitmee/codecompanion-spinners.nvim' },
  { src = 'https://github.com/ravitemer/codecompanion-history.nvim' },
}
-- CodeCompanion
require 'custom.ai'
local wkey_prefix = '<leader>a'
_G.keymaps_define({
  { mode = { 'n', 'v' }, lhs = wkey_prefix .. 'r', rhs = '<cmd>CodeCompanionChat RefreshCache<cr>', opts = { desc = 'CodeCompanion RefreshCache' } },
  { mode = { 'n', 'v' }, lhs = wkey_prefix .. 'a', rhs = '<cmd>CodeCompanionActions<cr>', opts = { desc = 'CodeCompanion Actions' } },
  { mode = { 'n', 'v' }, lhs = wkey_prefix .. 't', rhs = '<cmd>CodeCompanionChat Toggle<cr>', opts = { desc = 'CodeCompanionChat Toggle' } },
  { mode = { 'n', 'v' }, lhs = wkey_prefix .. 'i', rhs = '<cmd>CodeCompanionChat Add<cr>', opts = { desc = 'CodeCompanionChat Add' } },
  { mode = { 'n', 'v' }, lhs = wkey_prefix .. 'h', rhs = '<cmd>CodeCompanionHistory<cr>', opts = { desc = 'CodeCompanionHistory' } },
  { mode = { 'n', 'v' }, lhs = wkey_prefix .. 's', rhs = '<cmd>CodeCompanionSummaries<cr>', opts = { desc = 'Browse CodeCompanionSummaries' } },
}, { prefix = wkey_prefix, group = 'AI' })

local cc = augroup 'dotfiles.codecompanion'
_G.new_user_autocmd(function()
  vim.lsp.buf.format()
end, 'CodeCompanionInlineFinished', 'CodeCompanion Inline Format')

_G.new_user_autocmd(function(args)
  vim.treesitter.start(args.data.bufnr, 'markdown')
end, 'CodeCompanionChatCreated', 'CodeCompanion Chat Treesitter start')

local diff = require 'mini.diff'
diff.setup {
  -- Disabled by default
  source = diff.gen_source.none(),
}
