
 vim.pack.add(_G.plug_spec ({ 
  'catppuccin/nvim',
   'folke/noice.nvim' ,              
   'folke/snacks.nvim' ,             
   'akinsho/bufferline.nvim' ,       
   'folke/which-key.nvim' ,          
   'mrjones2014/smart-splits.nvim' , 
   'MunifTanjim/nui.nvim' ,          
   'rcarriga/nvim-notify' ,          
}))

require('noice').setup {
  lsp = {
    -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
    override = {
      ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
      ['vim.lsp.util.stylize_markdown'] = true,
      ['cmp.entry.get_documentation'] = true, -- requires hrsh7th/nvim-cmp
    },
  },
  -- you can enable a preset for easier configuration
  presets = {
    bottom_search = true,         -- use a classic bottom cmdline for search
    command_palette = true,       -- position the cmdline and popupmenu together
    long_message_to_split = true, -- long messages will be sent to a split
    inc_rename = false,           -- enables an input dialog for inc-rename.nvim
    lsp_doc_border = false,       -- add a border to hover docs and signature help
  },
}
_G.keymaps_define {
  {
    lhs = '<leader>nh',
    rhs = '<Cmd>Noice All<CR>',
    opts = { desc = '[N]otification [H]istory' },
  },
}
require('mini.starter').setup()
require('mini.statusline').setup()
require('bufferline').setup {
  options = {
    show_close_icon = false,
    show_buffer_close_icons = false,
    truncate_names = false,
    indicator = { style = 'underline' },
    close_command = function(bufnr)
      require('mini.bufremove').delete(bufnr, false)
    end,
    diagnostics = 'nvim_lsp',
    diagnostics_indicator = function(_, _, diag)
      local icons = require('icons').diagnostics
      local indicator = (diag.error and icons.ERROR .. ' ' or '') .. (diag.warning and icons.WARN or '')
      return vim.trim(indicator)
    end,
  },
}
_G.keymaps_define ({
  { lhs = '<leader>bp', rhs = '<Cmd>BufferLinePick<CR>',                 opts = { desc = 'Pick a buffer to open' } },
  { lhs = '<leader>bc', rhs = '<Cmd>BufferLinePickClose<CR>, true)<CR>', opts = { desc = 'Select a buffer to close' } },
  { lhs = '<leader>br', rhs = '<Cmd>BufferLineCloseRight<CR>',           opts = { desc = 'Close buffer to the left' } },
  { lhs = '<leader>bl', rhs = '<Cmd>BufferLineCloseLeft<CR>',            opts = { desc = 'Close buffer to the right' } },
  { lhs = '<leader>bo', rhs = '<Cmd>BufferLineCloseOthers<CR>',          opts = { desc = 'Close other buffers' } },
})
require('catppuccin').setup({
      flavour = 'macchiato', -- latte, frappe, macchiato, mocha
      background = {         -- :h background
        light = 'latte',
        dark = 'mocha',
      },
})
vim.cmd 'colorscheme catppuccin'
-- It is not enabled by default because it is not really needed on a daily basis.
-- Uncomment next line (use `gcc`) to enable.
require('mini.hipatterns').setup {
  highlighters = {
    fixme = require('mini.extra').gen_highlighter.words({ 'FIXME', 'Fixme', 'fixme' }, 'MiniHipatternsFixme'),
    hack = require('mini.extra').gen_highlighter.words({ 'HACK', 'Hack', 'hack' }, 'MiniHipatternsHack'),
    todo = require('mini.extra').gen_highlighter.words({ 'TODO', 'Todo', 'todo' }, 'MiniHipatternsTodo'),
    note = require('mini.extra').gen_highlighter.words({ 'NOTE', 'Note', 'note' }, 'MiniHipatternsNote'),
    hex_color = require('mini.hipatterns').gen_highlighter.hex_color(),
  },
}

-- Which-key
require('which-key').setup {
  preset = 'helix',
  defaults = {},
  spec = {
    mode = { 'n', 'v' },
    { '<leader>c', group = 'Code' },
    { '<leader>d', group = 'Diff' },
    { '<leader>f', group = 'File/find' },
    { '<leader>g', group = 'Git' },
    { '<Leader>s', group = '+Search',
      { '<Leader>v', group = '+Visits' },
      { '<leader>u', group = 'ui' },
      { '<leader>x', group = 'diagnostics/quickfix' },
      { '[',         group = 'prev' },
      { ']',         group = 'next' },
      { 'g',         group = 'goto' },
      { 'gs',        group = 'surround' },
      { 'z',         group = 'fold' },
      {
        '<leader>b',
        group = 'buffer',
        expand = function()
          return require('which-key.extras').expand.buf()
        end,
      },
      {
        '<leader>w',
        group = 'windows',
        proxy = '<c-w>',
        expand = function()
          return require('which-key.extras').expand.win()
        end,
      },
    },
  },
}
