VimRc.format_lines_sync = require('custom.lsp_format').format_lines_sync


---@param a? string
---@param b? string
---@return integer
local function common_prefix_len(a, b)
  if not a or not b then
    return 0
  end
  local min_len = math.min(#a, #b)
  for i = 1, min_len do
    if string.byte(a, i) ~= string.byte(b, i) then
      return i - 1
    end
  end
  return min_len
end

---@param a string
---@param b string
---@return integer
local function common_suffix_len(a, b)
  local a_len = #a
  local b_len = #b
  local min_len = math.min(a_len, b_len)
  for i = 0, min_len - 1 do
    if string.byte(a, a_len - i) ~= string.byte(b, b_len - i) then
      return i
    end
  end
  return min_len
end

local function create_text_edit(
  original_lines,
  replacement,
  is_insert,
  is_replace,
  orig_line_start,
  orig_line_end,
  line_ending
)
  local start_line, end_line = orig_line_start - 1, orig_line_end - 1
  local start_char, end_char = 0, 0
  if is_replace then
    -- If we're replacing text, see if we can avoid replacing the entire line
    start_char = common_prefix_len(original_lines[orig_line_start], replacement[1])
    if start_char > 0 then
      replacement[1] = replacement[1]:sub(start_char + 1)
    end

    if original_lines[orig_line_end] then
      local last_line = replacement[#replacement]
      local suffix = common_suffix_len(original_lines[orig_line_end], last_line)
      -- If we're only replacing one line, make sure the prefix/suffix calculations don't overlap
      if orig_line_end == orig_line_start then
        suffix = math.min(suffix, original_lines[orig_line_end]:len() - start_char)
      end
      end_char = original_lines[orig_line_end]:len() - suffix
      if suffix > 0 then
        replacement[#replacement] = last_line:sub(1, last_line:len() - suffix)
      end
    end
  end
  -- If we're inserting text, make sure the text includes a newline at the end.
  -- The one exception is if we're inserting at the end of the file, in which case the newline is
  -- implicit
  if is_insert and start_line < #original_lines then
    table.insert(replacement, "")
  end
  local new_text = table.concat(replacement, line_ending)

  return {
    newText = new_text,
    range = {
      start = {
        line = start_line,
        character = start_char,
      },
      ["end"] = {
        line = end_line,
        character = end_char,
      },
    },
  }
end
---@param bufnr integer
---@param original_lines string[]
---@param new_lines string[]
---@param range? conform.Range
---@param only_apply_range boolean
---@param dry_run boolean
---@param undojoin boolean
---@return boolean any_changes
local apply_format = function(
  bufnr,
  original_lines,
  new_lines,
  range,
  only_apply_range,
  dry_run,
  undojoin
)
  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  log.trace("Applying formatting to %s", bufname)
  -- The vim.diff algorithm doesn't handle changes in newline-at-end-of-file well. The unified
  -- result_type has some text to indicate that the eol changed, but the indices result_type has no
  -- such indication. To work around this, we just add a trailing newline to the end of both the old
  -- and the new text.
  table.insert(original_lines, "")
  table.insert(new_lines, "")
  local original_text = table.concat(original_lines, "\n")
  local new_text = table.concat(new_lines, "\n")
  table.remove(original_lines)
  table.remove(new_lines)

  -- Abort if output is empty but input is not (i.e. has some non-whitespace characters).
  -- This is to hack around oddly behaving formatters (e.g black outputs nothing for excluded files).
  if new_text:match("^%s*$") and not original_text:match("^%s*$") then
    log.warn("Aborting because a formatter returned empty output for buffer %s", bufname)
    return false
  end

  log.trace("Comparing lines %s and %s", original_lines, new_lines)
  ---@diagnostic disable-next-line: missing-fields
  local indices = vim.text.diff(original_text, new_text, {
    result_type = "indices",
    algorithm = "histogram",
  })
  assert(type(indices) == "table")
  log.trace("Diff indices %s", indices)
  local text_edits = {}
  for _, idx in ipairs(indices) do
    local orig_line_start, orig_line_count, new_line_start, new_line_count = unpack(idx)
    local is_insert = orig_line_count == 0
    local is_delete = new_line_count == 0
    local is_replace = not is_insert and not is_delete
    local orig_line_end = orig_line_start + orig_line_count
    local new_line_end = new_line_start + new_line_count
    local replacement = vim.list_slice(new_lines, new_line_start, new_line_end - 1)

    -- For replacement edits, convert the end line to be inclusive
    if is_replace then
      orig_line_end = orig_line_end - 1
    end

    local should_apply_diff = not only_apply_range
      or not range
      or (is_insert and vim.indices_in_range(range, orig_line_start, orig_line_start + 1))
      or (not is_insert and vim.iter(range, orig_line_start, orig_line_end))

    -- When the diff is an insert, it actually means to insert after the mentioned line
    if is_insert then
      orig_line_start = orig_line_start + 1
      orig_line_end = orig_line_end + 1
    end

    if should_apply_diff then
      local text_edit = create_text_edit(
        original_lines,
        replacement,
        is_insert,
        is_replace,
        orig_line_start,
        orig_line_end,
        util.buf_line_ending(bufnr)
      )
      table.insert(text_edits, text_edit)

      -- If we're using the aftermarket range formatting, diffs often have paired delete/insert
      -- diffs. We should make sure that if one of them overlaps our selected range, extend the
      -- range so that we pick up the other diff as well.
      if range and only_apply_range then
        range = vim.deepcopy(range)
        range["end"][1] = math.max(range["end"][1], orig_line_end + 1)
      end
    end
  end

  if not dry_run then
    log.trace("Applying text edits: %s", text_edits)
    if undojoin then
      -- may fail if after undo
      -- Vim:E790: undojoin is not allowed after undo
      pcall(vim.cmd.undojoin)
    end
    vim.lsp.util.apply_text_edits(text_edits, bufnr, "utf-8")
    log.trace("Done formatting %s", bufname)
  end

  return not vim.tbl_isempty(text_edits)
end

---@param bufnr integer
---@param formatters conform.FormatterInfo[]
---@param timeout_ms integer
---@param range? conform.Range
---@param opts conform.RunOpts
---@return conform.Error? error
---@return boolean did_edit
M.format_sync = function(bufnr, formatters, timeout_ms, range, opts)
  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  local original_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- kill previous jobs for buffer
  local prev_pid = vim.b[bufnr].conform_pid
  if prev_pid and opts.exclusive then
    if vim.uv.kill(prev_pid) == 0 then
      log.info("Canceled previous format job for %s", vim.api.nvim_buf_get_name(bufnr))
    end
  end

  local err, final_result, all_support_range_formatting =
    VimRc.format_lines_sync(bufnr, formatters, timeout_ms, range, original_lines, opts)

  local did_edit = apply_format(
    bufnr,
    original_lines,
    final_result,
    range,
    not all_support_range_formatting,
    opts.dry_run,
    opts.undojoin
  )
  return err, did_edit
end
-- vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
-- require('conform').setup {
--   notify_on_error = false,
--   notify_no_formatters = false,
--   -- toggle autoformatting
--   format_on_save = function(bufnr)
--     -- Disable with a global or buffer-local variable
--     if not FeatureFlags:get 'Format' then
--       return false
--     end
--     return {}
--   end,
--   formatters = {
--     shfmt = {
--       prepend_args = { '-i', '2', '-ci' },
--     },
--     just = {
--       env = {
--         JUST_UNSTABLE = 1,
--       },
--     },
--     ruff_unsafe = {
--       inherit = 'ruff_fix',
--       append_args = {
--         '--unsafe-fixes',
--         '--select=I001',
--       },
--     },
--
--     kconfigstyle = {
--       command = 'kconfigstyle',
--       args = { '--preset', 'zephyr', '-w', '$FILENAME' },
--       stdin = false,
--     },
--
--     prettier = {
--       -- Require a Prettier configuration file to format.
--       prettier = { require_cwd = true },
--     },
--   },
--   formatters_by_ft = {
--     c = { name = 'clang-format', timeout_ms = 500, lsp_format = 'prefer' },
--     -- c = { 'clang-format' }, -- try out uncrustify
--     cpp = { name = 'clangd', timeout_ms = 500, lsp_format = 'prefer' },
--     cmake = { 'gersemi', timeout_ms = 500, lsp_format = 'prefer' },
--     dts = { name = 'devicetree_ls', timeout_ms = 500, lsp_format = 'prefer' },
--     kconfig = { 'kconfigstyle' },
--     lua = { 'stylua' },
--     sh = { 'shfmt' },
--     just = { 'just' },
--     -- # Example of using shfmt with extra args
--     python = {
--       -- To fix auto-fixable lint errors.
--       'ruff_unsafe',
--       -- To run the Ruff formatter.
--       'ruff_format',
--     },
--     zsh = { 'shfmt' },
--     markdown = { 'prettier' },
--     toml = { 'taplo', lsp_format = 'prefer' },
--     json = { 'prettier' },
--     jsonc = { 'prettier' },
--     yaml = { 'prettier' },
--     typst = { 'typstyle' },
--     javascript = { 'prettier', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
--     javascriptreact = { 'prettier', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
--     scss = { 'prettier' },
--     typescript = { 'prettier', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
--     typescriptreact = { 'prettier', name = 'dprint', timeout_ms = 500, lsp_format = 'fallback' },
--     ['_'] = { 'trim_whitespace', 'trim_newlines' },
--   },
-- }
--
-- vim.api.nvim_create_user_command('Format', function(args)
--   local range = nil
--   if args.count ~= -1 then
--     local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
--     range = {
--       start = { args.line1, 0 },
--       ['end'] = { args.line2, end_line:len() },
--     }
--   end
--   require('conform').format { async = true, lsp_format = 'fallback', range = range }
-- end, { range = true })
