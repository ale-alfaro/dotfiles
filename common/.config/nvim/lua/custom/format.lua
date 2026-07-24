-- Minimal format-on-save: CLI formatters + LSP fallback.
---@class Fmt
---@field config table
---@field setup fun()
---@field format fun(bufnr:integer)
local Fmt = {}
local H = {}
local uv = vim.uv
---
---A text edit applicable to a text document.
---@alias FormatTextEdit lsp.TextEdit
---
---A text edit applicable to a text document.
---@class FormatLine : lsp.Position
---@field content string Content of lien

---@alias FormatList fmt.JobFormatterConfig|fmt.JobFormatterConfig[]
local prettier = { command = 'prettier', args = { '--stdin-filepath', '$FILENAME' }, mise_tool = 'npm:prettier' }
local dprint = {
  command = 'dprint',
  args = { 'fmt', '--stdin', '$FILENAME' },
  envs = { DPRINT_CONFIG_DIR = vim.fn.expand '~/.config/dprint', DPRINT_CONFIG_DISCOVERY = 'global' },
}
local shfmt = { command = 'shfmt', args = { '-i', '2', '-ci', '-filename', '$FILENAME' } }
local ruff = {
  command = 'ruff',
  args = { 'check', '--fix', '--force-exclude', '--exit-zero', '--no-cache', '--unsafe-fixes', '--select=I001', '--stdin-filename', '$FILENAME', '-' },
}
local stylua = { command = 'stylua', args = { '--stdin-filepath', '$FILENAME', '-' } }
local clang_format = { command = 'clang-format', args = {} }
local kconfigsyle = { command = 'kconfigstyle', args = { '-z', 'zephyr', '-w', '$FILENAME' } , no_stdin = true}

-- local dtslinter = { cmd = 'dts-linter', args = { '--formatFixAll', '--file', '$FILENAME' }, mise_tool = 'npm:dts-linter' }

Fmt.config = {
  timeout_ms = 1000,
  ---@type table<string, FormatList>
  formatters_by_ft = {
    c = clang_format,
    cpp = clang_format,
    cmake = { cmd = 'uvx', args = { 'gersemi', '-' } },
    css = prettier,
    -- dts = dtslinter,
    html = dprint,
    kconfig = kconfigsyle,
    javascript = dprint,
    json = dprint,
    jsonc = dprint,
    lua = stylua,
    markdown = dprint,
    sh = shfmt,
    python = ruff,
    rust = { cmd = 'rustfmt', args = { '$FILENAME' } },
    typescript = dprint,
    yaml = dprint,
    zsh = shfmt,
  },

  -- Filetypes that use LSP formatting exclusively when a client is attached.
  ---@type table<string, true>
  lsp_prefer = {
    dts = true,
    rust = true,
    toml = true,
  },
}

function Fmt.setup()
  vim.g.autoformat = true
  _G.Fmt = Fmt
  local aug = vim.api.nvim_create_augroup('CustomFormat', { clear = true })
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = aug,
    desc = 'Format on save',
    callback = function(ev)
      if vim.g.minifiles_active then
        return
      end
      if vim.g.skip_formatting then
        vim.g.skip_formatting = false
        return
      end

      if not vim.g.autoformat then
        return
      end
      Fmt.format(ev.buf)
    end,
  })
end

Fmt.format = function(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype

  -- vim.b[] returns nil for unset vars; nvim_buf_get_var would throw.
  local buf_lsp_format = vim.b[bufnr].lspformat
  if (Fmt.config.lsp_prefer[ft] ~= nil) and (buf_lsp_format ~= nil and buf_lsp_format == 1) then
    vim.lsp.buf.format { async = false }
  else
    local formatter = Fmt.config.formatters_by_ft[ft]
    if not formatter then
      VimRc.warn('No formatters for ft=' .. ft)
      return
    end

    if formatter.no_stdout then
      H.with_preserved_view('!' .. formatter.cmd)
    else
      local input_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
      local done = false
      local result = nil
      local start = uv.hrtime() / 1e6
      local pid = require('custom.docgen').run_formatter(bufnr, ft, formatter, input_lines, function(output)
        done = true
        result = output
      end)
      local remaining = Fmt.config.timeout_ms - (uv.hrtime() / 1e6 - start)
      local wait_result, wait_reason = vim.wait(remaining, function()
        return done
      end, 5)
      if not wait_result then
        if pid then
          uv.kill(pid)
        end
        if wait_reason == -1 then
          VimRc.err {
            message = string.format("Formatter '%s' timeout", formatter.name),
          }
        else
          VimRc.err {
            message = string.format("Formatter '%s' was interrupted", formatter.name),
          }
        end
        return
      end
      require('custom.docgen').apply_format(bufnr, input_lines, result or input_lines)
      -- Fmt.format_range(formatter, bufnr)
    end
  end
end

Fmt.formatexpr = function(opts)
  -- Use the same defaults as conform.format(), but force async = false and handle the range
  opts = vim.tbl_deep_extend('keep', opts or {}, {
    bufnr = vim.api.nvim_get_current_buf(),
  })
  -- Force async = false
  opts.async = false
  if vim.tbl_contains({ 'i', 'R', 'ic', 'ix' }, vim.fn.mode()) then
    -- `formatexpr` is also called when exceeding `textwidth` in insert mode
    -- fall back to internal formatting
    return 1
  end

  local start_lnum = vim.v.lnum
  local end_lnum = start_lnum + vim.v.count - 1

  if start_lnum <= 0 or end_lnum <= 0 then
    return 0
  end
  local end_line = vim.fn.getline(end_lnum)
  local end_col = end_line:len()

  if vim.v.count == vim.fn.line '$' then
    -- Whole buffer is selected; use buffer formatting
    opts.range = nil
  else
    opts.range = {
      start = { start_lnum, 0 },
      ['end'] = { end_lnum, end_col },
    }
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype

  local fmt = Fmt.config.formatters_by_ft[ft]
  if not fmt then
    VimRc.warn('No formatters for ft=' .. ft)
    return
  end
  Fmt.format_range(fmt, bufnr)
  return 0
end

--- Fallback formatter
---@param bufnr integer buffer id
Fmt.trim_and_compact = function(bufnr)
  local fmt_fn = function(lines, cursor_line)
    cursor_line = cursor_line or 0
    local cleaned = {}
    local excess_blank_lines = 0
    local blank_consecutive_inc = 0

    -- Remove consecutive blank lines
    for i, line in ipairs(lines) do
      local is_blank = line:match '^%s*$' ~= nil

      if is_blank then
        blank_consecutive_inc = blank_consecutive_inc + 1 -- increment
      else
        blank_consecutive_inc = 0 -- Restart
        if blank_consecutive_inc >= 2 and i <= cursor_line then
          excess_blank_lines = excess_blank_lines + (blank_consecutive_inc - 1) -- How many blank lines we have removed before cursor line
        end
      end

      if not is_blank or (is_blank and blank_consecutive_inc == 1) then
        table.insert(cleaned, is_blank and '' or line)
      end
    end
    -- Remove trailing blank lines
    for i = #cleaned, 1, -1 do
      if cleaned[i]:match '^%s*$' then
        table.remove(cleaned, i)
      else
        break
      end
    end
    --- Restore the cursor position with the adjustment done for lines removed before the cursor lne
    if excess_blank_lines > 0 then
      local final_line = math.max(1, cursor_line - excess_blank_lines)
      final_line = math.min(final_line, #cleaned)
      return cleaned, final_line
    end
    return cleaned, cursor_line
  end
  H.buffer_text_format_with_preserved_view(bufnr, fmt_fn)
end

H.with_preserved_view = function(op)
  local view = vim.fn.winsaveview()
  local ok, err = pcall(function()
    if type(op) == 'function' then
      op()
    else
      vim.cmd(('keepjumps keeppatterns %s'):format(op))
    end
  end)
  vim.fn.winrestview(view)
  if not ok then
    VimRc.err('[with_preserved_view]: ' .. (err or 'Unknown error'), vim.log.levels.ERROR)
  end
end
--- Modify buffer content while preserving window and cursor state
---@param bufnr integer buffer id
---@param op fun(lines:string[],cursor_l?:integer):string[],integer
H.buffer_text_format_with_preserved_view = function(bufnr, op)
  bufnr = bufnr or 0
  if vim.bo[bufnr].binary or vim.bo[bufnr].filetype == 'diff' then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  H.with_preserved_view(function()
    -- win_get/set_cursor take a WINDOW id, not a buffer id. Use the current
    -- window (0); on BufWritePre that is the window showing `bufnr`.
    local cursor_l, cursor_c = unpack(vim.api.nvim_win_get_cursor(0))
    local modified_l, mod_cursor_l = op(lines, cursor_l)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, modified_l)
    -- Clamp so the target line is always valid after edits.
    mod_cursor_l = math.max(1, math.min(mod_cursor_l or cursor_l, #modified_l))
    vim.api.nvim_win_set_cursor(0, { mod_cursor_l, cursor_c })
  end)
end
---Run formatter on a range
---@param fmt FormatDef  Formatter definition
---@param bufnr integer  buffer id
---@param start_pos? [integer,integer] Tuple of start position
---@param end_pos? [integer,integer] Tuple of end position
function Fmt.format_range(fmt, bufnr, start_pos, end_pos)
  local start_l, _ = start_pos ~= nil and unpack(start_pos) or 0, 0
  local end_l, _ = end_pos ~= nil and unpack(end_pos) or -1, -1
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_l, end_l, true)
  if #lines == 0 or lines[1] == '' then
    VimRc.warn 'File lines are empty'
    return
  end
  local original = table.concat(lines, '\n') .. (vim.bo[bufnr].eol and '\n' or '')
  local modified = H.run_formatter(fmt, bufnr, original)
  if not modified then
    VimRc.err 'Failed to run formatter'
    return
  end
  H.apply_diff(original, modified, bufnr)
end

-- ---@param fmt FormatDef  Formatter definition
-- ---@param bufnr integer  buffer id
-- ---@param original string? buffer content
-- ---@return string? modified
-- H.run_formatter = function(fmt, bufnr, original)
--   local exe = vim.fn.exepath(fmt.cmd)
--   if exe == '' and not fmt.mise_tool then
--     VimRc.warn('Formatter %s not found in path!', fmt.cmd)
--   end
--   ---@type string[]
--   local cmd = H.expand_args(fmt.args, bufnr)
--   table.insert(cmd, 1, fmt.cmd)
--   if not exe then
--     cmd = vim.list_extend({ 'mise', 'exec', vim.fn.shellescape(fmt.mise_tool), '--' }, cmd)
--   end
--   local opts = (original ~= nil) and { stdin = original, envs = fmt.envs } or { envs = fmt.envs }
--   local ret, modified = H.run(cmd, opts)
--   if not ret then
--     VimRc.warn('[format] error while formatting. stderr' .. modified)
--     return
--   elseif modified:match '^%s*$' then
--     VimRc.warn '[format] empty output, format did not run'
--     return
--   end
--   return modified
-- end

---Apply a formatter's output to the buffer by replacing only the changed line
---ranges, so cursor, marks, folds and undo granularity survive.
---@param original string original buffer text
---@param modified string formatted text
---@param bufnr integer buffer number
H.apply_diff = function(original, modified, bufnr)
  local hunks = vim.text.diff(original, modified, { result_type = 'indices' })
  if type(hunks) ~= 'table' then
    return
  end
  local new_lines = vim.split(modified, '\n', { plain = true })
  -- Apply bottom-up so earlier line numbers stay valid as the buffer mutates.
  for i = #hunks, 1, -1 do
    local h = hunks[i]
    local start_a, count_a, start_b, count_b = h[1], h[2], h[3], h[4]
    -- count_a == 0 is a pure insert *after* line start_a; else replace from start_a.
    local first = (count_a == 0) and start_a or (start_a - 1) -- 0-based, inclusive
    local last = first + count_a -- 0-based, exclusive
    local repl = {}
    for j = start_b, start_b + count_b - 1 do
      repl[#repl + 1] = new_lines[j]
    end
    vim.api.nvim_buf_set_lines(bufnr, first, last, true, repl)
  end
end
---Substitute well-known placeholders in a formatter's argv.
---@param args string[]
---@param bufnr integer
---@return string[]
function H.expand_args(args, bufnr)
  local filename = vim.api.nvim_buf_get_name(bufnr)
  return vim
    .iter(args)
    :map(function(a)
      if a == '$FILENAME' then
        return vim.fn.shellescape(filename)
      end
      return a
    end)
    :totable()
end

---Run one formatter: pipe `text` to stdin, return stdout or nil on failure.
---@param cmd string[]
---@param opts {stdin:string?,envs:table<string, string>?}?
---@return boolean,string
function H.run(cmd, opts)
  opts = vim.tbl_extend('force', { text = true }, opts or {})
  local result = vim.system(cmd, opts):wait(Fmt.config.timeout_ms)
  if result.code ~= 0 then
    VimRc.warn('[format] Failed to run format cmd: ', { cmd = cmd, opts = opts })
    VimRc.warn(string.format('[format] %s failed (%s): %s', cmd, result.code, result.stderr or ''))
    return false, result.stderr
  end
  return true, result.stdout
end
return Fmt
