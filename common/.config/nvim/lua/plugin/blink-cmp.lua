local blink_opts = {
  keymap = { preset = 'default' },
  appearance = { nerd_font_variant = 'mono' },
  completion = { documentation = { auto_show = false } },
  signature = { enabled = true },
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
    providers = {
      lsp = { async = true, score_offset = 70 },
      snippets = { score_offset = 1, max_items = 3 },
    },
  },
  fuzzy = { implementation = 'prefer_rust_with_warning' },
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
}
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
      local sources = { 'lsp', 'buffer' }
      local ok, node = pcall(vim.treesitter.get_node)

      if ok and node then
        if not vim.tbl_contains({ 'comment', 'line_comment', 'block_comment' }, node:type()) then
          table.insert(sources, 'path')
        end
        if node:type() ~= 'string' then
          table.insert(sources, 'snippets')
        end
      end

      return sources
    end,
    per_filetype = {
      codecompanion = { 'codecompanion', 'buffer' },
    },
  },
  appearance = {
    kind_icons = require('icons').symbol_kinds,
  },
}

vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities(nil, true) })
-- Show all diagnostics as underline (for their messages type `<Leader>ld`)
-- ok, blink = pcall(require, 'blink.cmp')
-- if ok then
--   blink.setup(blink_opts)
--   vim.lsp.config('*', { capabilities = blink.get_lsp_capabilities() })
-- end
