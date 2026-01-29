---@return VimPackPlugin

require('blink.cmp').setup {
  keymap = {

    -- show with a list of providers
    ['<C-space>'] = {
      function(cmp)
        cmp.show { providers = { 'snippets' } }
      end,
    },
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
    menu = {
      scrollbar = false,
      draw = {
        gap = 2,
        columns = {
          { 'kind_icon', 'kind', gap = 1 },
          { 'label', 'label_description', gap = 1 },
        },
      },
    },
  },
  signature = { enabled = true },

  snippets = { preset = 'mini_snippets' },
  sources = {
    -- Disable some sources in comments and strings.
    default = { 'lsp', 'path', 'snippets', 'buffer' },
  },
  appearance = {
    kind_icons = VimRc.icons.symbol_kinds,
  },
}
