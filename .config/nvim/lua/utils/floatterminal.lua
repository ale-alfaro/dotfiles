local vim = vim
local state = {
  floating = {
    buf = -1,
    win = -1,
  },
}

local function create_floating_window(opts)
  opts = opts or {}

  local buf = nil
  if vim.api.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    buf = vim.api.nvim_create_buf(false, true)
  end

  local width = opts.width or math.floor(vim.o.columns * 0.8)
  local height = opts.height or math.floor(vim.o.lines * 0.8)
  local row = opts.row or math.floor((vim.o.lines - height) / 2)
  local col = opts.col or math.floor((vim.o.columns - width) / 2)
  local anchor = opts.anchor or 'NW'
  local style = opts.style or 'minimal'
  local win_config = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    border = 'rounded',
    anchor = anchor,
    style = style,
    title_pos = 'center',
    title = 'floatterm',
  })
  return { buf = buf, win = win_config }
end

local toggle_floatterm = function()
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    state.floating = create_floating_window { buf = state.floating.buf }
    if vim.bo[state.floating.buf].buftype ~= 'terminal' then
      vim.cmd.term()
    end
  else
    vim.api.nvim_win_hide(state.floating.win)
  end
end
vim.api.nvim_create_user_command('FloatTermOpen', toggle_floatterm, {})

vim.keymap.set({ 'n', 't' }, '<leader>ft', '<cmd>FloatTermOpen<CR>', { desc = 'Open terminal' })

vim.keymap.set('t', '<esc><esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Terminal autocommands
local vim_term = vim.api.nvim_create_augroup('vim_term', { clear = true })
vim.api.nvim_create_autocmd('TermOpen', {
  callback = function()
    -- disable line numbering in terminal mode
    vim.opt_local.relativenumber = false
    vim.opt_local.number = false
  end,
  group = vim_term,
})
-- start insert mode when moving to a terminal window
vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinEnter' }, {
  callback = function()
    if vim.bo.buftype == 'terminal' then
      vim.cmd 'startinsert'
    end
  end,
  group = vim_term,
})
-- prevents insert mode when the terminal process has exited
vim.api.nvim_create_autocmd('TermClose', {
  callback = function(ctx)
    vim.cmd 'stopinsert'
    vim.api.nvim_create_autocmd('TermEnter', {
      command = 'stopinsert',
      buffer = ctx.buf,
    })
  end,
  nested = true,
  group = vim_term,
})

vim.api.nvim_create_autocmd('TermLeave', {
  --desc = 'Close floating window when exiting terminal mode within a floating window',
  callback = function()
    vim.api.nvim_win_hide(state.floating.win)
  end,
  group = vim_term,
})
--
-- local job_id = 0
-- vim.keymap.set('n', '<leader>st', function()
--   vim.cmd.vnew()
--   vim.cmd.term()
--   vim.cmd.wincmd 'J'
--   vim.api.nvim_win_set_height(0, 15)
--
--   job_id = vim.bo.channel
-- end, { desc = 'Open terminal' })
--
-- vim.keymap.set('n', '<leader>zb', function()
--   vim.fn.chansend(job_id, { 'west build \r\n' })
-- end, { desc = 'Zephyr West Build' })
