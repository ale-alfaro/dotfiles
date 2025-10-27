MiniPick = require 'mini.pick'

MiniPick.setup {
  -- Delays (in ms; should be at least 1)
  delay = {
    -- Delay between forcing asynchronous behavior
    async = 10,

    -- Delay between computation start and visual feedback about it
    busy = 50,
  },

  -- Keys for performing actions. See `:h MiniPick-actions`.
  mappings = {
    caret_left = '<Left>',
    caret_right = '<Right>',

    choose = '<CR>',
    choose_in_split = '<C-s>',
    choose_in_tabpage = '<C-t>',
    choose_in_vsplit = '<C-v>',
    choose_marked = '<M-CR>',

    delete_char = '<BS>',
    delete_char_right = '<Del>',
    delete_left = '<C-u>',
    delete_word = '<C-w>',

    mark = '<C-x>',
    mark_all = '<C-a>',

    move_down = '<C-n>',
    move_start = '<C-g>',
    move_up = '<C-p>',

    paste = '<C-r>',

    refine = '<C-Space>',
    refine_marked = '<M-Space>',

    scroll_down = '<C-f>',
    scroll_left = '<C-h>',
    scroll_right = '<C-l>',
    scroll_up = '<C-b>',

    stop = '<Esc>',

    toggle_info = '<S-Tab>',
    toggle_preview = '<Tab>',
  },

  -- General options
  options = {
    -- Whether to show content from bottom to top
    content_from_bottom = false,

    -- Whether to cache matches (more speed and memory on repeated prompts)
    use_cache = false,
  },

  -- Source definition. See `:h MiniPick-source`.
  source = {
    items = nil,
    name = nil,
    cwd = nil,

    match = nil,
    show = nil,
    preview = nil,

    choose = nil,
    choose_marked = nil,
  },

  -- Window related options
  window = {
    -- Float window config (table or callable returning it)
    config = nil,

    -- String to use as caret in prompt
    prompt_caret = '▏',

    -- String to use as prefix in prompt
    prompt_prefix = '> ',
  },
}

local wipeout_cur = function()
  vim.api.nvim_buf_delete(MiniPick.get_picker_matches().current.bufnr, {})
end
local buffer_mappings = { wipeout = { char = '<C-d>', func = wipeout_cur } }
-- stylua: ignore
_G.keymaps_define {
  { lhs = '<leader><leader>', rhs = function() MiniPick.builtin.buffers({}, { mappings = buffer_mappings }) end, opts = { desc = 'Pick open buffers' } },
  { lhs = '<leader>sh',       rhs = '<Cmd>Pick history scope=":"<CR>',                                         opts = { desc = '[S]earch Command [H]istory' } },
  { lhs = '<leader>sg',       rhs = '<Cmd>Pick grep_live<CR>',                                                 opts = { desc = '[S]earch [G]rep' } },
  { lhs = '<leader>sw',       rhs = '<Cmd>Pick grep pattern="<cword>"<CR>',                                    opts = { desc = '[S]earch current [W]ord' } },
  { lhs = '<leader>sd',       rhs = '<Cmd>Pick diagnostic scope="current"<CR>',                                opts = { desc = '[S]earch [D]iagnostics (Buffer)' } },
  { lhs = '<leader>sD',       rhs = '<Cmd>Pick diagnostic scope="all"<CR>',                                    opts = { desc = '[S]earch [D]iagnostics (Workspace)' } },
  { lhs = '<leader>sr',       rhs = '<Cmd>Pick lsp scope="references"<CR>',                                    opts = { desc = 'References (LSP)' } },
  { lhs = '<leader>ss',       rhs = '<Cmd>Pick lsp scope="workspace_symbol"<CR>',                              opts = { desc = 'Symbols workspace' } },
  { lhs = '<leadersS',        rhs = '<Cmd>Pick lsp scope="document_symbol"<CR>',                               opts = { desc = 'Symbols document' } },
  { lhs = '<leader>so',       rhs = '<Cmd>Pick oldfiles<CR>',                                                  opts = { desc = '[S]earch [O]ld files' } },
  { lhs = '<leader>sk',       rhs = '<Cmd>Pick keymaps<CR>',                                                   opts = { desc = '[S]earch [K]eymaps' } },
}
