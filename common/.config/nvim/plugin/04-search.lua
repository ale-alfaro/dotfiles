---@param selected string[]
---@param opts fzf-lua.config.Zoxide|{}
local zoxide_open = function(selected, opts)
  if not selected[1] then
    return
  end
  local cwd = selected[1]:match '[^\t]+$' or selected[1]
  if opts.cwd then
    cwd = vim.fs.joinpath(opts.cwd, cwd)
  end
  if vim.uv.fs_stat(cwd) then
    vim.cmd('Oil ' .. cwd)
    vim.system { 'zoxide', 'add', '--', cwd }
    VimRc.info(("cwd set to '%s'"):format(cwd))
  else
    VimRc.warn(("Unable to set cwd to '%s', directory is not accessible"):format(cwd))
  end
end

if not vim.o.diff then
  VimRc.later(function()
    ---@module 'fzf-lua'
    ---@param selected string[]
    ---@param opts fzf-lua.config.CommandHistory|{}
    local hist_copy = function(selected, opts)
      local iter = opts.reverse_list and vim.iter(selected) or vim.iter(selected):rev()
      iter:each(function(e)
        local idx = assert(FzfLua.utils.tointeger(opts.reverse_list and e or -e - 1))
        local sel = vim.fn.histget(':', idx) -- get before deleted
        vim.fn.setreg('+', sel)
        VimRc.info(string.format('Copied: %s', sel))
      end)
    end
    require('fzf-lua').setup {
      ---@type fzf-lua.profile[]
      { 'fzf-native', 'border-fused', 'hide' },
      keymap = {
        fzf = { true, ['ctrl-q'] = 'select-all+accept' },
      },
      ui_select = true,
      -- Configuration for specific commands.
      files = {
        winopts = {
          preview = { hidden = true },
        },
        --- NOTE: the directory must exist, so if you're using a custom folder make sure the directory exists using mkdir -p.
        fzf_opts = {
          ['--history'] = vim.fs.joinpath(vim.fn.stdpath 'data', 'fzf-lua', 'files-history'),
        },
        no_ignore = false, -- enable hidden files by default
      },
      grep = {
        -- Search in hidden files by default.
        hidden = true,
        --- NOTE: the directory must exist, so if you're using a custom folder make sure the directory exists using mkdir -p.
        fzf_opts = {
          ['--history'] = vim.fs.joinpath(vim.fn.stdpath 'data', 'fzf-lua', 'grep-history'),
        },
      },
      helptags = {
        actions = {
          -- Open help pages in a vertical split.
          ['enter'] = FzfLua.actions.help_vert,
        },
      },
      manpages = {
        actions = {
          -- Open help pages in a vertical split.
          ['enter'] = FzfLua.actions.help_vert,
        },
      },
      oldfiles = {
        include_current_session = true,
        winopts = {
          preview = { hidden = true },
        },
      },
      search_history = {

        actions = {
          ['ctrl-c'] = { fn = hist_copy, field_index = '{+n}', reload = true },
        },
      },
      zoxide = {
        actions = {
          enter = zoxide_open,
        },
      },
    }
    local nonprefix_keys = {
      { '<Space><Space>', '<cmd>FzfLua builtin<cr>', 'Find Fzf pickers' },
      { '<C-b>', '<cmd>FzfLua buffers<cr>', 'Buffers' },
      { '<C-f>', '<cmd>FzfLua files<cr>', 'Files' },
      { '<C-g>', '<cmd>FzfLua live_grep<cr>', 'Grep (cwd)' },
      { '<C-e>', '<cmd>FzfLua global<cr>', 'Global' },
      { '<C-/>', '<cmd>FzfLua blines<cr>', 'Buffer Lines' },
      { '<C-c>', '<cmd>FzfLua resume<cr>', 'Continue' },
    }
    local westgrep = function()
      local fzf = require 'fzf-lua'
      fzf.live_grep { cmd = 'west grep' }
    end
    for _, k in ipairs(nonprefix_keys) do
      vim.keymap.set('n', k[1], k[2], { desc = k[3], noremap = true })
    end
    local prefix_keys = {
      { 'o', '<cmd>FzfLua oldfiles<cr>', 'Old Files' },
      { 'm', '<cmd>FzfLua manpages<cr>', 'Find Man' },
      { 'h', '<cmd>FzfLua help_tags<cr>', 'Help' },
      { 'k', '<Cmd>FzfLua keymaps<CR>', 'Keymaps' },
      { 'z', '<cmd>FzfLua zoxide<cr>', 'Zoxide' },
      { 'H', '<cmd>FzfLua command_history<cr>', 'History' },
      {
        's',
        '<cmd>FzfLua lsp_document_symbols<cr>',
        'Live Document Symbols',
      },
      { 'd', '<cmd>FzfLua lsp_document_diagnostics<cr>', 'Document diagnostics' },
    }

    for _, k in ipairs(prefix_keys) do
      vim.keymap.set('n', '<leader>f' .. k[1], k[2], { desc = k[3] })
    end
  end)

  VimRc.later(function()
    require 'extras.grug'
  end)
end
