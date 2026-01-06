---@return VimPackPlugin
vim.pack.add {
  _G.plug('Saghen/blink.cmp', {
    build_hook = {
      plugin = 'blink.cmp',
      build_cmd_type = 'shell',
      build_cmd = 'cargo build --release',
    },
  }),
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
  snippets = { preset = 'luasnip' },
  cmdline = {
    enabled = true,
    keymap = { preset = 'cmdline' },
    completion = {
      list = { selection = { preselect = false } },
      menu = {
        auto_show = function(ctx)
          return false
          -- return vim.fn.getcmdtype() == ':'
        end,
      },
      -- ghost_text = { enabled = true },
    },
  },
  sources = {
    -- Disable some sources in comments and strings.
    default = function()
      local sources = { 'lsp', 'snippets', 'buffer' }
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
    kind_icons = VimRc.icons.symbol_kinds,
  },
}
