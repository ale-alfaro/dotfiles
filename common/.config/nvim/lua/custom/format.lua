--[[
--
      formatters = {
        my_formatter = {
          -- This can be a string or a function that returns a string.
          -- When defining a new formatter, this is the only field that is required
          command = "my_cmd",
          -- A list of strings, or a function that returns a list of strings
          -- Return a single string instead of a list to run the command in a shell
          args = { "--stdin-from-filename", "$FILENAME" },
          -- If the formatter supports range formatting, create the range arguments here
          range_args = function(self, ctx)
            return { "--line-start", ctx.range.start[1], "--line-end", ctx.range["end"][1] }
          end,
          -- Send file contents to stdin, read new contents from stdout (default true)
          -- When false, will create a temp file (will appear in "$FILENAME" args). The temp
          -- file is assumed to be modified in-place by the format command.
          stdin = true,
          -- A function that calculates the directory to run the command in
          cwd = require("conform.util").root_file({ ".editorconfig", "package.json" }),
          -- When cwd is not found, don't run the formatter (default false)
          require_cwd = true,
          -- When stdin=false, use this template to generate the temporary file that gets formatted
          tmpfile_format = ".conform.$RANDOM.$FILENAME",
          -- When returns false, the formatter will not be used
          condition = function(self, ctx)
            return vim.fs.basename(ctx.filename) ~= "README.md"
          end,
          -- Exit codes that indicate success (default { 0 })
          exit_codes = { 0, 1 },
          -- Environment variables. This can also be a function that returns a table.
          env = {
            VAR = "value",
          },
          -- Set to false to disable merging the config with the base definition.
          -- Can also be set to the name of the formatter to merge with (e.g. inherit = "black")
          inherit = true,
          -- When inherit = true, add these additional arguments to the beginning of the command.
          -- This can also be a function, like args
          prepend_args = { "--use-tabs" },
          -- When inherit = true, add these additional arguments to the end of the command.
          -- This can also be a function, like args
          append_args = { "--trailing-comma" },
        },
        -- These can also be a function that returns the formatter
        other_formatter = function(bufnr)
          return {
            command = "my_cmd",
          }
        end,
      },
--]]
--
--- Recipes taken from https://github.com/stevearc/conform.nvim/blob/master/doc/recipes.md

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

    cmakeformat = {
      command = 'cmake-format',
      args = { '--in-place', '$FILENAME' },
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
    -- c = { name = 'clangd', timeout_ms = 500, lsp_format = 'prefer' },
    c = { 'clang-format', 'uncrustify' }, -- try out uncrustify
    cpp = { name = 'clangd', timeout_ms = 500, lsp_format = 'prefer' },
    cmakeformat = { 'cmakeformat', timeout = 500, lsp_format = 'fallback' },
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
    json = { 'prettier' },
    jsonc = { 'prettier' },
    yaml = { 'prettier' },
    typst = { 'typstyle' },
    -- yaml = { 'yamlfmt' },
    -- ['*'] = { 'codespell' },
    ['_'] = { 'trim_whitespace' },
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
