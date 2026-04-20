local new_autocmd = function(evt, cb, desc)
  vim.api.nvim_create_autocmd(evt, { callback = cb, desc = desc })
end

local new_file_autocmd = function(pattern, cb, desc)
  vim.api.nvim_create_autocmd('FileType', { pattern = pattern, callback = cb, desc = desc })
end
new_autocmd('TextYankPost', function()
  (vim.hl or vim.highlight).on_yank()
end, 'Highlight on yank')
local q_close_ft = {
  'help',
  'man',
  'lspinfo',
  'checkhealth', -- qf handled by ftplugin/qf.lua
  'notify',
  'git',
  'grug-far',
  'qf',
  'scratch',
  'vimrc',
  'minigit',
  'ministarter',
  'Overseer*',
}

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('q_close', { clear = true }),
  pattern = q_close_ft,
  callback = function(ev)
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buf = ev.buf, silent = true, nowait = true })
  end,
})

-- ──────────────────────────────────────────────────────────────
--  Auto-reload buffers when focus returns
-- ──────────────────────────────────────────────────────────────

vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'FileChangedShell' }, {
  group = vim.api.nvim_create_augroup('autoread', { clear = true }),
  pattern = '*',
  callback = function()
    vim.cmd 'checktime'
  end,
})

-- ──────────────────────────────────────────────────────────────
--  Terminal window tweaks
-- ──────────────────────────────────────────────────────────────

vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('term', { clear = true }),
  callback = function()
    local o = vim.opt_local
    o.number = false
    o.relativenumber = false
    o.scrolloff = 0
  end,
})

-- <Esc><Esc> exits terminal mode (one Esc is sent to the program)
vim.keymap.set('t', '<esc><esc>', '<c-\\><c-n>')

-- Open a small terminal at the bottom of the screen
vim.keymap.set('n', '<c-w>t', function()
  vim.cmd.new()
  vim.cmd.wincmd 'J'
  vim.api.nvim_win_set_height(0, 12)
  vim.wo.winfixheight = true
  vim.cmd.term()
end, { desc = 'open terminal' })

-- ──────────────────────────────────────────────────────────────
--  Spelling for prose filetypes (enable spell + <C-l> quick-fix)
-- ──────────────────────────────────────────────────────────────

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'tex', 'markdown', 'norg', 'text', 'gitcommit' },
  callback = function(ev)
    vim.opt_local.spell = true
    vim.opt_local.wrap = true
    vim.keymap.set('i', '<c-l>', '<c-g>u<Esc>[s1z=`]a<c-g>u', { buffer = ev.buf, silent = true, desc = 'fix spelling' })
  end,
})

if FeatureFlags:get 'exrc' then
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = vim.api.nvim_create_augroup('exrc', { clear = true }),
    desc = 'Trust exrc files after write',
    pattern = '.nvim.lua', -- '.nvim.lua'
    callback = function()
      local ok, err = vim.secure.trust {
        action = 'allow',
        bufnr = vim.api.nvim_get_current_buf(),
      }
      if not ok then
        VimRc.error('Could not trust exrc file: %s', err)
      end
    end,
  })

  --     vim.api.nvim_create_autocmd('DirChanged', {
  --         group = group,
  --         desc = 'Load exrc files when changing directory',
  --         callback = function()
  --             require('exrc.loader').on_dir_changed()
  --         end,
  --     })
  --
  --
  -- function M.on_dir_changed()
  --     local event = vim.api.nvim_get_vvar('event')
  --     local cwd = vim.fn.fnamemodify(event.cwd, ':p')
  --     if (event.scope == 'global' or event.scope == 'tabpage') and not event.changed_window then
  --         if config.on_dir_changed.use_ui_select then
  --             coroutine.wrap(M.load_from_dirs) { cwd }
  --         else
  --             local path = utils.joinpath(cwd, config.exrc_name)
  --             if vim.fn.filereadable(path) == 1 then
  --                 M.load(path)
  --             end
  --         end
  --     end
  -- end
end
