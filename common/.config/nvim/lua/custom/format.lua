vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
-- vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
require('conform').setup {
  notify_on_error = false,
  notify_no_formatters = false,
  -- toggle autoformatting
  format_on_save = function(bufnr)
    -- Disable with a global or buffer-local variable
    if not FeatureFlags:get 'Format' then
      return
    end
    return {}
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
    ruff_unsafe = {
      inherit = 'ruff_fix',
      append_args = {
        '--unsafe-fixes',
        '--select=I001',
      },
    },

    kconfigstyle = {
      command = 'kconfigstyle',
      args = { '--preset', 'zephyr', '-w', '$FILENAME' },
      stdin = false,
    },

    cmakelang = {
      command = 'cmake-format',
      args = { '--in-place', '$FILENAME' },
      stdin = false,
    },
    prettier = {
      -- Require a Prettier configuration file to format.
      prettier = { require_cwd = true },
    },
  },
  formatters_by_ft = {
    c = { name = 'clang-format', timeout_ms = 500, lsp_format = 'prefer' },
    -- c = { 'clang-format' }, -- try out uncrustify
    cpp = { name = 'clangd', timeout_ms = 500, lsp_format = 'prefer' },
    cmake = { 'cmakelang' },
    dts = { name = 'devicetree_ls', timeout_ms = 500, lsp_format = 'prefer' },
    kconfig = { 'kconfigstyle' },
    lua = { 'stylua' },
    sh = { 'shfmt' },
    just = { 'just' },
    -- # Example of using shfmt with extra args
    python = {
      -- To fix auto-fixable lint errors.
      'ruff_unsafe',
      -- To run the Ruff formatter.
      'ruff_format',
    },
    zsh = { 'shfmt' },
    markdown = { 'prettier' },
    toml = { 'taplo', lsp_format = 'prefer' },
    json = { 'prettier' },
    jsonc = { 'prettier' },
    yaml = { 'prettier' },
    typst = { 'typstyle' },
    javascript = { 'prettier', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
    javascriptreact = { 'prettier', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
    scss = { 'prettier' },
    typescript = { 'prettier', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
    typescriptreact = { 'prettier', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
    ['_'] = { 'trim_whitespace', 'trim_newlines' },
  },
}

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
