return { -- Autoformat
  'stevearc/conform.nvim',
  -- keys = {
  --   {
  --     '<leader>fb',
  --     function()
  --       require('conform').format { async = true, lsp_format = 'fallback' }
  --     end,
  --     mode = '',
  --     desc = '[F]ormat [B]uffer',
  --   },
  -- },
  opts = {

    formatters = {
      justfmt = {
        -- This can be a string or a function that returns a string.
        -- When defining a new formatter, this is the only field that is required
        command = 'just',
        -- A list of strings, or a function that returns a list of strings
        -- Return a single string instead of a list to run the command in a shell
        args = { '--dump', '--unstable' },
        -- When false, will create a temp file (will appear in "$FILENAME" args). The temp
        -- file is assumed to be modified in-place by the format command.
        stdin = false,
        -- A function that calculates the directory to run the command in
        cwd = require('conform.util').root_file { 'justfile' },
        -- When cwd is not found, don't run the formatter (default false)
        require_cwd = true,
        -- When stdin=false, use this template to generate the temporary file that gets formatted
        tmpfile_format = 'justfile.$RANDOM.$FILENAME',
        -- When returns false, the formatter will not be used
        -- condition = function(self, ctx)
        --   return vim.fs.basename(ctx.filename) ~= 'justfile'
        -- end,
        -- Exit codes that indicate success (default { 0 })
        -- exit_codes = { 0  },
        -- Environment variables. This can also be a function that returns a table.
        env = {
          JUST_UNSTABLE = 1,
        },
        -- Set to false to disable merging the config with the base definition
        inherit = true,
        -- When inherit = true, add these additional arguments to the beginning of the command.
        -- This can also be a function, like args
        -- prepend_args = { '--use-tabs' },
        -- When inherit = true, add these additional arguments to the end of the command.
        -- This can also be a function, like args
        -- append_args = { '--trailing-comma' },
      },
    }, -- formatters
    formatters_by_ft = {
      lua = { 'stylua' },
      python = { 'ruff_fix', 'ruff_format' },
      sh = { 'shfmt' },
      zsh = { 'shfmt' },
      markdown = { 'mdformat' },
      go = { 'goimports', 'gofumpt' },
      gomod = { 'goimports', 'gofumpt' },
      rust = { 'rustfmt', lsp_format = 'fallback' },
      c = { 'clang_format' },
      cpp = { 'clang_format' },
      cmake = { 'cmake_format' },
      json = { 'jq' },
      yaml = { 'yamlfmt' },
      just = { 'justfmt' },
      xml = { 'xmllint' },
      ['*'] = { 'codespell' },
      ['_'] = { 'trim_whitespace' },
    },
  },
}
