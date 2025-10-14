return {
  {
    'benomahony/uv.nvim',
    config = function(_, opts)
      opts.keymaps = {
        prefix = '<leader>x', -- Main prefix for uv commands
        commands = true, -- Show uv commands menu (<leader>x)
        run_file = false, -- Run current file (<leader>xr)
        run_selection = false, -- Run selected code (<leader>xs)
        run_function = false, -- Run function (<leader>xf)
        venv = true, -- Environment management (<leader>xe)
        init = true, -- Initialize uv project (<leader>xi)
        add = true, -- Add a package (<leader>xa)
        remove = true, -- Remove a package (<leader>xd)
        sync = false, -- Sync packages (<leader>xc)
        sync_all = false, -- Sync all packages, extras and groups (<leader>xC)
      }
      require('custom.python.uv').setup(opts)
    end,
  },
  -- {
  --
  --   'nvimtools/none-ls.nvim',
  --   dependencies = { 'benomahony/uv.nvim' },
  --   opts = function(_, opts)
  --     opts = opts or {}
  --     vim.list_extend(opts.sources, require 'custom.python.none_ls')
  -- local diagnostics_on_save = require 'custom.python.diagnostics_on_save'
  -- local code_actions = require 'custom.python.code_actions'

  -- on_attach = function(client, bufnr)
  --   if client.name == 'null-ls' then
  --     -- you can add more on_attach logic here if needed
  --   end
  -- end,
  --   end,
  -- },
}
