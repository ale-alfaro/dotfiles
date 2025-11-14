vim.pack.add({ _G.plug('olimorris/codecompanion.nvim', { version = "17.30.0" }), _G.plug(
  'lalitmee/codecompanion-spinners.nvim'), _G.plug('ravitemer/codecompanion-history.nvim') })
-- CodeCompanion
require('custom.ai').setup {
  display = {
    action_palette = { provider = 'fzf_lua' },
    chat = {
      show_settings = false,
      show_header_separator = true,
      auto_scroll = true,
      show_token_count = true,
    },
  },
  extensions = {
    history = {
      enabled = true,
      opts = {
        keymap = 'gh',
        save_chat_keymap = 'sc',
        auto_save = true,
        expiration_days = 7,
        picker = 'fzf_lua',
      },
    },
    spinner = {
      enabled = true,
      opts = { style = 'native' },
    },
  },
  -- adapters = {
  --   acp = {
  --     gemini_cli = function()
  --       return require('codecompanion.adapters').extend('gemini_cli', {
  --         commands = {
  --           ['Gemini 2.5 Pro'] = { 'gemini', '--experimental-acp', '-m', 'gemini-2.5-pro' },
  --           ['default'] = { 'gemini', '--experimental-acp', '-m', 'gemini-2.5-flash' },
  --         },
  --         defaults = { auth_method = 'gemini-api-key', mcpServers = {}, timeout = 20000 },
  --         env = { GEMINI_API_KEY = vim.fn.expand '$GEMINI_API_KEY' },
  --       })
  --     end,
  --   },
  --   http = {
  --     qwen3 = function()
  --       return require("codecompanion.adapters").extend("ollama", {
  --         name = "qwen3-coder", -- Give this adapter a different name to differentiate it from the default ollama adapter
  --         opts = {
  --           vision = true,
  --           stream = true,
  --         },
  --         schema = {
  --           model = {
  --             default = "qwen3-coder:latest",
  --           },
  --           num_ctx = {
  --             default = 16384,
  --           },
  --           think = {
  --             default = false,
  --           },
  --           keep_alive = {
  --             default = "5m",
  --           },
  --         },
  --       })
  --     end,
  --   },
  -- },
}
local wkey_prefix = '<leader>a'
_G.keymaps_define({
  { mode = { 'n', 'v' }, lhs = wkey_prefix .. 'r', rhs = '<cmd>CodeCompanionChat RefreshCache<cr>', opts = { desc = 'CodeCompanion RefreshCache' } },
  { mode = { 'n', 'v' }, lhs = wkey_prefix .. 'a', rhs = '<cmd>CodeCompanionActions<cr>',           opts = { desc = 'CodeCompanion Actions' } },
  { mode = { 'n', 'v' }, lhs = wkey_prefix .. 't', rhs = '<cmd>CodeCompanionChat Toggle<cr>',       opts = { desc = 'CodeCompanionChat Toggle' } },
  { mode = { 'n', 'v' }, lhs = wkey_prefix .. 'i', rhs = '<cmd>CodeCompanionChat Add<cr>',          opts = { desc = 'CodeCompanionChat Add' } },
  { mode = { 'n', 'v' }, lhs = wkey_prefix .. 'h', rhs = '<cmd>CodeCompanionHistory<cr>',           opts = { desc = 'CodeCompanionHistory' } },
  { mode = { 'n', 'v' }, lhs = wkey_prefix .. 's', rhs = '<cmd>CodeCompanionSummaries<cr>',         opts = { desc = 'Browse CodeCompanionSummaries' } },
}, { prefix = wkey_prefix, group = 'AI' })

local cc = augroup 'dotfiles.codecompanion'
_G.new_user_autocmd(function()
  vim.lsp.buf.format()
end, 'CodeCompanionInlineFinished', { desc = "CodeCompanion Inline Format" })

_G.new_user_autocmd(function(args)
  vim.treesitter.start(args.data.bufnr, 'markdown')
end, 'CodeCompanionChatCreated', { desc = "CodeCompanion Chat Treesitter start" })

local diff = require("mini.diff")
diff.setup({
  -- Disabled by default
  source = diff.gen_source.none(),
})
