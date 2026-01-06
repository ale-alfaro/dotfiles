-- ┌─────────────────┐
-- │ Custom mappings │
-- └─────────────────┘
--
-- The next part (until `-- stylua: ignore end`) is aligned manually for easier
-- reading. Consider preserving this or remove `-- stylua` lines to autoformat.
_G.keymaps_define {
  -- General & Navigation
  -- stylua: ignore start
  { lhs = "<leader>bb",            rhs = "<cmd>b#<cr>",                      opts = { desc = "Switch to Other Buffer" } },
  {lhs = "<leader>bs", rhs = function() vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(true, true)) end, opts = { desc = "Scratch Buffer"}},
  { lhs = "<leader>bD",            rhs = "<cmd>:%bdelete|edit #|normal`<cr>", opts = { desc = "Close all Other Buffers" } },
  { lhs = "q",                     rhs = "<nop>",                             opts = { noremap = true } },
  { lhs = "Q",                     rhs = "<nop>",                             opts = { noremap = true } },
  { lhs = '[p',                    rhs = '<Cmd>exe "put! " . v:register<CR>', opts = { desc = 'Paste Above' } },
  { lhs = ']p',                    rhs = '<Cmd>exe "put "  . v:register<CR>', opts = { desc = 'Paste Below' } },
  -- stylua: ignore end

  -- File & Config Editing
  {
    mode = { 'n', 'v', 'x' },
    lhs = '<leader>o',
    rhs = '<Cmd>source $MYVIMRC<CR>',
    opts = { desc = 'Source ' .. vim.fn.expand '$MYVIMRC' },
  },
  {
    mode = { 'n', 'v', 'x' },
    lhs = '<leader>O',
    rhs = '<Cmd>source %<CR>',
    opts = { desc = 'Source ' .. vim.fn.expand '%' },
  },
  {
    mode = { 'n', 'v', 'x' },
    lhs = '<M-r>',
    rhs = '<Cmd>restart<CR>',
    opts = { desc = 'Restart vim.', noremap = true },
  },
  {
    mode = { 'n' },
    lhs = '<C-g>',
    rhs = '<Cmd>let @*=expand("%:p") <CR>',
    opts = { desc = 'Copy path of current filename  to clipboard', noremap = true },
  },
  -- Save
  {
    mode = { 'n' },
    lhs = '<C-f>',
    rhs = '<Cmd>Open .<CR>',
    opts = { desc = 'Open current directory in Finder.', noremap = true },
  },
  -- Save
  {
    mode = { 'i', 'x', 'n', 's' },
    lhs = '<C-s>',
    rhs = '<cmd>w<cr><esc>',
    opts = { desc = 'Save File', noremap = true },
  },
  -- Quit
  {
    mode = { 'n' },
    lhs = '<C-q>',
    rhs = '<Cmd>:quit<CR>',
    opts = { desc = 'Quit the current buffer.', noremap = true },
  },
  { lhs = '<M-q>', rhs = '<Cmd>:wqa<CR>', opts = { desc = 'Quit all buffers and write.', noremap = true } },

  -- Buffers
  -- stylua: ignore start
  { lhs = "<S-h>",                 rhs = "<cmd>bprevious<cr>",                opts = { desc = "Prev Buffer" } },
  { lhs = "<S-l>",                 rhs = "<cmd>bnext<cr>",                    opts = { desc = "Next Buffer" } },
  { lhs = "[b",                    rhs = "<cmd>bprevious<cr>",                opts = { desc = "Prev Buffer" } },
  { lhs = "]b",                    rhs = "<cmd>bnext<cr>",                    opts = { desc = "Next Buffer" } },
  { lhs = '<leader>ba',            rhs = '<Cmd>b#<CR>',                       opts = { desc = 'Alternate' } },
  -- stylua: ignore end

  -- Search
  { lhs = 'n', rhs = "'Nn'[v:searchforward].'zv'", opts = { expr = true, desc = 'Next Search Result' } },
  {
    mode = 'x',
    lhs = 'n',
    rhs = "'Nn'[v:searchforward]",
    opts = { expr = true, desc = 'Next Search Result' },
  },
  {
    mode = 'o',
    lhs = 'n',
    rhs = "'Nn'[v:searchforward]",
    opts = { expr = true, desc = 'Next Search Result' },
  },
  { lhs = 'N', rhs = "'nN'[v:searchforward].'zv'", opts = { expr = true, desc = 'Prev Search Result' } },
  {
    mode = 'x',
    lhs = 'N',
    rhs = "'nN'[v:searchforward]",
    opts = { expr = true, desc = 'Prev Search Result' },
  },
  {
    mode = 'o',
    lhs = 'N',
    rhs = "'nN'[v:searchforward]",
    opts = { expr = true, desc = 'Prev Search Result' },
  },

  -- Insert Mode Enhancements
  { mode = 'i', lhs = ',', rhs = ',<c-g>u' },
  { mode = 'i', lhs = '.', rhs = '.<c-g>u' },
  { mode = 'i', lhs = ';', rhs = ';<c-g>u' },

  -- Visual Mode Enhancements
  { mode = 'v', lhs = '<', rhs = '<gv' },
  { mode = 'v', lhs = '>', rhs = '>gv' },


  -- Quickfix
  -- stylua: ignore start
  { lhs = '[q', rhs = vim.cmd.cprev, opts = { desc = 'Previous Quickfix' } },
  { lhs = ']q', rhs = vim.cmd.cnext, opts = { desc = 'Next Quickfix' } },
  -- Diagnostics
  { lhs = "<leader>cd", rhs = vim.diagnostic.open_float,                                                            opts = { desc = "Line Diagnostics" } },
  { lhs = "]e",         rhs = function() vim.diagnostic.get_next({ severity = vim.diagnostic.severity.ERROR }) end, opts = { desc = "Next Error" } },
  { lhs = "[e",         rhs = function() vim.diagnostic.get_prev({ severity = vim.diagnostic.severity.ERROR }) end, opts = { desc = "Prev Error" } },
  { lhs = "]w",         rhs = function() vim.diagnostic.get_next({ severity = vim.diagnostic.severity.WARN }) end,  opts = { desc = "Next Warning" } },
  { lhs = "[w",         rhs = function() vim.diagnostic.get_prev({ severity = vim.diagnostic.severity.WARN }) end,  opts = { desc = "Prev Warning" } },
  -- stylua: ignore end
}
