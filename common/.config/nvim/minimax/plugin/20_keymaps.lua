-- local nmap_leader = function(suffix, rhs, desc)
--   vim.keymap.set('n', '<Leader>' .. suffix, rhs, { desc = desc })
-- end
--
-- local xmap_leader = function(suffix, rhs, desc)
--   vim.keymap.set('x', '<Leader>' .. suffix, rhs, { desc = desc })
-- end

-- f is for 'Fuzzy Find'. Common usage:
-- - `<Leader>ff` - find files; for best performance requires `ripgrep`
-- - `<Leader>fg` - find inside files; requires `ripgrep`
-- - `<Leader>fh` - find help tag
-- - `<Leader>fr` - resume latest picker
-- - `<Leader>fv` - all visited paths; requires 'mini.visits'
--
-- All these use 'mini.pick'. See `:h MiniPick-overview` for an overview.
local pick_added_hunks_buf = '<Cmd>Pick git_hunks path="%" scope="staged"<CR>'

_G.Utils.nmapleader('f/', '<Cmd>Pick history scope="/"<CR>',            '"/" history')
_G.Utils.nmapleader('f:', '<Cmd>Pick history scope=":"<CR>',            '":" history')
_G.Utils.nmapleader('fa', '<Cmd>Pick git_hunks scope="staged"<CR>',     'Added hunks (all)')
_G.Utils.nmapleader('fA', pick_added_hunks_buf,                         'Added hunks (buf)')
_G.Utils.nmapleader('fb', '<Cmd>Pick buffers<CR>',                      'Buffers')
_G.Utils.nmapleader('fc', '<Cmd>Pick git_commits<CR>',                  'Commits (all)')
_G.Utils.nmapleader('fC', '<Cmd>Pick git_commits path="%"<CR>',         'Commits (buf)')
_G.Utils.nmapleader('fd', '<Cmd>Pick diagnostic scope="all"<CR>',       'Diagnostic workspace')
_G.Utils.nmapleader('fD', '<Cmd>Pick diagnostic scope="current"<CR>',   'Diagnostic buffer')
_G.Utils.nmapleader('ff', '<Cmd>Pick files<CR>',                        'Files')
_G.Utils.nmapleader('fg', '<Cmd>Pick grep_live<CR>',                    'Grep live')
_G.Utils.nmapleader('fG', '<Cmd>Pick grep pattern="<cword>"<CR>',       'Grep current word')
_G.Utils.nmapleader('fh', '<Cmd>Pick help<CR>',                         'Help tags')
_G.Utils.nmapleader('fH', '<Cmd>Pick hl_groups<CR>',                    'Highlight groups')
_G.Utils.nmapleader('fl', '<Cmd>Pick buf_lines scope="all"<CR>',        'Lines (all)')
_G.Utils.nmapleader('fL', '<Cmd>Pick buf_lines scope="current"<CR>',    'Lines (buf)')
_G.Utils.nmapleader('fm', '<Cmd>Pick git_hunks<CR>',                    'Modified hunks (all)')
_G.Utils.nmapleader('fM', '<Cmd>Pick git_hunks path="%"<CR>',           'Modified hunks (buf)')
_G.Utils.nmapleader('fr', '<Cmd>Pick resume<CR>',                       'Resume')
_G.Utils.nmapleader('fp', '<Cmd>Pick projects<CR>',                     'Projects')
_G.Utils.nmapleader('fR', '<Cmd>Pick lsp scope="references"<CR>',       'References (LSP)')
_G.Utils.nmapleader('fs', '<Cmd>Pick lsp scope="workspace_symbol"<CR>', 'Symbols workspace')
_G.Utils.nmapleader('fS', '<Cmd>Pick lsp scope="document_symbol"<CR>',  'Symbols document')
_G.Utils.nmapleader('fv', '<Cmd>Pick visit_paths cwd=""<CR>',           'Visit paths (all)')
_G.Utils.nmapleader('fV', '<Cmd>Pick visit_paths<CR>',                  'Visit paths (cwd)')

-- g is for 'Git'. Common usage:
-- - `<Leader>gs` - show information at cursor
-- - `<Leader>go` - toggle 'mini.diff' overlay to show in-buffer unstaged changes
-- - `<Leader>gd` - show unstaged changes as a patch in separate tabpage
-- - `<Leader>gL` - show Git log of current file
local git_log_cmd = [[Git log --pretty=format:\%h\ \%as\ │\ \%s --topo-order]]
local git_log_buf_cmd = git_log_cmd .. ' --follow -- %'

_G.Utils.nmapleader('ga', '<Cmd>Git diff --cached<CR>',             'Added diff')
_G.Utils.nmapleader('gA', '<Cmd>Git diff --cached -- %<CR>',        'Added diff buffer')
_G.Utils.nmapleader('gc', '<Cmd>Git commit<CR>',                    'Commit')
_G.Utils.nmapleader('gC', '<Cmd>Git commit --amend<CR>',            'Commit amend')
_G.Utils.nmapleader('gd', '<Cmd>Git diff<CR>',                      'Diff')
_G.Utils.nmapleader('gD', '<Cmd>Git diff -- %<CR>',                 'Diff buffer')
_G.Utils.nmapleader('gl', '<Cmd>' .. git_log_cmd .. '<CR>',         'Log')
_G.Utils.nmapleader('gL', '<Cmd>' .. git_log_buf_cmd .. '<CR>',     'Log buffer')
_G.Utils.nmapleader('go', '<Cmd>lua MiniDiff.toggle_overlay()<CR>', 'Toggle overlay')
_G.Utils.nmapleader('gs', '<Cmd>lua MiniGit.show_at_cursor()<CR>',  'Show at cursor')

_G.Utils.xmapleader('gs', '<Cmd>lua MiniGit.show_at_cursor()<CR>', 'Show at selection')


-- m is for 'Map'. Common usage:
-- - `<Leader>mt` - toggle map from 'mini.map' (closed by default)
-- - `<Leader>mf` - focus on the map for fast navigation
-- - `<Leader>ms` - change map's side (if it covers something underneath)
_G.Utils.nmapleader('mf', '<Cmd>lua MiniMap.toggle_focus()<CR>', 'Focus (toggle)')
_G.Utils.nmapleader('mr', '<Cmd>lua MiniMap.refresh()<CR>',      'Refresh')
_G.Utils.nmapleader('ms', '<Cmd>lua MiniMap.toggle_side()<CR>',  'Side (toggle)')
_G.Utils.nmapleader('mt', '<Cmd>lua MiniMap.toggle()<CR>',       'Toggle')

-- o is for 'Other'. Common usage:
-- - `<Leader>oz` - toggle between "zoomed" and regular view of current buffer
_G.Utils.nmapleader('or', '<Cmd>lua MiniMisc.resize_window()<CR>', 'Resize to default width')
_G.Utils.nmapleader('ot', '<Cmd>lua MiniTrailspace.trim()<CR>',    'Trim trailspace')
_G.Utils.nmapleader('oz', '<Cmd>lua MiniMisc.zoom()<CR>',          'Zoom toggle')

-- s is for 'Session'. Common usage:
-- - `<Leader>sn` - start new session
-- - `<Leader>sr` - read previously started session
-- - `<Leader>sd` - delete previously started session
local session_new = 'MiniSessions.write(vim.fn.input("Session name: "))'

_G.Utils.nmapleader('sd', '<Cmd>lua MiniSessions.select("delete")<CR>', 'Delete')
_G.Utils.nmapleader('sn', '<Cmd>lua ' .. session_new .. '<CR>',         'New')
_G.Utils.nmapleader('sr', '<Cmd>lua MiniSessions.select("read")<CR>',   'Read')
_G.Utils.nmapleader('sw', '<Cmd>lua MiniSessions.write()<CR>',          'Write current')

if vim.lsp.inlay_hint then
  _G.Utils.nmap('<leader>uh', function()

    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
  end, 'Toggle Inlay Hints')
end

-- v is for 'Visits'. Common usage:
-- - `<Leader>vv` - add    "core" label to current file.
-- - `<Leader>vV` - remove "core" label to current file.
-- - `<Leader>vc` - pick among all files with "core" label.
local make_pick_core = function(cwd, desc)
  return function()
    local sort_latest = MiniVisits.gen_sort.default({ recency_weight = 1 })
    local local_opts = { cwd = cwd, filter = 'core', sort = sort_latest }
    MiniExtra.pickers.visit_paths(local_opts, { source = { name = desc } })
  end
end
-- Git and Terminal helpers
local function get_git_root()
  local path = vim.api.nvim_buf_get_name(0)
  local dir = vim.fn.isdirectory(path) == 1 and path or vim.fn.fnamemodify(path, ':h')
  local git_root = vim.fn.systemlist('git -C ' .. vim.fn.shellescape(dir) .. ' rev-parse --show-toplevel')[1]
  if vim.v.shell_error == 0 then
    return git_root
  end
  return nil
end

_G.Utils.nmapleader('vc', make_pick_core('',  'Core visits (all)'),       'Core visits (all)')
_G.Utils.nmapleader('vC', make_pick_core(nil, 'Core visits (cwd)'),       'Core visits (cwd)')
_G.Utils.nmapleader('vv', '<Cmd>lua MiniVisits.add_label("core")<CR>',    'Add "core" label')
_G.Utils.nmapleader('vV', '<Cmd>lua MiniVisits.remove_label("core")<CR>', 'Remove "core" label')
_G.Utils.nmapleader('vl', '<Cmd>lua MiniVisits.add_label()<CR>',          'Add label')
_G.Utils.nmapleader('vL', '<Cmd>lua MiniVisits.remove_label()<CR>',       'Remove label')
-- stylua: ignore end
--
--
_G.Utils.nmapleader('n', "<Cmd>lua MiniNotify.show_history()<CR>", "Notifications")
-- Lazygit
if vim.fn.executable('lazygit') == 1 then
  _G.Utils.nmap('<leader>gg', function()
    local git_root = get_git_root()
    require('snacks').lazygit({ cwd = git_root })
  end, 'Lazygit (Root Dir)')
  _G.Utils.nmap('<leader>gG', function() require('snacks').lazygit() end, 'Lazygit (cwd)')
  _G.Utils.nmap('<leader>gf', function() require('snacks').picker.git_log_file() end, 'Git Current File History')
  _G.Utils.nmap('<leader>gl', function()
    local git_root = get_git_root()
    require('snacks').picker.git_log({ cwd = git_root })
  end, 'Git Log')
  _G.Utils.nmap('<leader>gL', function() require('snacks').picker.git_log() end, 'Git Log (cwd)')
  _G.Utils.nmap('<leader>gb', function() require('snacks').picker.git_log_line() end, 'Git Blame Line')
end
