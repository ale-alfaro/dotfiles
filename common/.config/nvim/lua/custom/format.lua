-- Minimal format-on-save: sync CLI formatters + LSP fallback
-- Replaces conform.nvim for whole-file, synchronous formatting.

local M = {}

-- Configuration ---------------------------------------------------------------

M.timeout_ms = 1000

---@alias FormatDef { cmd: string, args: string[] }

---@type table<string, FormatDef[]>
M.formatters_by_ft = {
  lua = {
    { cmd = 'stylua', args = { '--search-parent-directories', '--respect-ignores', '--stdin-filepath', '$FILENAME', '-' } },
  },
  sh = {
    { cmd = 'shfmt', args = { '-i', '2', '-ci', '-filename', '$FILENAME' } },
  },
  zsh = {
    { cmd = 'shfmt', args = { '-i', '2', '-ci', '-filename', '$FILENAME' } },
  },
  python = {
    {
      cmd = 'ruff',
      args = { 'check', '--fix', '--force-exclude', '--exit-zero', '--no-cache', '--unsafe-fixes', '--select=I001', '--stdin-filename', '$FILENAME', '-' },
    },
    { cmd = 'ruff', args = { 'format', '--force-exclude', '--stdin-filename', '$FILENAME', '-' } },
  },
}

-- Filetypes where LSP formatting is used exclusively when available
---@type table<string, true>
M.lsp_prefer = {
  c = true,
  cpp = true,
  cmake = true,
  dts = true,
  toml = true,
}

-- Core ------------------------------------------------------------------------

---@param args string[]
---@param filename string
---@return string[]
local function resolve_args(args, filename)
  local resolved = {}
  for _, arg in ipairs(args) do
    resolved[#resolved + 1] = arg == '$FILENAME' and filename or arg
  end
  return resolved
end

---Run a single formatter, returning the formatted text or nil on failure.
---@param formatter FormatDef
---@param text string
---@param filename string
---@return string|nil
local function run_formatter(formatter, text, filename)
  local cmd = vim.list_extend({ formatter.cmd }, resolve_args(formatter.args, filename))
  local result = vim.system(cmd, { stdin = text, text = true }):wait(M.timeout_ms)
  if result.code ~= 0 then
    vim.notify(string.format('[format] %s exited with code %s', formatter.cmd, tostring(result.code)), vim.log.levels.WARN)
    return nil
  end
  return result.stdout
end

---Diff original_lines vs new_lines and apply minimal text edits to the buffer.
---@param bufnr integer
---@param original_lines string[]
---@param new_lines string[]
---@return boolean changed
local function apply_format(bufnr, original_lines, new_lines)
  -- vim.diff doesn't handle EOL changes well with indices result_type.
  -- Appending an empty line to both sides works around this.
  table.insert(original_lines, '')
  table.insert(new_lines, '')
  local original_text = table.concat(original_lines, '\n')
  local new_text = table.concat(new_lines, '\n')
  table.remove(original_lines)
  table.remove(new_lines)

  -- Abort if formatter returned empty output for non-empty input
  if new_text:match '^%s*$' and not original_text:match '^%s*$' then
    vim.notify('[format] Aborting: formatter returned empty output', vim.log.levels.WARN)
    return false
  end

  local indices = vim.text.diff(original_text, new_text, {
    result_type = 'indices',
    algorithm = 'histogram',
  })
  if not indices or #indices == 0 then
    return false
  end

  local line_ending = vim.bo[bufnr].fileformat == 'dos' and '\r\n' or '\n'
  local text_edits = {}

  for _, idx in ipairs(indices) do
    local orig_start, orig_count, new_start, new_count = unpack(idx)
    local is_insert = orig_count == 0
    local is_replace = orig_count > 0 and new_count > 0
    local orig_end = orig_start + orig_count
    local new_end = new_start + new_count
    local replacement = vim.list_slice(new_lines, new_start, new_end - 1)

    if is_replace then
      orig_end = orig_end - 1
    end

    -- Convert to 0-indexed LSP positions
    local start_line = orig_start - 1
    local end_line = orig_end - 1
    local start_char, end_char = 0, 0

    if is_replace then
      -- Trim common prefix on first line
      local orig_first = original_lines[orig_start] or ''
      local repl_first = replacement[1] or ''
      local prefix = 0
      local min_len = math.min(#orig_first, #repl_first)
      for i = 1, min_len do
        if orig_first:byte(i) ~= repl_first:byte(i) then
          break
        end
        prefix = i
      end
      if prefix > 0 then
        start_char = prefix
        replacement[1] = replacement[1]:sub(prefix + 1)
      end

      -- Trim common suffix on last line
      local orig_last = original_lines[orig_end] or ''
      local repl_last = replacement[#replacement] or ''
      local suffix = 0
      local a_len, b_len = #orig_last, #repl_last
      min_len = math.min(a_len, b_len)
      if orig_end == orig_start then
        min_len = math.min(min_len, a_len - start_char)
      end
      for i = 0, min_len - 1 do
        if orig_last:byte(a_len - i) ~= repl_last:byte(b_len - i) then
          break
        end
        suffix = i + 1
      end
      end_char = a_len - suffix
      if suffix > 0 then
        replacement[#replacement] = repl_last:sub(1, b_len - suffix)
      end
    end

    -- Inserts go after the mentioned line
    if is_insert then
      start_line = orig_start
      end_line = orig_start
      -- Append trailing newline for inserts (except at EOF)
      if start_line < #original_lines then
        replacement[#replacement + 1] = ''
      end
    end

    text_edits[#text_edits + 1] = {
      newText = table.concat(replacement, line_ending),
      range = {
        start = { line = start_line, character = start_char },
        ['end'] = { line = end_line, character = end_char },
      },
    }
  end

  pcall(vim.cmd.undojoin)
  vim.lsp.util.apply_text_edits(text_edits, bufnr, 'utf-8')
  return true
end

---@param bufnr integer
local function format_buffer(bufnr)
  local ft = vim.bo[bufnr].filetype

  -- LSP-preferred filetypes: just use the built-in LSP formatter
  if M.lsp_prefer[ft] then
    local clients = vim.lsp.get_clients { bufnr = bufnr, method = 'textDocument/formatting' }
    if #clients > 0 then
      vim.lsp.buf.format { bufnr = bufnr, timeout_ms = M.timeout_ms }
      return
    end
  end

  local formatters = M.formatters_by_ft[ft]
  if not formatters or #formatters == 0 then
    return
  end

  -- Filter to available formatters
  local available = {}
  for _, fmt in ipairs(formatters) do
    if vim.fn.executable(fmt.cmd) == 1 then
      available[#available + 1] = fmt
    end
  end
  if #available == 0 then
    return
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)
  local original_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local eol = vim.bo[bufnr].eol

  -- Build input text (matching vim's EOL behavior)
  local input_lines = vim.list_extend({}, original_lines)
  if eol then
    input_lines[#input_lines + 1] = ''
  end
  local text = table.concat(input_lines, '\n')

  -- Chain formatters: each takes the previous output as input
  for _, fmt in ipairs(available) do
    local output = run_formatter(fmt, text, filename)
    if output then
      text = output
    end
  end

  -- Parse output back to vim lines
  local new_lines = vim.split(text, '\r?\n')
  if eol and new_lines[#new_lines] == '' then
    table.remove(new_lines)
  end
  if #new_lines == 0 then
    new_lines = { '' }
  end

  apply_format(bufnr, original_lines, new_lines)
end

-- Setup -----------------------------------------------------------------------

function M.setup()
  FeatureFlags:add { name = 'Format', gl_enabled = true }

  vim.api.nvim_create_autocmd('BufWritePre', {
    group = vim.api.nvim_create_augroup('CustomFormat', { clear = true }),
    desc = 'Format on save',
    callback = function(args)
      if vim.bo[args.buf].buftype ~= '' then
        return
      end
      if not FeatureFlags:get('Format').gl_enabled then
        return
      end
      format_buffer(args.buf)
    end,
  })
end

return M
