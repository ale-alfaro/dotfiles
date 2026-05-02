local git = require 'mini.git'
local colors = require 'mini.colors'

git.setup()

local group = vim.api.nvim_create_augroup('mini_git', { clear = true })

local gen_blame_palette = function(count)
  local dark = vim.o.background == 'dark'
  local lightness = dark and 75 or 45
  local chroma = dark and 20 or 18
  local uv = vim.uv or vim.loop
  local offset = (uv.hrtime() % 360)
  local palette = {}
  for i = 1, count do
    -- Go to opposite side of color wheel so adjacent commits contrast more
    local hue = (offset + (i - 1) * 137.508) % 360
    palette[i] = colors.convert({ l = lightness, c = chroma, h = hue }, 'hex')
  end
  return palette
end

local gen_hl_groups = function()
  vim.api.nvim_set_hl(0, 'MiniGitBlameHash', { link = 'Comment' })
  vim.api.nvim_set_hl(0, 'MiniGitBlameUncommitted', { link = 'Conceal' })
end

gen_hl_groups() -- Call this now if colorscheme was already set

vim.api.nvim_create_autocmd('ColorScheme', { pattern = '*', group = group, callback = gen_hl_groups })

local pad_right = function(str, width)
  local pad = width - vim.fn.strwidth(str)
  if pad <= 0 then
    return str
  end
  return str .. string.rep(' ', pad)
end

--- Format unix timestamp
---@param timestamp integer Unix timestamp (seconds since epoch)
---@param fmt string os.date format string (e.g. `"%Y-%m-%d"`)
---@param rel? boolean|integer true = always relative, N = relative within N days then fallback to fmt
---@return string
local format_time = function(timestamp, fmt, rel)
  if not rel then
    return tostring(os.date(fmt, timestamp))
  end
  local diff = os.time() - timestamp
  local days = math.floor(diff / 86400)
  if type(rel) == 'number' and days >= rel then
    return tostring(os.date(fmt, timestamp))
  end
  local ago = function(n, unit)
    return n .. (n == 1 and ' ' .. unit .. ' ago' or ' ' .. unit .. 's ago')
  end
  if diff < 60 then
    return ago(diff, 'second')
  end
  if diff < 3600 then
    return ago(math.floor(diff / 60), 'minute')
  end
  if diff < 86400 then
    return ago(math.floor(diff / 3600), 'hour')
  end
  if diff < 2592000 then
    return ago(days, 'day')
  end
  if diff < 31536000 then
    return ago(math.floor(diff / 2592000), 'month')
  end
  return ago(math.floor(diff / 31536000), 'year')
end

--- Format parsed blame data into display lines.
--- @param data {sha: string, sha_short: string, date: string, author: string}[]
--- @param skip_consecutive boolean? Replace consecutive lines with the same sha with "┃"
--- @return string[]
local format_blame = function(data, skip_consecutive)
  local max_date = 0
  for _, entry in ipairs(data) do
    if entry.author ~= 'Not Committed Yet' then
      max_date = math.max(max_date, #entry.date)
    end
  end
  local formatted, prev_sha = {}, nil
  for _, entry in ipairs(data) do
    if skip_consecutive and entry.sha == prev_sha then
      table.insert(formatted, '┃')
    elseif entry.author == 'Not Committed Yet' then
      table.insert(formatted, 'Not Committed Yet')
    else
      table.insert(formatted, string.format('%s %s %s', entry.sha_short, pad_right(entry.date, max_date), entry.author))
    end
    prev_sha = entry.sha
  end
  return formatted
end

local parse_porcelain = function(lines)
  local commits, parsed = {}, {}
  local i = 1
  while i <= #lines do
    local sha, _, final = lines[i]:match '^(%x+) (%d+) (%d+)'
    if not sha then
      break
    end
    if not commits[sha] then
      commits[sha] = {}
      i = i + 1
      while i <= #lines and not lines[i]:match '^\t' do
        local key, val = lines[i]:match '^(%S+)%s?(.*)'
        if key then
          commits[sha][key] = val
        end
        i = i + 1
      end
    else
      i = i + 1
      while i <= #lines and not lines[i]:match '^\t' do
        i = i + 1
      end
    end
    local c = commits[sha]
    table.insert(parsed, {
      sha = sha,
      sha_short = sha:sub(1, 7),
      author = c.author or '',
      date = c['author-time'] and format_time(c['author-time'], '%Y-%m-%d', 10) or '',
      line = tonumber(final),
    })
    i = i + 1
  end
  return parsed
end

local blame_cb = function(event)
  if event.data.git_subcommand ~= 'blame' or not event.data.cmd_input.mods:match 'vertical' then
    return
  end
  vim.cmd 'wincmd H'
  local win_src, buf, win = event.data.win_source, event.buf, event.data.win_stdout

  -- stylua: ignore
  local settings = { number = false, relativenumber = false, winbar = "", signcolumn = "no", cursorbind = true, scrollbind = true, wrap = false }
  local saved = {}
  for key, val in pairs(settings) do
    saved[key] = vim.wo[win_src][key]
    vim.wo[win][key] = val
    vim.wo[win_src][key] = val
  end

  local blame_data = parse_porcelain(vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  local formatted = format_blame(blame_data, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, formatted)

  -- Highlights
  local ns = vim.api.nvim_create_namespace 'mini_git_blame'
  local unique_shas, sha_colors, color_idx = {}, {}, 0
  for _, data in ipairs(blame_data) do
    if not unique_shas[data.sha] and data.author ~= 'Not Committed Yet' then
      unique_shas[data.sha] = true
      color_idx = color_idx + 1
    end
  end
  local palette = gen_blame_palette(color_idx)
  color_idx = 0
  for i, data in ipairs(blame_data) do
    local ln = i - 1
    if not sha_colors[data.sha] and data.author ~= 'Not Committed Yet' then
      color_idx = color_idx + 1
      sha_colors[data.sha] = color_idx
      local color = palette[color_idx]
      vim.api.nvim_set_hl(0, 'MiniGitBlameDate' .. color_idx, { fg = color, italic = true })
      vim.api.nvim_set_hl(0, 'MiniGitBlameAuthor' .. color_idx, { fg = color })
    end
    if data.author == 'Not Committed Yet' then
      vim.api.nvim_buf_set_extmark(buf, ns, ln, 0, { end_col = #formatted[i], hl_group = 'MiniGitBlameUncommitted' })
    elseif formatted[i] == '┃' then
      -- stylua: ignore
      vim.api.nvim_buf_set_extmark(buf, ns, ln, 0, { end_col = #formatted[i], hl_group = "MiniGitBlameDate" .. sha_colors[data.sha] })
    else
      local ci = sha_colors[data.sha]
      local sha_end = #data.sha_short
      local date_end = sha_end + 1 + #data.date
      -- stylua: ignore start
      vim.api.nvim_buf_set_extmark(buf, ns, ln, 0, { end_col = sha_end, hl_group = "MiniGitBlameHash" })
      vim.api.nvim_buf_set_extmark(buf, ns, ln, sha_end + 1, { end_col = date_end, hl_group = "MiniGitBlameDate" .. ci })
      vim.api.nvim_buf_set_extmark(buf, ns, ln, date_end + 1, { end_row = ln, end_col = #formatted[i], hl_group = "MiniGitBlameAuthor" .. ci })
      -- stylua: ignore end
    end
  end

  -- Blame window options
  vim.wo[win].number = true
  vim.wo[win].winfixwidth = true
  vim.wo[win].winfixbuf = true
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].modifiable = false

  vim.api.nvim_win_set_cursor(0, { vim.fn.line('.', win_src), 0 })
  vim.cmd 'syncbind'

  -- Blame window width
  local max_len = 0
  for _, line in ipairs(formatted) do
    max_len = math.max(max_len, #line)
  end
  vim.api.nvim_win_set_width(win, max_len + math.max(vim.wo[win].numberwidth, #tostring(#formatted) + 1) + 2)

  -- Buffer keymaps
  local get_entry = function()
    return blame_data[vim.api.nvim_win_get_cursor(win)[1]]
  end
  local map = function(key, fn, desc)
    vim.keymap.set('n', key, fn, { buffer = buf, desc = desc })
  end
  local with_commit = function(fn)
    local entry = get_entry()
    if entry and entry.author ~= 'Not Committed Yet' then
      fn(entry.sha)
    end
  end

  -- stylua: ignore start
  local checkout = function() with_commit(function(sha) vim.cmd("Git checkout " .. sha) end) end
  local diff     = function() with_commit(function(sha) vim.cmd("Git diff " .. sha .. "^ " .. sha) end) end
  local files    = function() with_commit(function(sha) vim.cmd("Git show --name-status --format=fuller " .. sha) end) end
  local show     = function() with_commit(function(sha) vim.cmd("Git show " .. sha) end) end
  local stat     = function() with_commit(function(sha) vim.cmd("Git show --stat --summary --format=fuller " .. sha) end) end
  local yank     = function() with_commit(function(sha) vim.fn.setreg("+", sha) vim.notify("Yanked commit " .. sha) end) end

  map("c", checkout, "Checkout commit")
  map("d", diff,     "Diff commit")
  map("f", files,    "Show files in commit")
  map("s", show,     "Show commit")
  map("t", stat,     "Show commit stats")
  map("y", yank,     "Yank sha")
  -- stylua: ignore end

  local close = function()
    if vim.api.nvim_win_is_valid(win_src) then
      -- stylua: ignore
      for opt, val in pairs(saved) do vim.wo[win_src][opt] = val end
    end
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  map('q', close, 'Close blame')
  map('<esc>', close, 'Close blame')

  -- stylua: ignore
  vim.api.nvim_create_autocmd({ "WinLeave", "BufWipeout" }, { buffer = buf, once = true, callback = close })
end

vim.api.nvim_create_autocmd('User', { pattern = 'MiniGitCommandSplit', group = group, callback = blame_cb })

local conflict_ns = vim.api.nvim_create_namespace 'git_conflict'
local conflict_au = vim.api.nvim_create_augroup('git_conflict', {})

-- get_buf_conflicts(buf) -> { { {1,5}, {3,5}, {5,7} }, ... }
--                               ours   base?  theirs
-- 1: <<<<<<< HEAD
-- 2: local a = "main"
-- 3: ||||||| parent of xxxxxxx (xxx)
-- 4: local a = "base"
-- 5: =======
-- 6: local a = "feature"
-- 7: >>>>>>> xxxxxxx (xxx)
--
local function find_conflicts(buf)
  buf = buf or 0
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
  local ours, base, theirs = {}, {}, {}
  local conflicts = {}
  local on_end_mark = function()
    local full = function(val)
      return val[1] and val[2]
    end
    if full(ours) and full(theirs) then
      base = full(base) and base or nil
      table.insert(conflicts, { ours, base, theirs })
      ours, base, theirs = {}, {}, {}
    end
  end
  -- stylua: ignore
  for ln, line in ipairs(lines) do
    if vim.startswith(line, "<<<<<<<") then ours[1] = ln end
    if vim.startswith(line, "|||||||") then base[1] = ln end
    if vim.startswith(line, "=======") then ours[2], base[2], theirs[1] = ln, ln, ln end
    if vim.startswith(line, ">>>>>>>") then theirs[2] = ln; on_end_mark() end
  end
  return conflicts
end

local conflict_state = {}
local function toggle_conflicts(buf)
  buf = buf or 0
  if not vim.api.nvim_buf_is_valid(buf) then
    vim.notify(string.format('Invalid buffer: %d', buf), vim.log.levels.ERROR)
    return
  end
  conflict_state[buf] = not conflict_state[buf]
  if not conflict_state[buf] then
    vim.api.nvim_clear_autocmds { group = conflict_au, buffer = buf }
    vim.api.nvim_buf_clear_namespace(buf, conflict_ns, 0, -1)
    vim.b[buf].minigit_conflicts = nil
  else
    local update = function() ---@diagnostic disable-line: redefined-local
      local conflicts = find_conflicts(buf)
      vim.b[buf].minigit_conflicts = conflicts
      vim.api.nvim_buf_clear_namespace(buf, conflict_ns, 0, -1)
      local hi = function(from, to, hl)
        vim.api.nvim_buf_set_extmark(buf, conflict_ns, from - 1, 0, {
          end_row = to,
          hl_group = hl,
          hl_eol = true,
        })
      end
      for _, conflict in ipairs(conflicts) do
        local ours, base, theirs = unpack(conflict)
        hi(ours[1], ours[2] - 1, 'DiffText')
        hi(theirs[1] + 1, theirs[2], 'DiffAdd')
        if base then
          hi(base[1], base[2] - 1, 'DiffDelete')
        end
      end
    end
    update()
    vim.api.nvim_clear_autocmds { group = conflict_au, buffer = buf }
    vim.api.nvim_create_autocmd('ModeChanged', { pattern = 'i:*', group = conflict_au, callback = update })
    vim.api.nvim_create_autocmd('TextChanged', { group = conflict_au, buffer = buf, callback = update })
  end
end

local conflict_actions = {}
do
  local get_conflict = function()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    for _, conflict in ipairs(vim.b.minigit_conflicts or {}) do
      local ours, _, theirs = unpack(conflict)
      if lnum >= ours[1] and lnum <= theirs[2] then
        return conflict
      end
    end
  end
  local replace_conflict = function(conflict, lines)
    local ours, _, theirs = unpack(conflict)
    vim.api.nvim_buf_set_lines(0, ours[1] - 1, theirs[2], true, lines)
    vim.api.nvim_win_set_cursor(0, { ours[1], 0 })
  end
  local get_lines = function(from, to)
    return vim.api.nvim_buf_get_lines(0, from - 1, to - 1, true)
  end
  local search = function(line, pattern, ...)
    line = type(line) == 'number' and line or vim.fn.line(line)
    local saved_pos = vim.fn.getpos '.'
    vim.fn.cursor(line, 0)
    if vim.fn.search(pattern, ...) == 0 or vim.fn.line '.' == saved_pos[2] then
      vim.fn.cursor(saved_pos[2], saved_pos[3])
    end
  end
  --
  conflict_actions.ours = function()
    local conflict = get_conflict()
    if conflict then
      local ours, base, _ = unpack(conflict)
      local repl = get_lines(ours[1] + 1, base[1] or ours[2])
      replace_conflict(conflict, repl)
    end
  end
  conflict_actions.theirs = function()
    local conflict = get_conflict()
    if conflict then
      local _, _, theirs = unpack(conflict)
      local repl = get_lines(theirs[1] + 1, theirs[2])
      replace_conflict(conflict, repl)
    end
  end
  conflict_actions.both = function()
    local conflict = get_conflict()
    if conflict then
      local ours, base, theirs = unpack(conflict)
      local repl = {}
      vim.list_extend(repl, get_lines(ours[1] + 1, base[1] or ours[2]))
      vim.list_extend(repl, get_lines(theirs[1] + 1, theirs[2]))
      replace_conflict(conflict, repl)
    end
  end
  conflict_actions.none = function()
    local conflict = get_conflict()
    if conflict then
      replace_conflict(conflict, {})
    end
  end
  conflict_actions.forward = function()
    for _ = 1, vim.v.count1 do
      search('.', '^<<<<<<< ')
    end
  end
  conflict_actions.backward = function()
    for _ = 1, vim.v.count1 do
      search('.', '^<<<<<<< ', 'b')
    end
  end
  conflict_actions.last = function()
    search('$', '^<<<<<<< ', 'bW')
  end
  conflict_actions.first = function()
    search(1, '^<<<<<<< ', 'cW')
  end
end

local function minigit_is_merge(buf)
  buf = buf or 0
  local git_summary = vim.b[buf].minigit_summary or {}
  local in_progress = git_summary.in_progress
  return in_progress and (in_progress:find 'merge' or in_progress:find 'rebase')
end

vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniGitUpdated',
  group = conflict_au,
  callback = function(e)
    local buf = e.buf
    if minigit_is_merge(buf) then
      if not vim.b[buf].minigit_conflicts then
        toggle_conflicts(buf)
        vim.keymap.set('n', 'co', conflict_actions.ours, { buffer = buf, desc = 'Checkout ours' })
        vim.keymap.set('n', 'ct', conflict_actions.theirs, { buffer = buf, desc = 'Checkout theirs' })
        vim.keymap.set('n', 'cb', conflict_actions.both, { buffer = buf, desc = 'Checkout both' })
        vim.keymap.set('n', 'c0', conflict_actions.none, { buffer = buf, desc = 'Checkout none' })
        vim.keymap.set('n', ']x', conflict_actions.forward, { buffer = buf, desc = 'Conflict forward' })
        vim.keymap.set('n', '[x', conflict_actions.backward, { buffer = buf, desc = 'Conflict backward' })
        vim.keymap.set('n', ']X', conflict_actions.last, { buffer = buf, desc = 'Conflict last' })
        vim.keymap.set('n', '[X', conflict_actions.first, { buffer = buf, desc = 'Conflict first' })
      end
    else
      if vim.b[buf].minigit_conflicts then
        toggle_conflicts(buf)
        vim.keymap.del('n', 'co', { buffer = buf })
        vim.keymap.del('n', 'ct', { buffer = buf })
        vim.keymap.del('n', 'cb', { buffer = buf })
        vim.keymap.del('n', 'c0', { buffer = buf })
        vim.keymap.del('n', ']x', { buffer = buf })
        vim.keymap.del('n', '[x', { buffer = buf })
        vim.keymap.del('n', ']X', { buffer = buf })
        vim.keymap.del('n', '[X', { buffer = buf })
      end
    end
  end,
})
