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
}
