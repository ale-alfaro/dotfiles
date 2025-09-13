return {
  {
    'benomahony/uv.nvim',
    ft = { 'python' },
    dependencies = { 'folke/snacks.nvim' },
    opts = {
      picker_integration = true,
    },
  },
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/neotest-plenary',
      'nvim-neotest/neotest-go',
      'nvim-neotest/nvim-nio',
    },
    opts = {
      adapters = {
        'neotest-plenary',
        'neotest-go',
        'neotest-python',
      },
      status = { virtual_text = true },
      output = { open_on_run = true },
      summary = { open_on_run = true },
    },
  },
  {
    'nvim-lualine/lualine.nvim',
    opts = function(_, opts)
      local trouble = require 'trouble'
      local symbols = trouble.statusline {
        mode = 'lsp_document_symbols',
        groups = {},
        title = false,
        filter = { range = true },
        format = '{kind_icon}{symbol.name:Normal}',
        hl_group = 'lualine_c_normal',
      }
      table.insert(opts.sections.lualine_c, {
        symbols.get,
        cond = symbols.has,
      })
    end,
  },
}
