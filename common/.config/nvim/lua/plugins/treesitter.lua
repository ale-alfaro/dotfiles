return {
  {
    'echasnovski/mini.surround',
    keys = {},
    opts = {
      mappings = {
        add = 'sa', -- Add surrounding in Normal and Visual modes
        delete = 'sd', -- Delete surrounding
        find = 'sf', -- Find surrounding (to the right)
        find_left = 'sF', -- Find surrounding (to the left)
        highlight = 'sh', -- Highlight surrounding
        replace = 'sr', -- Replace surrounding
        update_n_lines = 'sn', -- Update `n_lines`
      },
    },
  },
  {
    'echasnovski/mini.ai',
  },
  {
    'nvim-treesitter/nvim-treesitter',
    opts = {
      ensure_installed = {
        'bash',
        'c',
        'cpp',
        'cmake',
        'diff',
        'html',
        'kconfig',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'query',
        'vim',
        'vimdoc',
        'just',
        'ninja',
        'toml',
        'rst',
      },
    },
  },
  { 'nvim-treesitter/nvim-treesitter-textobjects' },
}
