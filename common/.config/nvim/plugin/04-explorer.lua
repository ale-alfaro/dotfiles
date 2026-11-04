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
local minifiles_toggle = function()
    if not MiniFiles.close() then
        MiniFiles.open(
            vim.api.nvim_buf_get_name(
                0
            ),
            false
        )
    end
end

local oil_setup = function()
end
---@class ExplorerPlugin
---@field setup         fun()
---@field open_curr_buf fun() | string
---@field open_at_loc   fun(loc: string)
---@field quickfix?     fun()
---@field loc_list?     fun()
VimRc.now_if_args(function()
    local minifiles = require(
        'mini.files'
    )
    ---
    ---
    vim.api.nvim_set_hl(
        0,
        'MiniFilesSymLink',
        { link = 'PmenuExtra' }
    )

    minifiles.setup {
        windows = {
            -- Whether to show preview of file/directory under cursor
            preview = true,
            -- Width of focused window
            width_focus = 80,
            -- Width of non-focused window
            width_nofocus = 15,
            --
        -- Width of preview window
            width_preview = 25,
        },
        options = {
            permanent_delete = false,
            use_as_default_explorer = false,
        },
        content = {
            prefix = function(fs_entry)
                -- Prefer 'mini.icons'
                local filetype = vim.fn.getftype(
                    fs_entry.path
                )
                if filetype == 'link' then
                    return require('custom.icons').os.Interface .. ' ', 'MiniFilesSymLink'
                else
                    local category = fs_entry.fs_type == 'directory' and 'directory' or 'file'
                    if category == 'directory' then
                        return require('custom.icons').os.Folder .. ' ', 'MiniFilesDirectory'
                    else
                        if MiniIcons ~= nil then
                            local icon, hl = MiniIcons.get(
                                category,
                                fs_entry.path
                            )
                            return icon .. ' ', hl
                        else
                            -- Try falling back to 'nvim-web-devicons'
                            return ' ', 'MiniFilesFile'
                        end
                    end
                end
            end,
        },
        mappings = {
            close = 'q',
            go_in = '<CR>',
            go_in_plus = '<Right>',
            go_out = '<BS>',
            go_out_plus = '<Left>',
            mark_goto = '<localleader>g',
            mark_set = '<localleader>m',
        },
    }
    ---@param evt  string | string[]
    ---@param cb   function
    ---@param desc string?
    local minifiles_autocmd = function(evt, cb, desc, other)
        vim.api.nvim_create_autocmd(
            'User',
            { pattern = 'MiniFiles' .. evt, callback = cb, desc = 'MiniFiles ' .. desc }
        )
    end

    minifiles_autocmd('BufferCreate', function(args)
        vim.b.minisurround_disable = false
        vim.b.minioperators_disable = false
        local b = args.data.buf_id
        vim.keymap.set('n', '<C-g>', function()
            -- works only if cursor is on the valid file system entry
            local cur_entry_path = (MiniFiles.get_fs_entry() or {}).path
            local prefills = {
                paths = vim.fs.dirname(
                    cur_entry_path
                ),
            }

            local grug_far = require 'grug-far'
            if not grug_far then
                return
            end
            -- instance check
            if not grug_far.has_instance 'explorer' then
                grug_far.open {
                    instanceName = 'explorer',
                    prefills = prefills,
                    staticTitle = 'Find and Replace from Explorer',
                }
            else
                grug_far.get_instance(
                    'explorer'
                ) --[[@cast -?]]
                    :open()
                -- updating the prefills without crealing the search and other fields
                grug_far.get_instance(
                    'explorer'
                ) --[[@cast -?]]
                    :update_input_values(
                        prefills,
                        false
                    )
            end
        end, { buf = b, desc = 'Search' }
        )
        vim.keymap.set(
            'n',
            'q',
            '<Cmd>lua MiniFiles.close()<CR>',
            { buf = b, desc = 'close' }
        )
        vim.keymap.set(
            'n',
            'gy',
            '<Cmd>lua vim.fn.setreg(vim.v.register, (MiniFiles.get_fs_entry() or {path = vim.fn.getcwd()}).path)<CR>',
            { buf = b, desc = 'Yank Path' }
        )
        vim.keymap.set(
            'n',
            'gx',
            '<Cmd>lua vim.ui.open(MiniFiles.get_fs_entry().path)<cr>',
            { buf = b, desc = 'OS open' }
        )
        MiniClue.ensure_buf_triggers(
            b
        )
    end, 'Mappings'
    )

    minifiles_autocmd('ActionRename', function(event)
        local from = event.data.from
        local to = event.data.to
        local changes = {
            files = {
                {
                    oldUri = vim.uri_from_fname(
                        from
                    ),
                    newUri = vim.uri_from_fname(
                        to
                    ),
                },
            },
        }

        local clients = vim.lsp.get_clients()
        for _, client in ipairs(
            clients
        ) do
            if client:supports_method 'workspace/willRenameFiles' then
                local resp = client:request_sync(
                    'workspace/willRenameFiles',
                    changes,
                    1000,
                    0
                )
                if resp and resp.result ~= nil then
                    vim.lsp.util.apply_workspace_edit(
                        resp.result,
                        client.offset_encoding
                    )
                end
            end
        end
        for _, client in ipairs(
            clients
        ) do
            if client:supports_method 'workspace/didRenameFiles' then
                client:notify(
                    'workspace/didRenameFiles',
                    changes
                )
            end
        end
    end, 'Rename Files'
    )

    local oil = require 'oil'
    oil.setup {
        -- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
    -- Set to false if you want some other plugin (e.g. netrw) to open when you edit directories.
        default_file_explorer = true,
        -- Id is automatically added at the beginning, and name at the end
    -- See :help oil-columns
        columns = {
            'icon',
            'permissions',
            'size',
            'mtime',
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
        constrain_cursor = 'name',
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
            ['<localleader>o'] = 'actions.open_external',
            ['<localleader>t'] = 'actions.open_terminal',

            -- create a new mapping, gs, to search and replace in the current directory
            ['<localleader>s'] = {
                callback = function()
                    -- get the current directory
                    local prefills = { paths = oil.get_current_dir() }

                    local grug_far = require 'grug-far'
                    -- instance check
                    if not grug_far.has_instance 'explorer' then
                        grug_far.open {
                            instanceName = 'explorer',
                            prefills = prefills,
                            staticTitle = 'Find and Replace from Explorer',
                        }
                    else
                        grug_far.get_instance('explorer'):open()
                        -- updating the prefills without clearing the search and other fields
                        grug_far.get_instance('explorer'):update_input_values(prefills, false)
                    end
                end,
                mode = 'n',
                desc = 'oil: Search in directory',
            },
            ['<Right>'] = { 'actions.select', mode = 'n' },
            ['<localleader>q'] = { 'actions.close', mode = 'n' },
            ['<Left>'] = { 'actions.parent', mode = 'n' },
            -- You can pass additional opts to vim.keymap.set by using
        -- a table with the mapping as the first element.
            ["<localleader>f"] = {
                function()
                    FzfLua.files({
                        cwd = require("oil").get_current_dir(),
                        ignore_current_file = true,
                    })
                end,
                mode = "n",
                nowait = true,
                desc = "Find files in the current directory",
            },
            -- Mappings that are a string starting with "actions." will be
        -- one of the built-in actions, documented below.
            ["`"] = "actions.tcd",
            -- Some actions have parameters. These are passed in via the `opts` key.
            ["<leader>:"] = {
                "actions.open_cmdline",
                opts = {
                    shorten_path = true,
                    modify = ":h",
                },
                desc = "Open the command line with the current directory as an argument",
            },
        },
        -- Set to false to disable all of the above keymaps
        view_options = {
            -- Show files and directories that start with "."
            show_hidden = true,
            -- This function defines what will never be shown, even when `show_hidden` is set
        },
        keymaps_help = {
            border = 'rounded',
        },
    }
    -- stylua:ignore
    local keys = {
        { '\\', minifiles_toggle, 'Open MiniFiles' }, { '<leader>eo', function() require('oil').open() end, "Open Oil" },
    }
    for _, k in ipairs(
        keys
    ) do
        vim.keymap.set(
            'n',
            k[1],
            k[2],
            { desc = k[3] }
        )
    end
end)
