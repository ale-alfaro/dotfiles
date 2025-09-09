return { -- Autoformat
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },

  cmd = { 'ConformInfo', 'ConformEnable', 'ConformDisable', 'ConformToggle' },
  keys = {
    {
      '<leader>fb',
      function()
        require('conform').format { async = true, lsp_format = 'fallback' }
      end,
      mode = '',
      desc = '[F]ormat [B]uffer',
    },
  },
  config = function()
    require('conform').setup {
      -- Set the log level. Use `:ConformInfo` to see the location of the log file.
      log_level = vim.log.levels.ERROR,
      -- Conform will notify you when a formatter errors
      notify_on_error = true,
      -- Conform will notify you when no formatters are available for the buffer
      notify_no_formatters = true,
      format_on_save = function(bufnr)
        -- Disable with a global or buffer-local variable
        if vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 500, lsp_fallback = true }
      end,

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
        -- Use the "_" filetype to run formatters on filetypes that don't
        -- have other formatters configured.
        go = { 'gofmt' },
        gomod = { 'gofmt' },
        -- Conform will run multiple formatters sequentially
        -- go = { 'goimports', 'gofmt' },
        -- You can also customize some of the format options for the filetype
        rust = { 'rustfmt', lsp_format = 'fallback' },
        -- Conform can also run multiple formatters sequentially
        -- You can use a function here to determine the formatters dynamically

        c = { 'clang_format' },
        cpp = { 'clang_format' },
        cmake = { 'cmake_format' },
        json = { 'jq' },
        just = { 'justfmt' },
        xml = { 'xmllint' },
        --
        -- You can use 'stop_after_first' to run the first available formatter from the list

        -- Use the "*" filetype to run formatters on all filetypes.
        ['*'] = { 'codespell' },
        -- Use the "_" filetype to run formatters on filetypes that don't
        -- have other formatters configured.
        ['_'] = { 'trim_whitespace' },
      }, -- formatters_by_ft
    } -- conform.setup

    vim.api.nvim_create_user_command('ConformDisable', function()
      vim.b.disable_autoformat = true
    end, {
      desc = 'Disable Formatter',
    })
    vim.api.nvim_create_user_command('ConformEnable', function()
      vim.b.disable_autoformat = false
    end, {
      desc = 'Enable Formatter',
    })

    vim.api.nvim_create_user_command('ConformToggle', function()
      if vim.b.disable_autoformat then
        vim.cmd 'ConformEnable'
      else
        vim.cmd 'ConformDisable'
      end
    end, {
      desc = 'Toggle Formatter',
    })
  end,
}
