--- Recipes taken from https://github.com/stevearc/conform.nvim/blob/master/doc/recipes.md
local function user_cmd_create()
  -- Command for async formatting
  vim.api.nvim_create_user_command('Format', function(args)
    local range = nil
    if args.count ~= -1 then
      local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
      range = {
        start = { args.line1, 0 },
        ['end'] = { args.line2, end_line:len() },
      }
    end
    require('conform').format { async = true, lsp_format = 'fallback', range = range }
  end, { range = true })
end

local function autocmd_create()
  -- Run LSP command before formatting
  vim.api.nvim_create_autocmd('BufWritePre', {
    desc = 'Format before save',
    pattern = 'python',
    group = vim.api.nvim_create_augroup('FormatConfig', { clear = true }),
    callback = function(ev)
      local conform_opts = { bufnr = ev.buf, lsp_format = 'fallback', timeout_ms = 2000 }
      local client = vim.lsp.get_clients({ name = 'ruff', bufnr = ev.buf })[1]

      if not client then
        require('conform').format(conform_opts)
        return
      end

      local request_result = client:request_sync('workspace/executeCommand', {
        command = 'ruff.organizeImports',
        arguments = { vim.api.nvim_buf_get_name(ev.buf) },
      })

      if request_result and request_result.err then
        vim.notify(request_result.err.message, vim.log.levels.ERROR)
        return
      end

      require('conform').format(conform_opts)
    end,
  })
end

local function setup_formatting()
  vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  require('conform').setup {
    default_format_opts = {
      timeout_ms = 3000,
      async = false, -- not recommended to change
      quiet = false, -- not recommended to change
      lsp_format = 'fallback', -- not recommended to change
    },
    -- toggle autoformatting
    format_on_save = function(bufnr)
      -- Disable with a global or buffer-local variable
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end
      return { timeout_ms = 500, lsp_format = 'fallback' }
    end,
    formatters = {
      shfmt = {
        prepend_args = { '-i', '2', '-ci' },
      },
      just = {
        env = {
          JUST_UNSTABLE = 1,
        },
      },
      prettier = {
        options = {
          ft_parsers = {
            less = 'less',
            html = 'html',
            json = 'json',
            jsonc = 'json',
            yaml = 'yaml',
            markdown = 'markdown',
            typst = 'typst',
            ['markdown.mdx'] = 'mdx',
          },
        },
      },
    },
    formatters_by_ft = {
      c = { name = 'clangd', timeout_ms = 500, lsp_format = 'prefer' },
      cpp = { name = 'clangd', timeout_ms = 500, lsp_format = 'prefer' },
      cmake = { 'cmake_format' },
      lua = { 'stylua' },
      fish = { 'fish_indent' },
      sh = { 'shfmt' },
      just = { 'just' },
      -- # Example of using shfmt with extra args
      python = {
        -- To fix auto-fixable lint errors.
        'ruff_fix',
        -- To run the Ruff formatter.
        'ruff_format',
        -- To organize the imports.
        'ruff_organize_imports',
      },
      zsh = { 'shfmt' },
      markdown = { 'prettier' },
      json = { 'prettier' },
      jsonc = { 'prettier' },
      yaml = { 'prettier' },
      typst = { 'typstyle' },
      -- yaml = { 'yamlfmt' },
      -- ['*'] = { 'codespell' },
      ['_'] = { 'trim_whitespace' },
    },
  }

  user_cmd_create()
  autocmd_create()
end

return { setup = setup_formatting }
