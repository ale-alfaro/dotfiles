VimRc.later(function()
    require('mini.visits').setup()
end)
-- local builtin_textobjects = {
--   -- Use balanced pair for brackets. Use opening ones to possibly remove edge
--   -- whitespace from `i` textobject.
--   ['('] = { '%b()', '^.%s*().-()%s*.$' },
--   [')'] = { '%b()', '^.().*().$' },
--   ['['] = { '%b[]', '^.%s*().-()%s*.$' },
--   [']'] = { '%b[]', '^.().*().$' },
--   ['{'] = { '%b{}', '^.%s*().-()%s*.$' }%,
--   ['}'] = { '%b{}', '^.().*().$' },
--   ['<'] = { '%b<>', '^.%s*().-()%s*.$' },
--   ['>'] = { '%b<>', '^.().*().$' },
--   -- Use special "same balanced" pattern to select quotes in pairs
--   ["'"] = { "%b''", '^.().*().$' },
--   ['"'] = { '%b""', '^.().*().$' },
--   ['`'] = { '%b``', '^.().*().$' },
--   -- Derived from user prompt
--   ['?'] = MiniAi.gen_spec.user_prompt(),
--   -- Argument
--   ['a'] = MiniAi.gen_spec.argument(),
--   -- Brackets
--   ['b'] = { { '%b()', '%b[]', '%b{}' }, '^.().*().$' },
--   -- Function call
--   ['f'] = MiniAi.gen_spec.function_call(),
--   -- Tag
--   ['t'] = { '<(%w-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' },
--   -- Quotes
--   ['q'] = { { "%b''", '%b""', '%b``' }, '^.().*().$' },
--

VimRc.later(function()
    require('mini.git').setup()
    require('mini.diff').setup()
end)
VimRc.now(function()
    NOTIFY_WIDTH = 120
    --- to display progress when the server supports percentages
    ---@param notif_arr Notification[]
    local show_notifications = function(notif_arr)
        local ns_id = vim.api.nvim_create_namespace 'MiniNotifyHighlight'

        local buf_id
        for _, id in ipairs(vim.api.nvim_list_bufs()) do
            if vim.bo[id].filetype == 'vimrc-notify' then
                buf_id = id
            end
        end
        -- Ensure clear buffer
        -- vim.api.nvim_buf_clear_namespace(buf_id, ns_id, 0, -1)
        -- vim.api.nvim_buf_set_lines(buf_id, 0, -1, true, {})

        -- Compute lines and highlight regions
        local lines, highlights = {}, {}
        for _, notif in ipairs(notif_arr) do
            local notif_lines = vim.split(notif.msg, '\n')
            for _, l in ipairs(notif_lines) do
                table.insert(lines, l)
            end
            table.insert(
                highlights, { group = notif.hl_group, from_line = #lines - #notif_lines + 1, to_line = #lines }
            )
        end

        if buf_id ~= nil then
            vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)
        else
            buf_id = VimRc.show_in_split(lines, 'vimrc://notify')
        end
        -- Set lines and highlighting
        local extmark_opts = { end_col = 0, hl_eol = true, hl_mode = 'combine' }
        for _, hi_data in ipairs(highlights) do
            extmark_opts.end_row, extmark_opts.hl_group = hi_data.to_line, hi_data.group
            vim.api.nvim_buf_set_extmark(buf_id, ns_id, hi_data.from_line - 1, 0, extmark_opts)
        end
        vim.api.nvim_set_current_buf(buf_id)
    end

    ---@param pred   fun(Notification): boolean)?
    ---@param format fun(Notification): string)?
    local get_notif_arr = function(pred, format)
        -- Get notifications based on predicate
        local notif_arr = MiniNotify.get_all()
        if pred then
            notif_arr = vim.tbl_filter(function(notif)
                return pred(notif)
            end, notif_arr)
        end
        -- Prepare content
        table.sort(notif_arr, function(a, b)
            return a.ts_update < b.ts_update
        end)
        format = format or MiniNotify.default_format
        for _, notif in ipairs(notif_arr) do
            local res = format(notif)
            if type(res) ~= 'string' then
                VimRc.err 'Output of `content.format` should be string.'
            end
            notif.msg = res
        end
        return notif_arr
    end

    require('mini.notify').setup()
    vim.notify = MiniNotify.make_notify()

    local keymaps = {
        {
            'a',
            function()
                -- Get active notifications
                local notifs = get_notif_arr(function(notif)
                    return notif.ts_remove ~= nil
                end)
                show_notifications(notifs)
            end,
            'All',
        },
        {
            'h',
            '<Cmd>lua MiniNotify.show_history()<CR>',
            'History',
        },
        {
            'e',
            function()
                -- Get active notifications
                local err_notifs = get_notif_arr(function(notif)
                    return notif.level == 'ERROR'
                end)
                show_notifications(err_notifs)
            end,
            'Errors',
        },
        {
            'd',
            '<Cmd>lua MiniNotify.clear()<CR>',
            'Dismiss',
        },
    }

    for _, k in ipairs(keymaps) do
        vim.keymap.set('n', '<leader>n' .. k[1], k[2], { desc = k[3] })
    end
end)
-- Extend and create a/i textobjects, like `:h a(`, `:h a'`, and more).
-- Contains not only `a` and `i` type of textobjects, but also their "next" and
-- "last" variants that will explicitly search for textobjects after and before
-- cursor. Example usage:
-- - `ci)` - *c*hange *i*inside parenthesis (`)`)
-- - `di(` - *d*elete *i*inside padded parenthesis (`(`)
-- - `yaq` - *y*ank *a*round *q*uote (any of "", '', or ``)
-- - `vif` - *v*isually select *i*inside *f*unction call
-- - `cina` - *c*hange *i*nside *n*ext *a*rgument
-- - `valaala` - *v*isually select *a*round *l*ast (i.e. previous) *a*rgument
--   and then again reselect *a*round new *l*ast *a*rgument
--
-- See also:
-- - `:h text-objects` - general info about what textobjects are
-- - `:h MiniAi-builtin-textobjects` - list of all supported textobjects
-- - `:h MiniAi-textobject-specification` - examples of custom textobjects
VimRc.later(function()
    local ai = require 'mini.ai'
    ai.setup {
        custom_textobjects = {
            F = ai.gen_spec.treesitter { a = '@function.outer', i = '@function.inner' },
            c = ai.gen_spec.treesitter {
                a = { '@conditional.outer', '@loop.outer' },
                i = { '@conditional.inner', '@loop.inner' },
            },
            f = ai.gen_spec.function_call { name_pattern = '[%w_%.%>%<]' },
            p = ai.gen_spec.user_prompt(),
            ['|'] = ai.gen_spec.pair('|', '|', { type = 'non-balanced' }),
        },
    }
end)

-- Common configuration presets. Example usage:
-- - `<C-s>` in Insert mode - save and go to Normal mode
-- - `go` / `gO` - insert empty line before/after in Normal mode
-- - `gy` / `gp` - copy / paste from system clipboard
-- - `\` + key - toggle common options. Like `\h` toggles highlighting search.
-- - `<C-hjkl>` (four combos) - navigate between windows.
VimRc.later(function()
    require('mini.bufremove').setup()
end)
VimRc.later(function()
    require('mini.align').setup()
end)

VimRc.later(function()
    require('mini.bracketed').setup { comment = { suffix = '', options = {} }, conflict = { suffix = 'c', options = {} } }
end)

VimRc.later(function()
    require('mini.comment').setup()
end)
VimRc.later(function()
    require('mini.indentscope').setup()
end)

-- Split and join arguments (regions inside brackets between allowed separators).
-- It uses Lua patterns to find arguments, which means it works in comments and
-- strings but can be not as accurate as tree-sitter based solutions.
-- Each action can be configured with hooks (like add/remove trailing comma).
-- Example usage:
-- - `gS` - toggle between joined (all in one line) and split (each on a separate
--   line and indented) arguments. It is dot-repeatable (see `:h .`).
--
-- See also:
-- - `:h MiniSplitjoin.gen_hook` - list of available hooks
VimRc.later(function()
    require('mini.splitjoin').setup()
end)

--
-- Example usage (this may feel intimidating at first, but after practice it
-- becomes second nature during text editing):
-- - `sdf`   - *s*urround *d*elete *f*unction call (like `f(var)` -> `var`)
-- - `srb[`  - *s*urround *r*eplace *b*racket (any of [], (), {}) with padded `[`
-- - `sf*`   - *s*urround *f*ind right part of `*` pair (like bold in markdown)
-- - `shf`   - *s*urround *h*ighlight current *f*unction call
-- - `srn{{` - *s*urround *r*eplace *n*ext curly bracket `{` with padded `{`
-- - `sdl'`  - *s*urround *d*elete *l*ast quote pair (`'`)
-- - `vaWsa<Space>` - *v*isually select *a*round *W*ORD and *s*urround *a*dd
--                    spaces (`<Space>`)
---
--- Regular mappings:
--- - `saiw?[[<CR>]]<CR>` - add (`sa`) for inner word (`iw`) interactive
---   surrounding (`?`): `[[` for left and `]]` for right.
--- - `2sdf` - delete (`sd`) second (`2`) surrounding function call (`f`).
--- - `sr)tdiv<CR>` - replace (`sr`) surrounding parenthesis (`)`) with tag
---   (`t`) with identifier 'div' (`div<CR>` in command line prompt).
--- - `sff` - find right (`sf`) part of surrounding function call (`f`).
--- - `sh}` - highlight (`sh`) for a brief period of time surrounding curly
---   brackets (`}`).
---
--- Extended mappings (temporary force "prev"/"next" search methods):
--- - `sdnf` - delete (`sd`) next (`n`) function call (`f`).
--- - `srlf(` - replace (`sr`) last (`l`) function call (`f`) with padded
---   bracket (`(`).
--- - `2sfnt` - find (`sf`) second (`2`) next (`n`) tag (`t`).
--- - `2shl}` - highlight (`sh`) last (`l`) second (`2`) curly bracket (`}`).
-- See also:
--- `Key` represents the surrounding identifier: single character which should
--  be typed after action mappings (see "Mappings" in |MiniSurround.config|).
--- `Name` is a description of surrounding.
--- `Example line` contains a string for which examples are constructed. The
--  `*` denotes the cursor position over `a` character.
--- `Delete` shows the result of typing `sd` followed by surrounding identifier.
--  It aims to demonstrate "input" surrounding which is also used in replace
--  with `sr` (surrounding id is typed first), highlight with `sh`, find with
--  `sf` and `sF`.
--- `Replace` shows the result of typing `sr!` followed by surrounding
--  identifier (with possible follow up from user). It aims to demonstrate
--  "output" surrounding which is also used in adding with `sa` (followed by
--  textobject/motion or in Visual mode).
--
-- Example: typing `sd)` with cursor on `*` (covers `a` character) changes line
-- `!( *a (bb) )!` into `! aa (bb) !`. Typing `sr!)` changes same initial line
-- into `(( aa (bb) ))`.
-- >
-- ┌───┬───────────────┬───────────────┬─────────────┬─────────────────┐
-- │Key│     Name      │  Example line │    Delete   │     Replace     │
-- ├───┴───────────────┴───────────────┴─────────────┴─────────────────┤
-- ├┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
-- │ ( │  Balanced ()  │ !( *a (bb) )! │  !aa (bb)!  │ ( ( aa (bb) ) ) │
-- │ [ │  Balanced []  │ ![ *a [bb] ]! │  !aa [bb]!  │ [ [ aa [bb] ] ] │
-- │ { │  Balanced {}  │ !{ *a {bb} }! │  !aa {bb}!  │ { { aa {bb} } } │
-- │ < │  Balanced <>  │ !< *a <bb> >! │  !aa <bb>!  │ < < aa <bb> > > │
-- ├┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
-- │ ) │  Balanced ()  │ !( *a (bb) )! │ ! aa (bb) ! │ (( aa (bb) ))   │
-- │ ] │  Balanced []  │ ![ *a [bb] ]! │ ! aa [bb] ! │ [[ aa [bb] ]]   │
-- │ } │  Balanced {}  │ !{ *a {bb} }! │ ! aa {bb} ! │ {{ aa {bb} }}   │
-- │ > │  Balanced <>  │ !< *a <bb> >! │ ! aa <bb> ! │ << aa <bb> >>   │
-- │ b │  Alias for    │ !( *a {bb} )! │ ! aa {bb} ! │ (( aa {bb} ))   │
-- │   │  ), ], or }   │               │             │                 │
-- ├┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
-- │ q │  Alias for    │ !'aa'*a'aa'!  │ !'aaaaaa'!  │ "'aa'aa'aa'"    │
-- │   │  ", ', or `   │               │             │                 │
-- ├┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
-- │ ? │  User prompt  │ !e * o!       │ ! a !       │ ee a oo         │
-- │   │(typed e and o)│               │             │                 │
-- ├┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
-- │ t │      Tag      │ !<x>*</x>!    │ !a!         │ <y><x>a</x></y> │
-- │   │               │               │             │ (typed y)       │
-- ├┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
-- │ f │ Function call │ !f(*a, bb)!   │ !aa, bb!    │ g(f(*a, bb))    │
-- │   │               │               │             │ (typed g)       │
-- ├┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┤
-- │   │    Default    │ !_a*a_!       │ !aaa!       │ __aaa__         │
-- │   │   (typed _)   │               │             │                 │
-- └┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┘
--
--
--                                               *MiniSurround-count-with-actions*
-- |[count]| is supported by all actions in the following ways:
--
-- * In add, two types of `[count]` is supported in Normal mode:
--  `[count1]sa[count2][textobject]`. The `[count1]` defines how many times
--  left and right parts of output surrounding will be repeated and `[count2]` is
--  used for textobject.
--  In Visual mode `[count]` is treated as `[count1]`.
--  Example: `2sa3aw)` and `v3aw2sa)` will result into textobject `3aw` being
--  surrounded by `((` and `))`.
--
--- In delete/replace/find/highlight `[count]` means "find n-th surrounding
--  and execute operator on it".
--  Example: `2sd)` on line `(a(b(c)b)a)` with cursor on `c` will result into
--  `(ab(c)ba)` (and not in `(abcba)` if it would have meant "delete n times").

--
VimRc.later(function()
    -- local surround = require 'mini.surround'
    -- local ts_input = surround.gen_spec.input.treesitter
    require('mini.surround').setup()
    --   custom_surroundings = {
    --     f = {
    --       input = ts_input({ outer = '@call.outer', inner = '@calll.inner' }, { use_nvim_treesitter = true }),
    --     },
    --   },
    -- }
end)

-- Highlight and remove trailspace. Temporarily stops highlighting in Insert mode
-- to reduce noise when typing. Example usage:
-- - `<Leader>ot` - trim all trailing whitespace in a buffer
VimRc.later(function()
    require('mini.operators').setup {

        replace = {
            -- NOTE: Default `gr*` LSP mappings are removed
            prefix = 'go',

            -- Whether to reindent new text to match previous indent
            reindent_linewise = true,
        },
    }
end)

VimRc.later(function()
    require('mini.hipatterns').setup {
        highlighters = {
            fixme = require('mini.extra').gen_highlighter.words({ 'FIXME', 'Fixme', 'fixme' }, 'MiniHipatternsFixme'),
            hack = require('mini.extra').gen_highlighter.words({ 'HACK', 'Hack', 'hack' }, 'MiniHipatternsHack'),
            todo = require('mini.extra').gen_highlighter.words({ 'TODO', 'Todo', 'todo' }, 'MiniHipatternsTodo'),
            note = require('mini.extra').gen_highlighter.words({ 'NOTE', 'Note', 'note' }, 'MiniHipatternsNote'),
            hex_color = require('mini.hipatterns').gen_highlighter.hex_color(),
        },
    }
end)
