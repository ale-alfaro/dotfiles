VimRc.now_if_args(function()
  vim.diagnostic.config {
    severity_sort = true,
    float = {
      border = 'rounded',
      source = 'if_many',
      underline = true,
    },
    virtual_text = {
      spacing = 2,
      source = 'if_many',
      prefix = 'o',
    },
    -- Disable signs in the gutter.
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = 'E',
        [vim.diagnostic.severity.WARN] = 'W',
        [vim.diagnostic.severity.INFO] = 'I',
        [vim.diagnostic.severity.HINT] = 'H',
      },
    },
  }
end)
VimRc.now_if_args(function()
  -- Customize post-processing of LSP responses for a better user experience.
  -- Don't show 'Text' suggestions (usually noisy) and show snippets last.
  local process_items_opts = { filtersort = 'fuzzy', kind_priority = { Text = -1, Snippet = 99 } }
  local process_items = function(items, base)
    return MiniCompletion.default_process_items(items, base, process_items_opts)
  end

  require('mini.completion').setup {
    delay = { completion = 300, info = 300, signature = 300 },
    lsp_completion = {
      auto_setup = false,
      -- Without this config autocompletion is set up through `:h 'completefunc'`.
      -- Although not needed, setting up through `:h 'omnifunc'` is cleaner
      -- (sets up only when needed) and makes it possible to use `<C-u>`.
      source_func = 'omnifunc',
      -- A function which takes LSP 'textDocument/completion' response items
      -- (each with `client_id` field for item's server) and word to complete.
      -- Output should be a table of the same nature as input. Common use case
      -- is custom filter/sort. Default: `default_process_items`
      process_items = process_items,

      -- A function which takes a snippet as string and inserts it at cursor.
      -- Default: `default_snippet_insert` which tries to use 'mini.snippets'
      -- and falls back to `vim.snippet.expand` (on Neovim>=0.10).
      snippet_insert = function(snippet)
        local insert = MiniSnippets.config.expand.insert or MiniSnippets.default_insert
        return insert { body = snippet }
      end,
    },

    -- Fallback action as function/string. Executed in Insert mode.
    -- To use built-in completion (`:h ins-completion`), set its mapping as
    -- string. Example: set '<C-x><C-l>' for 'whole lines' completion.
    -- fallback_action = '<C-x><C-l>',

    -- Module mappings. Use `''` (empty string) to disable one. Some of them
    -- might conflict with system mappings.
    mappings = {
      -- Force two-step/fallback completions
      force_twostep = '<A-Space>',
      force_fallback = '<A-CR>',

      -- Scroll info/signature window down/up. When overriding, check for
      -- conflicts with built-in keys for popup menu (like `<C-u>`/`<C-o>`
      -- for 'completefunc'/'omnifunc' source function; or `<C-n>`/`<C-p>`).
      scroll_down = '<C-f>',
      scroll_up = '<C-b>',
    },
  }

  --[[
  --
  --
  -- SNIPPETS
  --
  --]]
  --
  --
  --
  local snippets = require 'mini.snippets'
  local config_path = vim.fn.stdpath 'config'
  local common_sh_patterns = { 'sh/**/*.json', '**/sh.json', 'shell/**/*.json', '**/shell.json' }
  local lang_patterns = {
    -- Recognize special injected language of markdown tree-sitter parser
    markdown_inline = { 'markdown.json' },
    c = { 'cdoc/**/*.json', 'c/**/*.json', '**/cdoc.json', '**/c.json' },
    cpp = { 'cpp/**/*.json', '**/cpp.json', '**/cppdoc.json' },
    cmake = { 'cmake/**/*.json', '**/cmake.json' },
    python = { 'python/**/*.json', '**/python.json' },
    bash = vim.list_extend({ 'bash/**/*.json', '**/bash.json' }, common_sh_patterns),
    sh = common_sh_patterns,
    zsh = vim.list_extend({ 'zsh/**/*.json', '**/zsh.json' }, common_sh_patterns),
  }
  snippets.setup {
    snippets = {
      -- Always load 'snippets/global.json' from config directory
      snippets.gen_loader.from_file(config_path .. '/snippets/global.json'),
      -- Load from 'snippets/' directory of plugins, like 'friendly-snippets'
      snippets.gen_loader.from_lang { lang_patterns = lang_patterns },
    },
  }

  local map = require('mini.keymap').map_multistep
  --   -- Navigate 'mini.completion' menu with `<Tab>` /  `<S-Tab>`
  map('i', '<Tab>', { 'pmenu_next' })
  map('i', '<S-Tab>', { 'pmenu_prev' })
  map('i', '<CR>', { 'pmenu_accept' })
end)

-- Set up LSP servers.
VimRc.now_if_args(function()
  -- Code action setup
  local capabilities = MiniCompletion.get_lsp_capabilities { resolve_additional_text_edits = true }
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  vim.lsp.config('*', { capabilities = capabilities })
  require('vimrc_lsp').setup()
  require('custom.format').setup()
end)
