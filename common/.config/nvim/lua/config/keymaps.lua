-- ┌─────────────────┐
-- │ Custom mappings │
-- └─────────────────┘
--
-- stylua: ignore start
-- The next part (until `-- stylua: ignore end`) is aligned manually for easier
-- reading. Consider preserving this or remove `-- stylua` lines to autoformat.
_G.keymaps_define({
  -- General & Navigation
  -- stylua:ignore
  { lhs = "<leader>bb",            rhs = "<cmd>e #<cr>",                      opts = { desc = "Switch to Other Buffer" } },
  { lhs = "<leader>bD",            rhs = "<cmd>:%bdelete|edit #|normal`<cr>", opts = { desc = "Close all Other Buffers" } },
  { lhs = "q",                     rhs = "<nop>",                             opts = { noremap = true } },
  { lhs = "Q",                     rhs = "q",                                 opts = { noremap = true } },
  { lhs = "<M-q>",                 rhs = "Q",                                 opts = { desc = "Replay last register", noremap = true } },
  { mode = { "n" },                lhs = "<C-q>",                             rhs = ":copen<CR>",                                      opts = { silent = true } },
  { mode = { "n" },                lhs = "<leader>u",                         rhs = "<Cmd>update<CR>",                                 opts = { desc = "Write the current buffer." } },
  { mode = { "n" },                lhs = "<leader>q",                         rhs = "<Cmd>:quit<CR>",                                  opts = { desc = "Quit the current buffer." } },
  { mode = { "n" },                lhs = "<leader>Q",                         rhs = "<Cmd>:wqa<CR>",                                   opts = { desc = "Quit all buffers and write." } },
  { mode = { "n" },                lhs = "<C-f>",                             rhs = "<Cmd>Open .<CR>",                                 opts = { desc = "Open current directory in Finder." } },
  { lhs = '[p',                    rhs = '<Cmd>exe "put! " . v:register<CR>', opts = { desc = 'Paste Above' } },
  { lhs = ']p',                    rhs = '<Cmd>exe "put "  . v:register<CR>', opts = { desc = 'Paste Below' } },

  -- File & Config Editing
  -- stylua:ignore
  { mode = { "n", "v", "x" },      lhs = "<leader>ev",                        rhs = "<Cmd>edit $MYVIMRC<CR>",                          opts = { desc = "Edit " .. vim.fn.expand("$MYVIMRC") } },
  { mode = { "n", "v", "x" },      lhs = "<leader>ez",                        rhs = "<Cmd>e $ZDOTDIR<CR>",                             opts = { desc = "Edit .zshrc" } },
  { mode = { "n", "v", "x" },      lhs = "<leader>eh",                        rhs = "<Cmd>e $XDG_CONFIG_HOME/hypr/hyprland<CR>",       opts = { desc = "Edit Hyprland Config" } },
  { mode = { "n", "v", "x" },      lhs = "<leader>sO",                        rhs = "<Cmd>source %<CR>",                               opts = { desc = "Source " .. vim.fn.expand("$MYVIMRC") } },
  { mode = { 'n', 'v', 'x' },      lhs = '<leader>O',                         rhs = '<Cmd>restart<CR>',                                opts = { desc = 'Restart vim.' } },

  -- Buffers
  -- stylua:ignore
  { lhs = "<S-h>",                 rhs = "<cmd>bprevious<cr>",                opts = { desc = "Prev Buffer" } },
  { lhs = "<S-l>",                 rhs = "<cmd>bnext<cr>",                    opts = { desc = "Next Buffer" } },
  { lhs = "[b",                    rhs = "<cmd>bprevious<cr>",                opts = { desc = "Prev Buffer" } },
  { lhs = "]b",                    rhs = "<cmd>bnext<cr>",                    opts = { desc = "Next Buffer" } },
  { lhs = '<leader>ba',            rhs = '<Cmd>b#<CR>',                       opts = { desc = 'Alternate' } },

  -- Search
  -- stylua:ignore
  { lhs = "n",                     rhs = "'Nn'[v:searchforward].'zv'",        opts = { expr = true, desc = "Next Search Result" } },
  { mode = "x",                    lhs = "n",                                 rhs = "'Nn'[v:searchforward]",                           opts = { expr = true, desc = "Next Search Result" } },
  { mode = "o",                    lhs = "n",                                 rhs = "'Nn'[v:searchforward]",                           opts = { expr = true, desc = "Next Search Result" } },
  { lhs = "N",                     rhs = "'nN'[v:searchforward].'zv'",        opts = { expr = true, desc = "Prev Search Result" } },
  { mode = "x",                    lhs = "N",                                 rhs = "'nN'[v:searchforward]",                           opts = { expr = true, desc = "Prev Search Result" } },
  { mode = "o",                    lhs = "N",                                 rhs = "'nN'[v:searchforward]",                           opts = { expr = true, desc = "Prev Search Result" } },

  -- Insert Mode Enhancements
  -- stylua:ignore
  { mode = "i",                    lhs = ",",                                 rhs = ",<c-g>u" },
  { mode = "i",                    lhs = ".",                                 rhs = ".<c-g>u" },
  { mode = "i",                    lhs = ";",                                 rhs = ";<c-g>u" },

  -- Save
  -- stylua:ignore
  { mode = { "i", "x", "n", "s" }, lhs = "<C-s>",                             rhs = "<cmd>w<cr><esc>",                                 opts = { desc = "Save File" } },

  -- Visual Mode Enhancements
  -- stylua:ignore
  { mode = "v",                    lhs = "<",                                 rhs = "<gv" },
  { mode = "v",                    lhs = ">",                                 rhs = ">gv" },

  -- Quickfix & Location Lists
  {
    lhs = "<leader>xl",
    rhs = function()
      local success, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
      if not success and err then vim.notify(err, vim.log.levels.ERROR) end
    end,
    opts = { desc = "Location List" }
  },
  {
    lhs = "<leader>xq",
    rhs = function()
      local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
      if not success and err then vim.notify(err, vim.log.levels.ERROR) end
    end,
    opts = { desc = "Quickfix List" }
  },
  { lhs = "[q",         rhs = vim.cmd.cprev,                                                                        opts = { desc = "Previous Quickfix" } },
  { lhs = "]q",         rhs = vim.cmd.cnext,                                                                        opts = { desc = "Next Quickfix" } },

  -- Diagnostics
  -- stylua:ignore
  { lhs = "<leader>cd", rhs = vim.diagnostic.open_float,                                                            opts = { desc = "Line Diagnostics" } },
  { lhs = "]e",         rhs = function() vim.diagnostic.get_next({ severity = vim.diagnostic.severity.ERROR }) end, opts = { desc = "Next Error" } },
  { lhs = "[e",         rhs = function() vim.diagnostic.get_prev({ severity = vim.diagnostic.severity.ERROR }) end, opts = { desc = "Prev Error" } },
  { lhs = "]w",         rhs = function() vim.diagnostic.get_next({ severity = vim.diagnostic.severity.WARN }) end,  opts = { desc = "Next Warning" } },
  { lhs = "[w",         rhs = function() vim.diagnostic.get_prev({ severity = vim.diagnostic.severity.WARN }) end,  opts = { desc = "Prev Warning" } },
})
-- stylua: ignore end
