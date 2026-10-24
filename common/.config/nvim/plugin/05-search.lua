---@module 'fzf-lua'

---@param selected string[]
---@param opts     fzf-lua.config.Zoxide | { }
local zoxide_open = function(selected, opts)
    if not selected[1] then
        return
    end
    local cwd = selected[1]:match '[^\t]+$' or selected[1]
    if opts.cwd then
        cwd = vim.fs.joinpath(opts.cwd, cwd)
    end
    if vim.uv.fs_stat(cwd) then
        vim.cmd('cd ' .. cwd)
        vim.cmd('Oil')
        vim.system { 'zoxide', 'add', '--', cwd }
        VimRc.info(("cwd set to '%s'"):format(cwd))
    else
        VimRc.warn(("Unable to set cwd to '%s', directory is not accessible"):format(cwd))
    end
end

local filedel = function(selected, opts)
    if not selected[1] then return end
    local file = selected[1]:match("^[^%s]+") or ''
    if (vim.uv.fs_stat(file) or {}).type ~= 'file' then
        vim.notify("Cannot delete " .. file, vim.log.levels.WARN)
        return
    end
    if require('fzf-lua').utils.confirm("Delete file " .. file .. "?", "&Yes\n&No") == 1 then
        local output, rc = vim.fn.systemlist({ 'rm' })
        if rc ~= 0 then
            vim.notify(table.concat(output, "\n"), vim.log.levels.ERROR)
        else
            vim.notify('Deleted file ' .. file, vim.log.levels.INFO)
        end
    end
end

---@param selected string[]
---@param opts     fzf-lua.config.CommandHistory | { }
local hist_copy = function(selected, opts)
    local iter = opts.reverse_list and vim.iter(selected) or vim.iter(selected):rev()
    iter:each(function(e)
        local idx = assert(FzfLua.utils.tointeger(opts.reverse_list and e or -e - 1))
        local sel = vim.fn.histget(':', idx) -- get before deleted
        vim.fn.setreg('+', sel)
        VimRc.info(string.format('Copied: %s', sel))
    end)
end

VimRc.later(function()
    --[[ START OF 05-search.lua ]]--

    require('fzf-lua').setup {
        ---@type fzf-lua.profile[]
        { 'fzf-native', 'border-fused', 'hide' },
        keymap = {
            fzf = { true, ['ctrl-q'] = 'select-all+accept' },
        },
        -- Configuration for specific commands.
        files = {
            cmd = 'fd',
            ignore_current_file = true,
            winopts = {
                preview = { hidden = true },
            },
            --- NOTE: the directory must exist, so if you're using a custom folder make sure the directory exists using mkdir -p.
            fzf_opts = {
                ['--history'] = vim.fs.joinpath(vim.fn.stdpath 'data', 'fzf-lua', 'files-history'),
            },
            no_ignore = false, -- enable hidden files by default
            actions = {
                ['ctrl-x'] = {
                    fn = filedel,
                    reload = true,
                },
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
        },
    }
    ---@class fzf-lua.config.Visits: fzf-lua.config.Files | { }?
    ---@field sort_by 'recency' | 'frequency' | 'custom'
    ---
    ---@param opts fzf-lua.config.Visits | { }?
    ---@return thread?, string?, table?
    FzfLua.register_extension('visits', function(opts)
        ---@type fzf-lua.config.Files
        opts = FzfLua.config.normalize_opts(opts, 'files')
        if not opts then
            return
        end

        if not MiniVisits then
            VimRc.warn 'MiniVisits is null.'
            return
        end

        -- Get paths sorted from most to least recent
        local sort
        if opts.sort_by == 'custom' then else
            sort = opts.sort_by == 'recency' and MiniVisits.gen_sort.default { recency_weight = 1 }
                or MiniVisits.gen_sort.default {
                    recency_weight = 0,
                }
        end

        -- Get paths from all cwd sorted from most to least frequent
        local is_not_hidden = function(path_data)
            return not vim.startswith(vim.fn.fnamemodify(path_data.path, ':t'), '.')
        end
        local contents = function(cb)
            for _, s in ipairs(MiniVisits.list_paths(nil, {
                    sort = sort,
                    filter = function(path_data)
                        local keep = true
                        if not opts.hidden then
                            keep = is_not_hidden(path_data)
                        end
                        return keep
                    end,
                })) do
                local st = vim.uv.fs_stat(s)
                if st and st.type == 'file' then
                    s = assert(FzfLua.make_entry.file(s, opts))
                    cb(s)
                end
            end
            cb(nil)
        end

        return FzfLua.fzf_exec(contents, opts)
    end, vim.tbl_extend('force', FzfLua.defaults.files, { sort_by = 'recency' })
    )

    ---@class fzf-lua.config.West : fzf-lua.config.Files | { }?
    ---@field sort_by 'recency' | 'frequency' | 'custom'
    --- Global multi-picker, combines files, buffers and symbols.
    ---@diagnostic disable-next-line: param-type-mismatch
    ---@class fzf-lua.config.West : fzf-lua.config.Files
    -- FzfLua.register_extension('west', function(opts)
    --     opts = FzfLua.config.normalize_opts(opts, 'west')
    --     if not opts then
    --         return
    --     end
    --
    --     local contents = function(cb)
    --         for _, s in ipairs(vim.fs.find({ 'sample.yaml', 'testcase.yaml' }, {
    --                 type = 'file',
    --                 path = opts.cwd or '.',
    --             })) do
    --             local st = vim.uv.fs_stat(s)
    --             if st and st.type == 'file' then
    --                 local obj = vim
    --                     .system({ 'yq', 'eval', '-o=lua', '--lua-unquoted', "'[.tests[] | key]'", s }, { text = true })
    --                     :wait(1000)
    --
    --                 if obj.code ~= 0 then
    --                     return
    --                 end
    --                 local samples = VimRc.evaluate(obj.stdout)
    --                 for _, sample in ipairs(vim._ensure_list(samples)) do
    --                     s = assert(string.format('%q/%q', s, sample))
    --                     cb(s)
    --                 end
    --             end
    --         end
    --         cb(nil)
    --     end
    --     return FzfLua.fzf_exec(contents, opts)
    -- end, {}
    -- )
end) --[[ END OF 05-search.lua ]]--
