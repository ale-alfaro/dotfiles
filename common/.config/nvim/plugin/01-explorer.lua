-- Step one or two ============================================================
-- Load now if Neovim is started like `nvim -- path/to/file`, otherwise - later.
-- This ensures a correct behavior for files opened during startup.

-- Completion and signature help. Implements async "two stage" autocompletion:
-- - Based on attached LSP servers that support completion.
-- - Fallback (based on built-in keyword completion) if there is no LSP candidates.
--
-- Example usage in Insert mode with attached LSP:
-- - Start typing text that should be recognized by LSP (like variable name).
-- - After 100ms a popup menu with candidates appears.
-- - Press `<Tab>` / `<S-Tab>` to navigate down/up the list. These are set up
--   in 'mini.keymap'. You can also use `<C-n>` / `<C-p>`.
-- - During navigation there is an info window to the right showing extra info
--   that the LSP server can provide about the candidate. It appears after the
--   candidate stays selected for 100ms. Use `<C-f>` / `<C-b>` to scroll it.
-- - Navigating to an entry also changes buffer text. If you are happy with it,
--   keep typing after it. To discard completion completely, press `<C-e>`.
-- - After pressing special trigger(s), usually `(`, a window appears that shows
--   the signature of the current function/method. It gets updated as you type
--   showing the currently active parameter.
--
-- Example usage in Insert mode without an attached LSP or in places not
-- supported by the LSP (like comments):
-- - Start typing a word that is present in current or opened buffers.
-- - After 100ms popup menu with candidates appears.
-- - Navigate with `<Tab>` / `<S-Tab>` or `<C-n>` / `<C-p>`. This also updates
--   buffer text. If happy with choice, keep typing. Stop with `<C-e>`.
--
-- It also works with snippet candidates provided by LSP server. Best experience
-- when paired with 'mini.snippets' (which is set up in this file).

---@module 'oil'

local now_if_args = VimRc.now_if_args

now_if_args(function()
  require('oil').setup {
    -- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
    -- Set to false if you want some other plugin (e.g. netrw) to open when you edit directories.
    default_file_explorer = true,
    -- Id is automatically added at the beginning, and name at the end
    -- See :help oil-columns
    columns = {
      'icon',
      'permissions',
    },
    -- Buffer-local options to use for oil buffers
    buf_options = {
      buflisted = false,
      bufhidden = 'hide',
    },
    -- Window-local options to use for oil buffers
    win_options = {
      wrap = false,
      signcolumn = 'no',
      cursorcolumn = false,
      foldcolumn = '0',
      spell = false,
      list = false,
      conceallevel = 3,
      concealcursor = 'nvic',
    },
    -- Send deleted files to the trash instead of permanently deleting them (:help oil-trash)
    delete_to_trash = true,
    -- Skip the confirmation popup for simple operations (:help oil.skip_confirm_for_simple_edits)
    skip_confirm_for_simple_edits = true,
    -- Selecting a new/moved/renamed file or directory will prompt you to save changes first
    -- (:help prompt_save_on_select_new_entry)
    prompt_save_on_select_new_entry = true,
    -- Oil will automatically delete hidden buffers after this delay
    -- You can set the delay to false to disable cleanup entirely
    -- Note that the cleanup process only starts when none of the oil buffers are currently displayed
    cleanup_delay_ms = 2000,
    lsp_file_methods = {
      -- Enable or disable LSP file operations
      enabled = true,
      -- Time to wait for LSP file operations to complete before skipping
      timeout_ms = 1000,
      -- Set to true to autosave buffers that are updated with LSP willRenameFiles
      -- Set to "unmodified" to only save unmodified buffers
      autosave_changes = true,
    },
    -- Constrain the cursor to the editable parts of the oil buffer
    -- Set to `false` to disable, or "name" to keep it on the file names
    constrain_cursor = 'editable',
    -- Set to true to watch the filesystem for changes and reload oil
    watch_for_changes = true,
    -- Keymaps in oil buffer. Can be any value that `vim.keymap.set` accepts OR a table of keymap
    -- options with a `callback` (e.g. { callback = function() ... end, desc = "", mode = "n" })
    -- Additionally, if it is a string that matches "actions.<name>",
    -- it will use the mapping at require("oil.actions").<name>
    -- Set to `false` to remove a keymap
    -- See :help oil-actions for a list of all available actions
    keymaps = {
      ['g?'] = { 'actions.show_help', mode = 'n' },
      ['<CR>'] = 'actions.select',

      ['gp'] = {
        'actions.paste_from_system_clipboard',
        opts = {
          delete_original = true,
        },
        desc = 'Paste and delete',
      },
      ['<Right>'] = { 'actions.select', mode = 'n' },
      ['gv'] = { 'actions.select', opts = { vertical = true } },
      ['q'] = { 'actions.close', mode = 'n' },
      ['gr'] = 'actions.refresh',
      ['<Left>'] = { 'actions.parent', mode = 'n' },
      ['gw'] = { 'actions.open_cwd', mode = 'n' },
      ['g~'] = { 'actions.cd', opts = { scope = 'tab' }, mode = 'n' },
      ['gs'] = { 'actions.change_sort', mode = 'n' },
      ['gx'] = 'actions.open_external',
      ['gt'] = 'actions.open_terminal',
      ['g.'] = { 'actions.toggle_hidden', mode = 'n' },
      ['g\\'] = { 'actions.toggle_trash', mode = 'n' },
      ['gy'] = 'actions.yank_entry',
      ['<C-q>'] = 'actions.send_to_qflist',

      -- Mappings can be a function
      ['gd'] = {
        function()
          require('oil').set_columns { 'icon', 'permissions', 'size', 'mtime' }
        end,
        desc = 'Show more info',
      },
      -- You can pass additional opts to vim.keymap.set by using
      -- a table with the mapping as the first element.
      ['<leader>ff'] = {
        function()
          require('fzf-lua').files {
            cwd = require('oil').get_current_dir(),
          }
        end,
        mode = 'n',
        nowait = true,
        desc = 'Find files in the current directory',
      },
      -- Mappings that are a string starting with "actions." will be
      -- one of the built-in actions, documented below.
      ['`'] = 'actions.tcd',
      -- Some actions have parameters. These are passed in via the `opts` key.
      ['<leader>:'] = {
        'actions.open_cmdline',
        opts = {
          shorten_path = true,
          modify = ':h',
        },
        desc = 'Open the command line with the current directory as an argument',
      },
    },
    -- Set to false to disable all of the above keymaps
    use_default_keymaps = false,
    view_options = {
      -- Show files and directories that start with "."
      show_hidden = true,
      -- This function defines what is considered a "hidden" file
      is_hidden_file = function(name, bufnr)
        local m = name:match '^%.'
        return m ~= nil
      end,
      -- This function defines what will never be shown, even when `show_hidden` is set
      is_always_hidden = function(name, bufnr)
        return false
      end,
      -- Sort file names with numbers in a more intuitive order for humans.
      -- Can be "fast", true, or false. "fast" will turn it off for large directories.
      natural_order = 'fast',
      -- Sort file and directory names case insensitive
      case_insensitive = true,
      sort = {
        -- sort order can be "asc" or "desc"
        -- see :help oil-columns to see which columns are sortable
        { 'type', 'asc' },
        { 'name', 'asc' },
      },
      -- Customize the highlight group for the file name
      -- highlight_filename = function(entry, is_hidden, is_link_target, is_link_orphan)
      --   return is_link_orphan or is_link_target
      -- end,
    },
    -- EXPERIMENTAL support for performing file operations with git
    -- git = {
    --   -- Return true to automatically git add/mv/rm files
    --   add = function(path)
    --     return false
    --   end,
    --   mv = function(src_path, dest_path)
    --     return false
    --   end,
    --   rm = function(path)
    --     return false
    --   end,
    -- },
    -- Configuration for the floating keymaps help window
    keymaps_help = {
      border = 'rounded',
    },
  }
  ---@type table<string,oil.OpenPreviewOpts>
  local oil_preview_opts = {
    ['vsplit'] = {
      preview = { vertical = true, horizontal = false, split = 'aboveleft' },
    },
    ['hsplit'] = {
      preview = { vertical = false, horizontal = true, split = 'botleft' },
    },
  }

  ---Open oil browser for a directory
  ---@param dir string?
  ---@param preview? "hsplit"|"vsplit"
  local function create_oil_open_fn(dir, preview)
    local opts = nil
    if preview and oil_preview_opts[preview] then
      opts = oil_preview_opts[preview]
    end
    return function()
      require('oil').open(dir, opts, function()
        MiniClue.disable_buf_triggers(0)
      end)
    end
  end
  local oil_open_current_buf = create_oil_open_fn(nil, 'vsplit')

  ---@comment create a oil open function
  ---@param loc string
  ---@return function
  local oil_open_loc = function(loc)
    if type(loc) == 'string' and vim.uv.fs_stat(loc) then
      return create_oil_open_fn(loc)
    else
      VimRc.err 'Location is not a valid path. Creating open cwd function'
      return function()
        VimRc.warn 'Location was not a valid path. Check your config!'
        create_oil_open_fn(vim.fn.getcwd())
      end
    end
  end
  -- stylua:ignore
  local wkey_prefix = '<leader>e'
  KEYS.define({
    {
      mode = { 'n', 'v', 'x' },
      lhs = wkey_prefix .. 'v',
      rhs = oil_open_loc(vim.fn.expand '$MYVIMRC'),
      opts = { desc = 'Edit $MYVIMRC' },
    },
    {
      mode = { 'n', 'v', 'x' },
      lhs = wkey_prefix .. 'z',
      rhs = oil_open_loc(vim.fn.getenv 'ZDOTDIR'),
      opts = { desc = 'Edit .zshrc' },
    },
    {
      mode = { 'n', 'v', 'x' },
      lhs = wkey_prefix .. 'o',
      rhs = oil_open_loc(vim.fn.getenv 'OBSIDIAN_HOME'),
      opts = { desc = 'Edit Obsidian' },
    },
    {
      mode = { 'n', 'v', 'x' },
      lhs = wkey_prefix .. '.',
      rhs = oil_open_loc(vim.fs.joinpath(vim.fn.getenv 'HOME', 'dotfiles')),
      opts = { desc = 'Edit Dotfiles' },
    },
    {
      mode = { 'n', 'v', 'x' },
      lhs = wkey_prefix .. 'm',
      rhs = oil_open_loc(vim.fs.joinpath(vim.fn.getenv 'XDG_CONFIG_HOME', 'mise')),
      opts = { desc = 'Edit Direnv config' },
    },
    -- {
    --   mode = { 'n', 'v', 'x' },
    --   lhs = wkey_prefix .. 'c',
    --   rhs = oil_open_loc(vim.fn.getenv 'XDG_CONFIG_HOME'),
    --   opts = { desc = 'Edit Config Home' },
    -- },
    {
      mode = { 'n', 'v', 'x' },
      lhs = wkey_prefix .. 'w',
      rhs = oil_open_loc(vim.fs.joinpath(vim.fn.getenv 'HOME', 'sibel', 'eng')),
      opts = { desc = 'Explore Sibel Work Dirs' },
    },
    { lhs = '<leader><leader>', rhs = '<Cmd>Oil<CR>', opts = { desc = 'File Explorer (cwd)' } },
    {
      lhs = '\\',
      rhs = oil_open_current_buf,
      opts = { desc = 'Open file explorer shortcut' },
    },
  }, { group = 'Explore/Edit', prefix = wkey_prefix })
end)
