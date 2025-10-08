---@module 'lazyvim'
---@module 'null-ls'
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
      python = {
        -- To fix auto-fixable lint errors.
        'ruff_fix',
        -- To run the Ruff formatter.
        'ruff_format',
        -- To organize the imports.
        'ruff_organize_imports',
      },
      sh = { 'shfmt' },
      zsh = { 'shfmt' },
      markdown = { 'mdformat' },
      go = { 'goimports', 'gofumpt' },
      gomod = { 'goimports', 'gofumpt' },
      c = { 'clang_format' },
      cpp = { 'clang_format' },
      cmake = { 'cmake_format' },
      yaml = { 'yamlfmt' },
      just = { 'justfmt' },
      -- ['*'] = { 'codespell' },
      -- ['_'] = { 'trim_whitespace' },
    },
  },
  {
    -- none-ls
    -- {
    'nvimtools/none-ls.nvim',
    opts = function(_, opts)
      local nls = require 'null-ls'
      opts.root_dir = opts.root_dir or require('null-ls.utils').root_pattern('.null-ls-root', '.neoconf.json', 'Makefile', '.git')
      opts.sources = vim.list_extend(opts.sources or {}, {
        nls.builtins.formatting.stylua,
        nls.builtins.formatting.shfmt,
      })
    end,
    --   event = "LazyFile",
    --   dependencies = { "mason.nvim" },
    --   init = function()
    --     LazyVim.on_very_lazy(function()
    --       -- register the formatter with LazyVim
    --       LazyVim.format.register({
    --         name = "none-ls.nvim",
    --         priority = 200, -- set higher than conform, the builtin formatter
    --         primary = true,
    --         format = function(buf)
    --           return LazyVim.lsp.format({
    --             bufnr = buf,
    --             filter = function(client)
    --               return client.name == "null-ls"
    --             end,
    --           })
    --         end,
    --         sources = function(buf)
    --           local ret = require("null-ls.sources").get_available(vim.bo[buf].filetype, "NULL_LS_FORMATTING") or {}
    --           return vim.tbl_map(function(source)
    --             return source.name
    --           end, ret)
    --         end,
    --       })
    --     end)
    --   end,
    --   opts = function(_, opts)
    --     local nls = require("null-ls")
    --     opts.root_dir = opts.root_dir
    --       or require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", "Makefile", ".git")
    --     opts.sources = vim.list_extend(opts.sources or {}, {
    --       nls.builtins.formatting.fish_indent,
    --       nls.builtins.diagnostics.fish,
    --       nls.builtins.formatting.stylua,
    --       nls.builtins.formatting.shfmt,
    --     })
    --   end,
    -- },
  },
}
