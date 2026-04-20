local oil_setup = function()
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

      ['p'] = {
        'actions.paste_from_system_clipboard',
        opts = {
          delete_original = true,
        },
        desc = 'Paste and delete',
      },
      ['<Right>'] = { 'actions.select', mode = 'n' },
      ['q'] = { 'actions.close', mode = 'n' },
      ['gr'] = 'actions.refresh',
      ['<Left>'] = { 'actions.parent', mode = 'n' },
      ['gw'] = { 'actions.open_cwd', mode = 'n' },
      ['g~'] = { 'actions.cd', opts = { scope = 'tab' }, mode = 'n' },
      ['gs'] = { 'actions.change_sort', mode = 'n' },
      ['gX'] = 'actions.open_external',
      ['gt'] = 'actions.open_terminal',
      ['y'] = 'actions.yank_entry',

      -- Mappings can be a function
      ['gd'] = {
        function()
          require('oil').set_columns { 'icon', 'permissions', 'size', 'mtime' }
        end,
        desc = 'Show more info',
      },
    },
    -- Set to false to disable all of the above keymaps
    use_default_keymaps = false,
    view_options = {
      -- Show files and directories that start with "."
      show_hidden = true,
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
    keymaps_help = {
      border = 'rounded',
    },
  }
end

---@param dir? string
local oil_open_loc = function(dir)
  require('oil').open(dir, {
    preview = { vertical = true, horizontal = false, split = 'aboveleft' },
  }, function()
    MiniClue.disable_buf_triggers(0)
  end)
end

---@return ExplorerPlugin
return {
  setup = oil_setup,
  open_curr_buf = function()
    oil_open_loc(nil)
  end,
  open_at_loc = oil_open_loc,
}
