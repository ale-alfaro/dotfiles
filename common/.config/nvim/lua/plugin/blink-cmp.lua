require('blink.cmp').setup {
  keymap = {
    ['<CR>'] = { 'accept', 'fallback' },
    ['<C-\\>'] = { 'hide', 'fallback' },
    ['<C-n>'] = { 'select_next', 'show' },
    ['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
    ['<C-p>'] = { 'select_prev' },
    ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
    ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
  },
  completion = {
    list = {
      -- Insert items while navigating the completion list.
      selection = { preselect = false, auto_insert = true },
      max_items = 10,
    },
    documentation = { auto_show = true },
    menu = { scrollbar = false },
  },
  signature = { enabled = true },
  snippets = { preset = 'luasnip' },
  -- Disable command line completion:
  cmdline = {
    enabled = true,
    keymap = { preset = 'cmdline' },
    completion = {
      list = { selection = { preselect = false } },
      menu = {
        auto_show = function(ctx)
          return vim.fn.getcmdtype() == ':'
        end,
      },
      ghost_text = { enabled = true },
    },
  },
  sources = {
    -- Disable some sources in comments and strings.
    default = function()
      local sources = { "lsp", "buffer", "path", "snippets" }
      return sources
    end,
    per_filetype = {
      codecompanion = { 'codecompanion' },
    },
  },
  appearance = {
    kind_icons = VimRc.icons.symbol_kinds,
  },
}
