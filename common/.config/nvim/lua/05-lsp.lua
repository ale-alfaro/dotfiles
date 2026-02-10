vim.pack.add(_G.plug_spec {
  'neovim/nvim-lspconfig',
  'rachartier/tiny-code-action.nvim',
  'p00f/clangd_extensions.nvim',
  'jmbuhr/otter.nvim',
})

local function diagnostics_setup()
  local diagnostic_icons = VimRc.icons.diagnostics
  -- Disable inlay hints initially (and enable if needed with my ToggleInlayHints command).
  -- Define the diagnostic signs.
  for severity, icon in pairs(diagnostic_icons) do
    local hl = 'DiagnosticSign' .. severity:sub(1, 1) .. severity:sub(2):lower()
    vim.fn.sign_define(hl, { text = icon, texthl = hl })
  end
  vim.diagnostic.config {
    virtual_text = {
      prefix = '',
      spacing = 2,
      format = function(diagnostic)
        -- Use shorter, nicer names for some sources:
        local special_sources = {
          ['Lua Diagnostics.'] = 'lua',
          ['Lua Syntax Check.'] = 'lua',
        }

        local message = diagnostic_icons[vim.diagnostic.severity[diagnostic.severity]]
        if diagnostic.source then
          message = string.format('%s %s', message, special_sources[diagnostic.source] or diagnostic.source)
        end
        if diagnostic.code then
          message = string.format('%s[%s]', message, diagnostic.code)
        end

        return message .. ' '
      end,
    },
    float = {
      source = true, --'if_many',
      -- Show severity icons as prefixes.
      prefix = function(diag)
        local level = vim.diagnostic.severity[diag.severity]
        local prefix = string.format(' %s ', diagnostic_icons[level])
        return prefix, 'Diagnostic' .. level:gsub('^%l', string.upper)
      end,
    },
    -- Disable signs in the gutter.
    signs = false,
  }
  -- Override the virtual text diagnostic handler so that the most severe diagnostic is shown first.
  local show_handler = vim.diagnostic.handlers.virtual_text.show
  assert(show_handler)
  local hide_handler = vim.diagnostic.handlers.virtual_text.hide
  vim.diagnostic.handlers.virtual_text = {
    show = function(ns, bufnr, diagnostics, opts)
      table.sort(diagnostics, function(diag1, diag2)
        return diag1.severity > diag2.severity
      end)
      return show_handler(ns, bufnr, diagnostics, opts)
    end,
    hide = hide_handler,
  }

  local hover = vim.lsp.buf.hover
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.lsp.buf.hover = function()
    return hover {
      max_height = math.floor(vim.o.lines * 0.5),
      max_width = math.floor(vim.o.columns * 0.4),
    }
  end

  local signature_help = vim.lsp.buf.signature_help
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.lsp.buf.signature_help = function()
    return signature_help {
      max_height = math.floor(vim.o.lines * 0.5),
      max_width = math.floor(vim.o.columns * 0.4),
    }
  end
  return require 'lsp.custom_diagnostics'
end
VimRc.diagnostics = diagnostics_setup()
local lsp_servers = { 'lua_ls', 'tinymyst', 'esbonio', 'clangd', 'neocmake', 'bashls', 'taplo', 'yamls', 'jsonls', 'marksman', 'ruff', 'pyrefly' }
local lspau = vim.api.nvim_create_augroup('vimrc.lsp', {})
vim.api.nvim_create_autocmd('LspAttach', {
  group = lspau,
  desc = 'Configure LSP keymaps',
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    -- I don't think this can happen but it's a wild world out there.
    if not client then
      return
    end
    local bufnr = args.buf
    if client:supports_method 'textDocument/documentHighlight' then
      local under_cursor_highlights_group = vim.api.nvim_create_augroup('mariasolos/cursor_highlights', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'InsertLeave' }, {
        group = under_cursor_highlights_group,
        desc = 'Highlight references under the cursor',
        buffer = bufnr,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'InsertEnter', 'BufLeave' }, {
        group = under_cursor_highlights_group,
        desc = 'Clear highlight references',
        buffer = bufnr,
        callback = vim.lsp.buf.clear_references,
      })
    end

    if client:supports_method 'textDocument/inlayHint' then
      vim.api.nvim_create_user_command('InlayHints', function()
        vim.g.inlay_hints = false
        require('lsp.inlay_hints').add_inlay_hint_support(client, bufnr)
      end, { desc = 'Enable InlayHints' })
    end
    VimRc.diagnostics.setup_diagnostics_cursorhold(bufnr)
    if client:supports_method 'textDocument/codeAction' then
      require('lsp.code_action').on_attach(bufnr, client)
    end
    -- if client:supports_method 'workspace/diagnostic' then
    -- local folders = vim.lsp.buf.list_workspace_folders()
    -- VimRc.info 'LSP Client supports workspace diagnostics. Adding user command to fetch them. Current workspace folder: '
    -- VimRc.info(folders)
    -- end

    if client:supports_method 'textDocument/diagnostic' then
      VimRc.diagnostics.setup_workspace_diagnostics(client, bufnr)
      vim.api.nvim_buf_create_user_command(bufnr, 'WorkspaceDiag', function()
        D.populate_workspace_diagnostics(client, bufnr)
        -- vim.lsp.buf.workspace_diagnostics {
        --   client_id = client.id,
        -- }
      end, {})
    end

    -- vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = false })

    -- Don't check for the capability here to allow dynamic registration of the request.
    vim.lsp.document_color.enable(true, bufnr)
    require('lsp.keys').on_attach(bufnr, client)
  end,
})

-- Diagnostic configuration.

-- Set up LSP servers.
vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
  once = true,
  callback = function()
    -- Extend neovim's client capabilities with the completion ones.
    if MiniCompletion then
      vim.lsp.config('*', { capabilities = MiniCompletion.get_lsp_capabilities() })
    else
      vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities(nil, true) })
    end
    vim.lsp.enable(lsp_servers)
  end,
})

local otter = require 'otter'
otter.setup {
  lsp = {
    -- `:h events` that cause the diagnostics to update. Set to:
    -- { "BufWritePost", "InsertLeave", "TextChanged" } for less performant
    -- but more instant diagnostic updates
    diagnostic_update_events = { 'BufWritePost' },
    -- function to find the root dir where the otter-ls is started
    root_dir = function(_, bufnr)
      return vim.fs.root(bufnr or 0, {
        '.git',
        '_quarto.yml',
        'package.json',
      }) or vim.fn.getcwd(0)
    end,
  },
  -- options related to the otter buffers
  buffers = {
    -- if set to true, the filetype of the otterbuffers will be set.
    -- otherwise only the autocommand of lspconfig that attaches
    -- the language server will be executed without setting the filetype
    --- this setting is deprecated and will default to true in the future
    set_filetype = true,
    -- write <path>.otter.<embedded language extension> files
    -- to disk on save of main buffer.
    -- usefule for some linters that require actual files.
    -- otter files are deleted on quit or main buffer close
    write_to_disk = false,
    -- a table of preambles for each language. The key is the language and the value is a table of strings that will be written to the otter buffer starting on the first line.
    preambles = {},
    -- a table of postambles for each language. The key is the language and the value is a table of strings that will be written to the end of the otter buffer.
    postambles = {},
    -- A table of patterns to ignore for each language. The key is the language and the value is a lua match pattern to ignore.
    -- lua patterns: https://www.lua.org/pil/20.2.html
    ignore_pattern = {
      -- ipython cell magic (lines starting with %) and shell commands (lines starting with !)
      python = '^(%s*[%%!].*)',
    },
  },
  -- remove whitespace from the beginning of the code chunks when writing to the otter buffers
  -- and calculate it back in when handling lsp requests
  handle_leading_whitespace = true,
  -- mapping of filetypes to extensions for those not already included in otter.tools.extensions
  -- e.g. ["bash"] = "sh"
  extensions = {
    ['bash'] = 'sh',
    ['zsh'] = 'sh',
  },
  -- add event listeners for LSP events for debugging
  debug = false,
  verbose = { -- set to false to disable all verbose messages
    no_code_found = false, -- warn if otter.activate is called, but no injected code was found
  },
}
