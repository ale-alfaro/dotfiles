-- ┌─────────────────┐
-- │ Custom mappings │
-- └─────────────────┘
_G.Utils.keymaps.define({
  -- General & Navigation
  { lhs = "<leader>bb", rhs = "<cmd>e #<cr>", opts = { desc = "Switch to Other Buffer" } },
  { lhs = "<leader>`", rhs = "<cmd>e #<cr>", opts = { desc = "Switch to Other Buffer" } },
  { lhs = "q", rhs = "<nop>", opts = { noremap = true } },
  { lhs = "Q", rhs = "q", opts = { noremap = true } },
  { lhs = "<M-q>", rhs = "Q", opts = { desc = "Replay last register", noremap = true } },
 
  -- { lhs = "<C-j>", rhs = "<C-w>j", opts = { desc = "Go to Lower Window", remap = true } },
  -- { lhs = "<C-k>", rhs = "<C-w>k", opts = { desc = "Go to Upper Window", remap = true } },
  -- { lhs = "<C-l>", rhs = "<C-w>l", opts = { desc = "Go to Right Window", remap = true } },
  { mode = {"n"}, lhs = "<C-q>", rhs = ":copen<CR>", opts = { silent = true } },
  { mode = {"n"}, lhs = "<leader>u", rhs = "<Cmd>update<CR>", opts = { desc = "Write the current buffer." } },
  { mode = {"n"}, lhs = "<leader>q", rhs = "<Cmd>:quit<CR>", opts = { desc = "Quit the current buffer." } },
  { mode = {"n"}, lhs = "<leader>Q", rhs = "<Cmd>:wqa<CR>", opts = { desc = "Quit all buffers and write." } },
  { mode = {"n"}, lhs = "<C-f>", rhs = "<Cmd>Open .<CR>", opts = { desc = "Open current directory in Finder." } },
  { lhs = '[p', rhs = '<Cmd>exe "put! " . v:register<CR>', opts = { desc = 'Paste Above' } },
  { lhs = ']p', rhs = '<Cmd>exe "put "  . v:register<CR>', opts = { desc = 'Paste Below' } },
  {mode =  {'n', 'v', 'x' }, lhs = '<leader>O', rhs = '<Cmd>restart<CR>', opts = { desc = 'Restart vim.' }},
  {mode = {'n'}, lhs = '<leader>ed', rhs = '<Cmd>lua MiniFiles.open()<CR>',   opts = { desc = 'Directory'}},
  {mode = {'n'}, lhs = '<leader>eq', rhs = function()
      for _, win_id in ipairs(vim.api.nvim_tabpage_list_wins(0)) do 
        if vim.fn.getwininfo(win_id)[1].quickfix == 1 then 
          return vim.cmd('cclose') 
        end 
      end
      vim.cmd('copen')
    end, opts = { desc = 'Quickfix'}},
  {mode = {'n'}, lhs = '<leader>n', rhs = '<Cmd>lua MiniNotify.show_history()<CR>',   opts = { desc = 'Notification History'}},
  { lhs = '\\', rhs = '<Cmd>lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>', opts = { desc = 'Open file explorer quick'}},

  -- File & Config Editing
  { mode = { "n", "v", "x" }, lhs = "<leader>ev", rhs = "<Cmd>edit $MYVIMRC<CR>", opts = { desc = "Edit " .. vim.fn.expand("$MYVIMRC") } },
  { mode = { "n", "v", "x" }, lhs = "<leader>ez", rhs = "<Cmd>e $ZDOTDIR<CR>", opts = { desc = "Edit .zshrc" } },
  { mode = { "n", "v", "x" }, lhs = "<leader>eh", rhs = "<Cmd>e $XDG_CONFIG_HOME/hypr/hyprland<CR>", opts = { desc = "Edit Hyprland Config" } },
  { mode = { "n", "v", "x" }, lhs = "<leader>so", rhs = "<Cmd>source %<CR>", opts = { desc = "Source " .. vim.fn.expand("$MYVIMRC") } },

  -- Buffers
  { lhs = "<S-h>", rhs = "<cmd>bprevious<cr>", opts = { desc = "Prev Buffer" } },
  { lhs = "<S-l>", rhs = "<cmd>bnext<cr>", opts = { desc = "Next Buffer" } },
  { lhs = "[b", rhs = "<cmd>bprevious<cr>", opts = { desc = "Prev Buffer" } },
  { lhs = "]b", rhs = "<cmd>bnext<cr>", opts = { desc = "Next Buffer" } },
  { lhs = '<leader>ba', rhs = '<Cmd>b#<CR>', opts = { desc = 'Alternate' } },
  { lhs = '<leader>bd', rhs = '<Cmd>lua MiniBufremove.delete()<CR>', opts = { desc = 'Delete' } },
  { lhs = '<leader>bD', rhs = '<Cmd>lua MiniBufremove.delete(0, true)<CR>', opts = { desc = 'Delete!' } },
  { lhs = '<leader>bs', rhs = function() vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(true, true)) end, opts = { desc = 'Scratch' } },
  { lhs = '<leader>bw', rhs = '<Cmd>lua MiniBufremove.wipeout()<CR>', opts = { desc = 'Wipeout' } },
  { lhs = '<leader>bW', rhs = '<Cmd>lua MiniBufremove.wipeout(0, true)<CR>', opts = { desc = 'Wipeout!' } },

  -- Clipboard & Text Manipulation
  { mode = { "n", "x" }, lhs = "<leader>y", rhs = '"+y' },
  { mode = { "n", "x" }, lhs = "<leader>d", rhs = '"+d' },
  { mode = { "v", "x", "n" }, lhs = "<C-y>", rhs = '"+y', opts = { desc = "System clipboard yank." } },
  { mode = { "n", "v", "x" }, lhs = "<leader>no", rhs = ":norm ", opts = { desc = "ENTER NORM COMMAND." } },
  { lhs = "<leader>ur", rhs = "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>", opts = { desc = "Redraw / Clear hlsearch / Diff Update" } },

  -- Search
  { lhs = "n", rhs = "'Nn'[v:searchforward].'zv'", opts = { expr = true, desc = "Next Search Result" } },
  { mode = "x", lhs = "n", rhs = "'Nn'[v:searchforward]", opts = { expr = true, desc = "Next Search Result" } },
  { mode = "o", lhs = "n", rhs = "'Nn'[v:searchforward]", opts = { expr = true, desc = "Next Search Result" } },
  { lhs = "N", rhs = "'nN'[v:searchforward].'zv'", opts = { expr = true, desc = "Prev Search Result" } },
  { mode = "x", lhs = "N", rhs = "'nN'[v:searchforward]", opts = { expr = true, desc = "Prev Search Result" } },
  { mode = "o", lhs = "N", rhs = "'nN'[v:searchforward]", opts = { expr = true, desc = "Prev Search Result" } },

  -- Insert Mode Enhancements
  { mode = "i", lhs = ",", rhs = ",<c-g>u" },
  { mode = "i", lhs = ".", rhs = ".<c-g>u" },
  { mode = "i", lhs = ";", rhs = ";<c-g>u" },

  -- Save
  { mode = { "i", "x", "n", "s" }, lhs = "<C-s>", rhs = "<cmd>w<cr><esc>", opts = { desc = "Save File" } },

  -- Visual Mode Enhancements
  { mode = "v", lhs = "<", rhs = "<gv" },
  { mode = "v", lhs = ">", rhs = ">gv" },

  -- Commenting
  { lhs = "gco", rhs = "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", opts = { desc = "Add Comment Below" } },
  { lhs = "gcO", rhs = "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", opts = { desc = "Add Comment Above" } },

  -- Quickfix & Location Lists
  { lhs = "<leader>xl", rhs = function()
      local success, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
      if not success and err then vim.notify(err, vim.log.levels.ERROR) end
    end, opts = { desc = "Location List" } },
  { lhs = "<leader>xq", rhs = function()
      local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
      if not success and err then vim.notify(err, vim.log.levels.ERROR) end
    end, opts = { desc = "Quickfix List" } },
  { lhs = "[q", rhs = vim.cmd.cprev, opts = { desc = "Previous Quickfix" } },
  { lhs = "]q", rhs = vim.cmd.cnext, opts = { desc = "Next Quickfix" } },

  -- Diagnostics
  { lhs = "<leader>cd", rhs = vim.diagnostic.open_float, opts = { desc = "Line Diagnostics" } },
  { lhs = "]d", rhs = function() vim.diagnostic.get_next() end, opts = { desc = "Next Diagnostic" } },
  { lhs = "[d", rhs = function() vim.diagnostic.get_prev() end, opts = { desc = "Prev Diagnostic" } },
  { lhs = '<leader>dp', rhs = '<Cmd>lua vim.diagnostic.open_float()<CR>', opts = { desc = 'Diagnostic popup' } },
  { lhs = "]e", rhs = function() vim.diagnostic.get_next({ severity = vim.diagnostic.severity.ERROR }) end, opts = { desc = "Next Error" } },
  { lhs = "[e", rhs = function() vim.diagnostic.get_prev({ severity = vim.diagnostic.severity.ERROR }) end, opts = { desc = "Prev Error" } },
  { lhs = "]w", rhs = function() vim.diagnostic.get_next({ severity = vim.diagnostic.severity.WARN }) end, opts = { desc = "Next Warning" } },
  { lhs = "[w", rhs = function() vim.diagnostic.get_prev({ severity = vim.diagnostic.severity.WARN }) end, opts = { desc = "Prev Warning" } },

  -- LSP
  { lhs = '<leader>ga', rhs = '<Cmd>lua vim.lsp.buf.code_action()<CR>', opts = { desc = 'Actions' } },
  { lhs = '<leader>gi', rhs = '<Cmd>lua vim.lsp.buf.implementation()<CR>', opts = { desc = 'Implementation' } },
  { lhs = '<leader>gh', rhs = '<Cmd>lua vim.lsp.buf.hover()<CR>', opts = { desc = 'Hover' } },
  { lhs = '<leader>gn', rhs = '<Cmd>lua vim.lsp.buf.rename()<CR>', opts = { desc = 'Rename' } },
  { lhs = '<leader>gr', rhs = '<Cmd>lua vim.lsp.buf.references()<CR>', opts = { desc = 'References' } },
  { lhs = '<leader>gd', rhs = '<Cmd>lua vim.lsp.buf.definition()<CR>', opts = { desc = 'Source definition' } },
  { lhs = '<leader>gt', rhs = '<Cmd>lua vim.lsp.buf.type_definition()<CR>', opts = { desc = 'Type definition' } },

  { mode = { "n", "v", "x" }, lhs = "<leader>lf", rhs = vim.lsp.buf.format, opts = { desc = "Format current buffer" } },
  -- { mode = { "n", "v", "x" }, lhs = '<leader>lf', rhs = '<Cmd>lua require("conform").format({lsp_fallback=true})<CR>', opts = { desc = 'Format selection' } },


  -- Smart Splits
  { lhs = '<A-h>', rhs = function() require('smart-splits').resize_left() end, opts = { desc = 'Resize left' } },
  { lhs = '<A-j>', rhs = function() require('smart-splits').resize_down() end, opts = { desc = 'Resize down' } },
  { lhs = '<A-k>', rhs = function() require('smart-splits').resize_up() end, opts = { desc = 'Resize up' } },
  { lhs = '<A-l>', rhs = function() require('smart-splits').resize_right() end, opts = { desc = 'Resize right' } },
  { lhs = '<C-h>', rhs = function() require('smart-splits').move_cursor_left() end, opts = { desc = 'Move window left' } },
  { lhs = '<C-j>', rhs = function() require('smart-splits').move_cursor_down() end, opts = { desc = 'Move window down' } },
  { lhs = '<C-k>', rhs = function() require('smart-splits').move_cursor_up() end, opts = { desc = 'Move window up' } },
  { lhs = '<C-l>', rhs = function() require('smart-splits').move_cursor_right() end, opts = { desc = 'Move window right' } },

  -- Linting
  { lhs = "<leader>li", rhs = "<cmd>Lint<cr>", opts = { desc = "Trigger linting for current file" } },
})
