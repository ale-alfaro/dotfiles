local augrp_fmt = vim.api.nvim_create_augroup('vimrc.fmt', { clear = false })
local augrp_cursor_hold = vim.api.nvim_create_augroup('vimrc.cursorhold', { clear = false })
---@description Function that handles LspAttach events.
---@param client vim.lsp.Client
---@param bufnr  integer
VimRc.lsp_on_attach = function(client, bufnr)
    local buf_usercmd = function(event, callback, desc)
        vim.api.nvim_buf_create_user_command(
            bufnr, event, callback,
            {
                desc = desc or '',
            }
        )
    end

    buf_usercmd('ToggleInlayHints', function()
        vim.g.inlay_hints = not vim.g.inlay_hints
        vim.notify(
            string.format('%s inlay hints...', vim.g.inlay_hints and 'Enabling' or 'Disabling'), vim.log.levels.INFO
        )

        local mode = vim.api.nvim_get_mode().mode
        vim.lsp.inlay_hint.enable(vim.g.inlay_hints and (mode == 'n' or mode == 'v'))
    end, 'Toggle inlay hints'
    )
    local cursor_autocmd = function(event, callback, desc)
        vim.api.nvim_create_autocmd(
            event,
            {
                group = augrp_cursor_hold,
                callback = callback,
                buffer = bufnr,
                desc = desc or '',
            }
        )
    end
    -- Enable auto-completion. Note: Use CTRL-Y to select an item. |complete_CTRL-Y|
    cursor_autocmd(
        { 'CursorHold', 'InsertLeave' }, vim.lsp.buf.document_highlight, 'Highlight references under the cursor'
    )
    cursor_autocmd(
        { 'CursorMoved', 'InsertEnter', 'BufLeave' }, vim.lsp.buf.clear_references, 'Clear highlight references'
    )

    cursor_autocmd('CursorHold', function()
        local hover_opts = {
            focusable = false,
            close_events = { 'BufLeave', 'CursorMoved', 'InsertEnter', 'FocusLost' },
            border = 'rounded',
            source = 'always',
            prefix = ' ',
        }
        vim.diagnostic.open_float(hover_opts)
    end, '✨lsp show diagnostics on Cursorhold'
    )
    -- Don't check for the capability here to allow dynamic registration of the request.
    -- vim.lsp.document_color.enable(true, { bufnr = bufnr, style = 'virtual' })
    vim.lsp.document_color.enable(false)

    local function can_format(event)
        if vim.g.minifiles_active or not vim.g.autoformat then
            return false
        end
        if vim.b[event.buf].skip_formatting then
            vim.b[event.buf].skip_formatting = false
            return false
        end
        return true
    end
    vim.b[bufnr].skip_formatting = false
    if client:supports_method 'textDocument/formatting' then
        vim.bo[bufnr].formatexpr = 'v:lua.vim.lsp.formatexpr(#{timeout_ms:1000})'
        vim.api.nvim_create_autocmd('BufWritePre', {
            group = augrp_fmt,
            buf = bufnr,
            callback = function(ev)
                if not can_format(ev) then return end
                vim.lsp.buf.format({ async = false })
            end,
            desc = 'format',
        })
    else
        vim.api.nvim_create_autocmd('BufWritePost', {
            group = augrp_fmt,
            desc = 'Format on save',
            callback = function(ev)
                if not can_format(ev) then return end
                require('custom.format').format(ev.buf)
            end,
        })
    end
    --- Global lsp keymaps redefined to use Fzf-lua functions
    -- Code Action
    if client:supports_method 'textDocument/codeAction' then
        VimRc.code_action = require 'vimrc_lsp.code_action'
        VimRc.code_action.on_attach(bufnr, client)
    end
    if client:supports_method 'textDocument/signatureHelp' then
        vim.keymap.set({ 'i' }, '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<cr>', { desc = 'Signature help' })
    end

    if client:supports_method 'textDocument/foldingRange' then
        local win = vim.api.nvim_get_current_win()
        vim.wo[win][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
    end

    local lsp_gr_keys = {
        { 's', '<Cmd>Trouble symbols toggle<CR>', 'Doc Symbols (Trouble)' },
        { 'l', '<Cmd>FzfLua lsp_document_symbols<CR>', 'Doc Symbols (Fzf)' },
        { 'A', '<Cmd>lua VimRc.code_action.run_sorted() <CR>', 'Code Action Menu ' },
        { 'f', '<Cmd>lua vim.lsp.buf.format({async=false})<CR>', 'Lsp Format' },
        { 'r', '<Cmd>FzfLua lsp_references<cr>', 'References' },
        { 'R', '<Cmd>lua VimRc.code_action.refactor() <CR>', 'Refactor' },
        { 'c', '<Cmd>lua vim.lsp.codelens.run()<CR>', 'Code Lens' },
        { 'd', '<Cmd>FzfLua lsp_definitions<CR>', 'Goto Definition' },
        { 'D', '<Cmd>FzfLua lsp_declaration<CR>', 'Goto Declaration' },
    }
    for _, key in ipairs(lsp_gr_keys) do
        vim.keymap.set('n', 'gr' .. key[1], key[2], { desc = key[3] })
    end
end
---@comment Get the lsp configuration in the current working directory
---@return string[]
local lsp_configs_get = function()
    return vim
        .iter(vim.fn.globpath(vim.fn.expand '$XDG_CONFIG_HOME/nvim', '**/lsp/*.lua', false, true))
        :map(function(f)
            return f:match '/([%w%-_]+)%.lua$'
        end)
        :totable()
end
-- Set up LSP servers.
VimRc.later(function()
    vim.g.autoformat = true
    local blink_plug = vim.pack.get({ 'blink.cmp' })[1]
    if blink_plug then
        local capabilities = require('blink.cmp').get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities(), false)
        vim.lsp.config('*', { capabilities = capabilities })
        local blink_dylib = vim.fs.joinpath(blink_plug.path, 'target', 'release')
        if blink_plug.path and vim.uv.fs_stat(blink_dylib) ~= nil then
            local lib_path = vim.env['LD_LIBRARY_PATH']
            lib_path = lib_path and lib_path .. ':' or ''
            vim.fn.setenv('LD_LIBRARY_PATH', lib_path .. blink_dylib)
        end
    end
    local augrp_lsp = vim.api.nvim_create_augroup('vimrc.lsp', { clear = false })

    vim.diagnostic.config {
        severity_sort = true,
        float = {
            border = 'rounded',
            source = 'if_many',
            underline = true,
        },
        virtual_text = {
            spacing = 2,
            source = 'if_many',
            prefix = 'o',
        },
        -- Disable signs in the gutter.
        signs = {
            text = {
                [vim.diagnostic.severity.ERROR] = 'E',
                [vim.diagnostic.severity.WARN] = 'W',
                [vim.diagnostic.severity.INFO] = 'I',
                [vim.diagnostic.severity.HINT] = 'H',
            },
        },
    }

    vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(ev)
            local bufnr = ev.buf
            local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))

            VimRc.lsp_on_attach(client, bufnr)
        end,
        pattern = '*',
        desc = 'LspAttach Configure Lsps',
        group = augrp_lsp,
    })

    --- Lsp Configuration happens on a different paths sometimes when Lsp Servers are expected
    --- to register dynamic capabilities. Current the same on_attach handler is used so
    --- is not being leveraged but kept as "just in case"
    vim.lsp.handlers['client/registerCapability'] = (function(overridden_register_caps)
        return function(err, res, ctx)
            local client = vim.lsp.get_client_by_id(ctx.client_id)
            if not client then
                return
            end

            -- Update mappings when registering dynamic capabilities.
            VimRc.lsp_on_attach(client, vim.api.nvim_get_current_buf()) -- end
            return overridden_register_caps(err, res, ctx)
        end
    end)(vim.lsp.handlers['client/registerCapability'])

    ---
    --[[
    -- Setup autocmds for Lsp Events
    -- LspAttach event happens when the buffer is open and Neovim starts the Lsp client
    -- for that filetype and using other heuristics
    --]]
    --
    -- Extend neovim's client capabilities with the completion ones.

    local servers = lsp_configs_get()
    vim.lsp.config['pklls'] = vim.tbl_extend('force', {
        name = 'pklls',
        filetypes = { 'pkl' },
    }, require 'vimrc_lsp.pkl'
    )
    servers = vim.list_extend(servers, { 'lua_ls', 'pklls' })
    vim.lsp.enable(servers)

    -- HACK: Override buf_request to ignore notifications from LSP servers that don't implement a method.
    local buf_request = vim.lsp.buf_request
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.lsp.buf_request = function(bufnr, method, params, handler)
        return buf_request(bufnr, method, params, handler, function() end)
    end
end)
