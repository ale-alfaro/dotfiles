---@module 'lazyvim'
---@module 'lint'
return {
  { -- Autoformat
    'stevearc/conform.nvim',
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
    opts = function(_, opts)
      opts = opts or {}
      ---@type lint.Linter[]
      opts.formatters = {
        -- # Example of using shfmt with extra args
        shfmt = {
          prepend_args = { '-i', '2', '-ci' },
        },
        just = {
          env = {
            JUST_UNSTABLE = 1,
          },
        },
      }
      opts.formatters_by_ft = {
        python = {
          -- To fix auto-fixable lint errors.
          'ruff_fix',
          -- To run the Ruff formatter.
          'ruff_format',
          -- To organize the imports.
          'ruff_organize_imports',
        },
        zsh = { 'shfmt' },
        markdown = { 'mdformat' },
        yaml = { 'yamlfmt' },
        just = { 'just' },
        -- ['*'] = { 'codespell' },
        -- ['_'] = { 'trim_whitespace' },
      }
      -- LazyVim.format.register({
      --
      -- })
    end,
  },
  {
    'mfussenegger/nvim-lint',
    event = 'LazyFile',
    opts = {
      -- Event to trigger linters
      events = { 'BufWritePost', 'BufReadPost', 'InsertLeave' },
      linters_by_ft = {
        python = { 'ruff' },
        -- just = { 'just' },
        zsh = { 'zsh' },
        -- Use the "*" filetype to run linters on all filetypes.
        -- ['*'] = { 'global linter' },
        -- Use the "_" filetype to run linters on filetypes that don't have other linters configured.
        -- ['_'] = { 'fallback linter' },
        -- ["*"] = { "typos" },
      },
      -- LazyVim extension to easily override linter options
      -- or add custom linters.
      ---@type table<string,table>
      linters = {
        -- just = {
        --
        --   command = 'just',
        --   args = { '--fmt', '--unstable', '-f', '$FILENAME' },
        --   stdin = false,
        --   ignore_exitcode = true,
        --   parser = require('lint.parser').from_pattern(pattern, groups, nil, {
        --     ['source'] = 'cmakelint',
        --     ['severity'] = vim.diagnostic.severity.WARN,
        --   }),
        -- },
      },
    },
  },
}
