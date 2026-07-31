local M = {}

local uv = vim.uv

---@class (exact) fmt.FormatterInfo
---@field name string
---@field command string
---@field cwd? string
---
---@class (exact) fmt.JobFormatterConfig
---@field command string|fun(self: fmt.JobFormatterConfig, ctx: fmt.Context): string
---@field args? string|string[]|fun(self: fmt.JobFormatterConfig, ctx: fmt.Context): string|string[]
---@field range_args? fun(self: fmt.JobFormatterConfig, ctx: fmt.RangeContext): string|string[]
---@field cwd? fun(self: fmt.JobFormatterConfig, ctx: fmt.Context): nil|string
---@field require_cwd? boolean When cwd is not found, don't run the formatter (default false)
---@field no_stdin? boolean Send buffer contents to stdin (default false)
---@field tmpfile_format? string When stdin=false, use this format for temporary files (default ".fmt.$RANDOM.$FILENAME")
---@field env? table<string, any>|fun(self: fmt.JobFormatterConfig, ctx: fmt.Context): table<string, any>
---@field lsp_prefer? boolean
---@field post? boolean
---
---@class (exact) fmt.LuaFormatterConfig
---@field format fun(self: fmt.LuaFormatterConfig, ctx: fmt.Context, lines: string[], callback: fun(err: nil|string, new_lines: nil|string[]))
---@field condition? fun(self: fmt.LuaFormatterConfig, ctx: fmt.Context): boolean
---@field options? table

---@class (exact) fmt.FileLuaFormatterConfig : fmt.LuaFormatterConfig
---@field meta fmt.FormatterMeta

---@class (exact) fmt.FileFormatterConfig : fmt.JobFormatterConfig
---@field meta fmt.FormatterMeta

---@alias fmt.FormatterConfig fmt.JobFormatterConfig|fmt.LuaFormatterConfig
---

---@class (exact) fmt.Context
---@field buf integer
---@field filename string
---@field dirname string
---@field range? fmt.Range
---@field shiftwidth integer
---
---@class (exact) fmt.RangeContext : fmt.Context
---@field range fmt.Range
---
---@class (exact) fmt.Range
---@field start integer[]
---@field end integer[]
---

local ft_to_ext = {
  elixir = 'ex',
  graphql = 'gql',
  javascript = 'js',
  javascriptreact = 'jsx',
  markdown = 'md',
  perl = 'pl',
  python = 'py',
  ruby = 'rb',
  rust = 'rs',
  typescript = 'ts',
  typescriptreact = 'tsx',
}
---@generic T : fun()
---@param cb T
---@param wrapper T
---@return T
local wrap_callback = function(cb, wrapper)
  return function(...)
    wrapper(...)
    cb(...)
  end
end
---@param output? string[]
---@return boolean
local function is_empty_output(output)
  return not output or vim.tbl_isempty(output) or (#output == 1 and output[1] == '')
end

---Ensure that all parent directories of a path exist
---@param path string
local dir_ensure_parent = function(path)
  local current_parent_dir = vim.fs.dirname(path)
  -- Keep track of the current parent directories created, so we can delete them later
  while current_parent_dir and not uv.fs_stat(current_parent_dir) do
    table.insert(M._dirs, current_parent_dir)
    current_parent_dir = vim.fs.dirname(current_parent_dir)
  end
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
end

---Clean up temporary directories
local dir_cleanup = function()
  -- Before cleanup we make sure to order the deepest paths first
  table.sort(M._dirs, function(a, b)
    return a:len() > b:len()
  end)
  local temp_dir_idx = 1
  while temp_dir_idx <= #M._dirs do
    local temp_dir_to_remove = M._dirs[temp_dir_idx]
    VimRc.debug('Cleaning up temp dir %s', temp_dir_to_remove)
    local success, err_name, err_msg = uv.fs_rmdir(temp_dir_to_remove)
    if not success then
      VimRc.warn('Failed to remove temp directory %s: %s: %s', temp_dir_to_remove, err_name, err_msg)
      temp_dir_idx = temp_dir_idx + 1
    else
      table.remove(M._dirs, temp_dir_idx)
    end
  end
end
---@param ctx fmt.Context
---@param config fmt.JobFormatterConfig
---@return string[]
M.build_cmd = function(ctx, config)
  local command = config.command
  if type(command) == 'function' then
    command = command(config, ctx)
  end
  local exepath = vim.fn.exepath(command)
  if exepath ~= '' then
    command = exepath
  end
  ---@type string|string[]
  local args = {}
  if ctx.range and config.range_args then
    ---@cast ctx fmt.RangeContext
    args = config.range_args(config, ctx)
  elseif config.args then
    local computed_args = config.args
    if type(computed_args) == 'function' then
      args = computed_args(config, ctx)
    elseif computed_args then
      args = computed_args
    end
  end

  local function compute_relative_filepath()
    local cwd
    if config.cwd then
      cwd = config.cwd(config, ctx)
    end
    return vim.fs.relpath(cwd or vim.fn.getcwd(), ctx.filename) or ctx.filename
  end

  if type(args) == 'string' then
    local interpolated = args
      :gsub('$FILENAME', ctx.filename)
      :gsub('$DIRNAME', ctx.dirname)
      :gsub('$RELATIVE_FILEPATH', compute_relative_filepath)
      :gsub('$EXTENSION', ctx.filename:match '.*(%..*)$' or '')
    return VimRc.shell_build_argv(command .. ' ' .. interpolated)
  else
    local cmd = { command }
    for _, v in ipairs(args) do
      if v == '$FILENAME' then
        v = ctx.filename
      elseif v == '$DIRNAME' then
        v = ctx.dirname
      elseif v == '$RELATIVE_FILEPATH' then
        v = compute_relative_filepath()
      elseif v == '$EXTENSION' then
        v = ctx.filename:match '.*(%..*)$' or ''
      end
      table.insert(cmd, v)
    end
    return cmd
  end
end

---@param bufnr integer
---@return string
local buf_line_ending = function(bufnr)
  local fileformat = vim.bo[bufnr].fileformat
  if fileformat == 'dos' then
    return '\r\n'
  elseif fileformat == 'mac' then
    return '\r'
  else
    return '\n'
  end
end
---@param range fmt.Range
---@param start_a integer
---@param end_a integer
---@return boolean
local function indices_in_range(range, start_a, end_a)
  return start_a <= range['end'][1] and range['start'][1] <= end_a
end

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

local function create_text_edit(original_lines, replacement, is_insert, is_replace, orig_line_start, orig_line_end, line_ending)
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
    table.insert(replacement, '')
  end
  local new_text = table.concat(replacement, line_ending)

  return {
    newText = new_text,
    range = {
      start = {
        line = start_line,
        character = start_char,
      },
      ['end'] = {
        line = end_line,
        character = end_char,
      },
    },
  }
end

---@param bufnr integer
---@param original_lines string[]
---@param new_lines string[]
---@return boolean any_changes
M.apply_format = function(bufnr, original_lines, new_lines)
  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  VimRc.debug('Applying formatting to %s', bufname)
  -- The vim.text.diff algorithm doesn't handle changes in newline-at-end-of-file well. The unified
  -- result_type has some text to indicate that the eol changed, but the indices result_type has no
  -- such indication. To work around this, we just add a trailing newline to the end of both the old
  -- and the new text.
  table.insert(original_lines, '')
  table.insert(new_lines, '')
  local original_text = table.concat(original_lines, '\n')
  local new_text = table.concat(new_lines, '\n')
  table.remove(original_lines)
  table.remove(new_lines)

  -- Abort if output is empty but input is not (i.e. has some non-whitespace characters).
  -- This is to hack around oddly behaving formatters (e.g black outputs nothing for excluded files).
  if new_text:match '^%s*$' and not original_text:match '^%s*$' then
    VimRc.warn('Aborting because a formatter returned empty output for buffer %s', bufname)
    return false
  end

  VimRc.debug('Comparing lines %s and %s', original_lines, new_lines)
  local indices
  if vim.fn.has 'nvim-0.12' == 1 then
    indices = vim.text.diff(original_text, new_text, {
      result_type = 'indices',
      algorithm = 'histogram',
    })
  else
    ---@diagnostic disable-next-line: deprecated
    indices = vim.diff(original_text, new_text, {
      result_type = 'indices',
      algorithm = 'histogram',
    })
  end
  assert(type(indices) == 'table')
  VimRc.debug('Diff indices %s', indices)
  local text_edits = {}
  for _, idx in ipairs(indices) do
    local orig_line_start, orig_line_count, new_line_start, new_line_count = unpack(idx)
    local is_insert = orig_line_count == 0
    local is_delete = new_line_count == 0
    local is_replace = not is_insert and not is_delete
    local orig_line_end = orig_line_start + orig_line_count
    local new_line_end = new_line_start + new_line_count
    local replacement = VimRc.tbl_slice(new_lines, new_line_start, new_line_end - 1)

    -- For replacement edits, convert the end line to be inclusive
    if is_replace then
      orig_line_end = orig_line_end - 1
    end

    -- When the diff is an insert, it actually means to insert after the mentioned line
    if is_insert then
      orig_line_start = orig_line_start + 1
      orig_line_end = orig_line_end + 1
    end

    local text_edit = create_text_edit(original_lines, replacement, is_insert, is_replace, orig_line_start, orig_line_end, buf_line_ending(bufnr))
    table.insert(text_edits, text_edit)

    -- If we're using the aftermarket range formatting, diffs often have paired delete/insert
    -- diffs. We should make sure that if one of them overlaps our selected range, extend the
    -- range so that we pick up the other diff as well.
  end

  VimRc.debug('Applying text edits: %s', text_edits)
  -- if undojoin then
  --   -- may fail if after undo
  --   -- Vim:E790: undojoin is not allowed after undo
  --   pcall(vim.cmd.undojoin)
  -- end
  vim.lsp.util.apply_text_edits(text_edits, bufnr, 'utf-8')
  VimRc.debug('Done formatting %s', bufname)

  return not vim.tbl_isempty(text_edits)
end

---@param bufnr integer
---@param config fmt.FormatterConfig
---@param range? fmt.Range
---@return fmt.Context
local build_context = function(bufnr, config, range)
  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  local filename = vim.api.nvim_buf_get_name(bufnr)

  local shiftwidth = vim.bo[bufnr].shiftwidth
  if shiftwidth == 0 then
    shiftwidth = vim.bo[bufnr].tabstop
  end

  -- Hack around checkhealth. For buffers that are not files, we need to fabricate a filename
  if vim.bo[bufnr].buftype ~= '' then
    filename = ''
  end
  local dirname
  if filename == '' then
    dirname = vim.fn.getcwd()
    filename = vim.fs.joinpath(dirname, 'unnamed_temp')
    local ft = vim.bo[bufnr].filetype
    if ft and ft ~= '' then
      filename = filename .. '.' .. (ft_to_ext[ft] or ft)
    end
  else
    dirname = vim.fs.dirname(filename)
  end

  if config.no_stdin then
    local template = config.tmpfile_format
    if not template then
      template = '.fmt.$RANDOM.$FILENAME'
    end
    local basename = vim.fs.basename(filename)
    local tmpname = template:gsub('$RANDOM', tostring(math.random(1000000, 9999999))):gsub('$FILENAME', basename)
    filename = vim.fs.normalize(tmpname)
  end
  return {
    buf = bufnr,
    filename = filename,
    dirname = dirname,
    range = range,
    shiftwidth = shiftwidth,
  }
end
---@param bufnr integer
---@param fmt_name string
---@param config fmt.FormatterConfig
---@param input_lines string[]
---@param callback fun(output?:string[])
---@return integer? job_id
M.run_formatter = function(bufnr, fmt_name, config, input_lines, callback)
  local ctx = build_context(bufnr, config, nil)

  ---@cast config fmt.JobFormatterConfig
  local cmd = M.build_cmd(ctx, config)
  local cwd = nil
  if config.cwd then
    cwd = config.cwd(config, ctx)
  end
  local env = config.env
  if type(env) == 'function' then
    env = env(config, ctx)
  end

  local buffer_text
  -- If the buffer has a newline at the end, make sure we include that in the input to the formatter
  local add_extra_newline = vim.bo[bufnr].eol
  if add_extra_newline then
    table.insert(input_lines, '')
  end
  buffer_text = table.concat(input_lines, '\n')
  if add_extra_newline then
    table.remove(input_lines)
  end

  if config.no_stdin then
    VimRc.debug('Creating temp file %s', ctx.filename)
    dir_ensure_parent(ctx.filename)
    local fd = assert(uv.fs_open(ctx.filename, 'w', 448)) -- 0700
    uv.fs_write(fd, buffer_text)
    uv.fs_close(fd)
  end

  VimRc.debug('Run command: %s', cmd)
  if cwd then
    VimRc.debug('Run CWD: %s', cwd)
  else
    VimRc.debug('Run default CWD: %s', vim.fn.getcwd())
  end
  if env then
    VimRc.debug('Run ENV: %s', env)
  end
  local exit_codes = { 0 }
  local pid
  local ok, job_or_err = pcall(
    vim.system,
    cmd,
    {
      cwd = cwd,
      env = env,
      stdin = config.no_stdin and nil or buffer_text,
      text = true,
    },
    vim.schedule_wrap(function(result)
      local code = result.code
      local stdout = result.stdout and vim.split(result.stdout, '\r?\n') or {}
      local stderr = result.stderr and vim.split(result.stderr, '\r?\n') or {}
      if vim.tbl_contains(exit_codes, code) then
        local output = stdout
        if config.no_stdin then
          local fd = assert(uv.fs_open(ctx.filename, 'r', 448)) -- 0700
          local stat = assert(uv.fs_fstat(fd))
          local content = assert(uv.fs_read(fd, stat.size))
          uv.fs_close(fd)
          output = vim.split(content, '\r?\n')
        end
        -- Remove the trailing newline from the output to convert back to vim lines representation
        if add_extra_newline and output[#output] == '' then
          table.remove(output)
        end
        -- Vim will never let the lines array be empty. An empty file will still look like { "" }
        if #output == 0 then
          table.insert(output, '')
        end
        VimRc.debug('%s exited with code %d', fmt_name, code)
        VimRc.debug('Output lines: %s', output)
        VimRc.debug('%s stderr: %s', fmt_name, stderr)
        callback(output)
      else
        VimRc.info('%s exited with code %d', fmt_name, code)
        VimRc.debug('%s stdout: %s', fmt_name, stdout)
        VimRc.debug('%s stderr: %s', fmt_name, stderr)
        local err_str
        if not is_empty_output(stderr) then
          err_str = table.concat(stderr, '\n')
        elseif not is_empty_output(stdout) then
          err_str = table.concat(stdout, '\n')
        else
          err_str = 'unknown error'
        end
        if vim.api.nvim_buf_is_valid(bufnr) and pid ~= vim.b[bufnr].fmt_pid then
          VimRc.err {
            message = string.format("Formatter '%s' was interrupted", fmt_name),
          }
        else
          VimRc.err {
            message = string.format("Formatter '%s' error: %s", fmt_name, err_str),
          }
        end
        callback(nil)
      end
        if config.no_stdin then
          VimRc.debug('Cleaning up temp file %s', ctx.filename)
          uv.fs_unlink(ctx.filename)
          dir_cleanup()
        end
    end)
  )
  if not ok then
    VimRc.err {
      message = string.format("Formatter '%s' error in vim.system: %s", fmt_name, job_or_err),
    }
    return
  end
  pid = job_or_err.pid
  return pid
end

return M
