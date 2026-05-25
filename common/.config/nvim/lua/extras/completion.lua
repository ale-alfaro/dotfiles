return {
  setup_blink = function()
    local blink_build = function(plugin, path)
      -- vim.system({ 'cargo', 'build', '--release' }, { cwd = path })
      require('blink.cmp').build():wait(60000)
    end
    VimRc.on_packchanged('blink.cmp', { 'update', 'install' }, blink_build, 'Build  Blink')
    local cmp = require 'blink.cmp'
    cmp.setup {
      -- Enables keymaps, completions and signature help when true (doesn't apply to cmdline or term)
      --
      -- If the function returns 'force', the default conditions for disabling the plugin will be ignored
      -- Default conditions: (vim.bo.buftype ~= 'prompt' and vim.b.completion ~= false)
      -- Note that the default conditions are ignored when `vim.b.completion` is explicitly set to `true`
      --
      -- Exceptions: vim.bo.filetype == 'dap-repl'
      enabled = function()
        return true
      end,

      -- Disable cmdline
      cmdline = { enabled = true, keymap = { preset = 'cmdline' } },
      fuzzy = {
        implementation = 'prefer_rust_with_warning',
      },
      keymap = {
        preset = 'default',
      },

      -- Use a preset for snippets, check the snippets documentation for more information
      snippets = { preset = 'mini_snippets' },

      -- Experimental signature help support
      signature = { enabled = true },
    }

    local capabilities = vim.tbl_deep_extend('force', vim.lsp.protocol.make_client_capabilities(), cmp.get_lsp_capabilities({}, false))
    vim.lsp.config('*', { capabilities = capabilities })
  end,
  setup_mini_cmdline = function()
    ---@class CmdLineState
    ---@field line string vim.fn.getcmdline
    ---@field pos string vim.fn.getcmdpos
    ---@field prev_line string vim.fn.getcmdline
    ---@field prev_pos string vim.fn.getcmdpos
    ---
    ---@class CmdLineInfo
    ---@field complpat string  vim.fn.getcmdcomplpat completion pattern
    ---@field compltype string vim.fn.getcmdcompltype completion type

    local block_compltype = { 'shellcmd' }
    -- Command line tweaks. Improves command line editing with:
    -- - Autocompletion. Basically an automated `:h cmdline-completion`.
    -- - Autocorrection of words as-you-type. Like `:W`->`:w`, `:lau`->`:lua`, etc.
    -- - Autopeek command range (like line number at the start) as-you-type.
    VimRc.later(function()
      require('mini.cmdline').setup {
        autocomplete = {
          delay = 1000,
          ---@param state CmdLineState
          predicate = function(state, _opts)
            return (state.line:find '%a' ~= nil) and not block_compltype[vim.fn.getcmdcompltype()]
          end,
        },
        autocorrect = {},
      }
    end)
  end,
  -- Customize post-processing of LSP responses for a better user experience.
  -- Don't show 'Text' suggestions (usually noisy) and show snippets last.
  setup_mini_comp = function()
    local process_items_opts = { filtersort = 'fuzzy', kind_priority = { Text = -1, Snippet = 99 } }
    local process_items = function(items, base)
      return MiniCompletion.default_process_items(items, base, process_items_opts)
    end
    --
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
    local capabilities = MiniCompletion.get_lsp_capabilities { resolve_additional_text_edits = true }
    vim.lsp.config('*', { capabilities = capabilities })
    local map = require('mini.keymap').map_multistep
    --   -- Navigate 'mini.completion' menu with `<Tab>` /  `<S-Tab>`
    map('i', '<Tab>', { 'pmenu_next' })
    map('i', '<S-Tab>', { 'pmenu_prev' })
    map('i', '<CR>', { 'pmenu_accept' })
  end,
  --
  --[[
    --
    --
    -- SNIPPETS
    --
    --]]
  --
  --
  --
  setup_mini_snippets = function()
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
  end,
}
