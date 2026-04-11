local M = {}

local errors = require 'conform.errors'
local dir_manager = require 'conform.dir_manager'
local uv = vim.uv or vim.loop
local log = {
  debug = function(...)
    VimRc.info(..., 'DEBUG')
  end,
  warn = VimRc.warn,
  info = VimRc.print,
  error = VimRc.err,
}
---@param output? string[]
---@return boolean
local function is_empty_output(output)
  return not output or vim.tbl_isempty(output) or (#output == 1 and output[1] == '')
end

---@param value any
---@return boolean
local function truthy(value)
  return value ~= nil and value ~= false
end
local util = require 'vim.lsp.util'

local function apply_text_edits(text_edits, bufnr, offset_encoding, dry_run, undojoin)
  if
    #text_edits == 1
    and text_edits[1].range.start.line == 0
    and text_edits[1].range.start.character == 0
    and text_edits[1].range['end'].line >= vim.api.nvim_buf_line_count(bufnr)
    and text_edits[1].range['end'].character == 0
  then
    local original_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
    local new_lines = vim.split(text_edits[1].newText, '\r?\n', {})
    -- If it had a trailing newline, remove it to make the lines match the expected vim format
    if #new_lines > 1 and new_lines[#new_lines] == '' then
      table.remove(new_lines)
    end
    log.debug 'Converting full-file LSP format to piecewise format'
    return require('conform.runner').apply_format(bufnr, original_lines, new_lines, nil, false, dry_run, undojoin)
  elseif dry_run then
    return #text_edits > 0
  else
    if undojoin then
      pcall(vim.cmd.undojoin)
    end
    vim.lsp.util.apply_text_edits(text_edits, bufnr, offset_encoding)
    return #text_edits > 0
  end
end

---@param options table
---@return table[] clients
function M.get_format_clients(options)
  local method = options.range and 'textDocument/rangeFormatting' or 'textDocument/formatting'

  local clients
  if vim.lsp.get_clients then
    clients = vim.lsp.get_clients {
      id = options.id,
      bufnr = options.bufnr,
      name = options.name,
      method = method,
    }
  else
    ---@diagnostic disable-next-line: deprecated
    clients = vim.lsp.get_active_clients {
      id = options.id,
      bufnr = options.bufnr,
      name = options.name,
    }

    clients = vim.tbl_filter(function(client)
      return client.supports_method(method, { bufnr = options.bufnr })
    end, clients)
  end
  if options.filter then
    clients = vim.tbl_filter(options.filter, clients)
  end
  return clients
end

---@param options conform.FormatOpts
---@param callback fun(err?: string, did_edit?: boolean)
function M.format(options, callback)
  options = options or {}
  local bufnr = options.bufnr
  if not bufnr or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
    options.bufnr = bufnr
  end
  local range = options.range
  local method = range and 'textDocument/rangeFormatting' or 'textDocument/formatting'

  local clients = M.get_format_clients(options)

  if #clients == 0 then
    return callback '[LSP] Format request failed, no matching language servers.'
  end

  local function set_range(client, params)
    if range then
      local range_params = util.make_given_range_params(range.start, range['end'], bufnr, client.offset_encoding)
      params.range = range_params.range
    end
    return params
  end

  if options.async then
    local changedtick = vim.b[bufnr].changedtick
    local do_format
    local did_edit = false
    do_format = function(idx, client)
      if not client then
        return callback(nil, did_edit)
      end
      --- @diagnostic disable-next-line: param-type-mismatch
      local params = set_range(client, util.make_formatting_params(options.formatting_options))
      local auto_id = vim.api.nvim_create_autocmd('LspDetach', {
        buffer = bufnr,
        callback = function(args)
          if args.data.client_id == client.id then
            log.warn(string.format('LSP %s detached during format request', client.name))
            callback 'LSP detached'
          end
        end,
      })
      local request = function(c, ...)
        return c:request(...)
      end
      request(client, method, params, function(err, result, ctx, _)
        vim.api.nvim_del_autocmd(auto_id)
        if not result then
          return callback(err or 'No result returned from LSP formatter')
        elseif not vim.api.nvim_buf_is_valid(bufnr) then
          return callback 'buffer was deleted'
        elseif changedtick ~= require('conform.util').buf_get_changedtick(bufnr) then
          return callback(string.format('Async LSP formatter discarding changes for %s: concurrent modification', vim.api.nvim_buf_get_name(bufnr)))
        else
          local this_did_edit = apply_text_edits(result, ctx.bufnr, client.offset_encoding, options.dry_run, options.undojoin)
          changedtick = vim.b[bufnr].changedtick

          if options.dry_run and this_did_edit then
            callback(nil, true)
          else
            did_edit = did_edit or this_did_edit
            do_format(next(clients, idx))
          end
        end
      end, bufnr)
    end
    do_format(next(clients))
  else
    local timeout_ms = options.timeout_ms or 1000
    local did_edit = false
    local request_sync = function(c, ...)
      return c:request_sync(...)
    end
    for _, client in pairs(clients) do
      --- @diagnostic disable-next-line: param-type-mismatch
      local params = set_range(client, util.make_formatting_params(options.formatting_options))
      local result, wait_error = request_sync(client, method, params, timeout_ms, bufnr)
      local lsp_error = (result and result.err) or wait_error
      if result and result.result then
        local this_did_edit = apply_text_edits(result.result, bufnr, client.offset_encoding, options.dry_run, options.undojoin)
        did_edit = did_edit or this_did_edit

        if options.dry_run and did_edit then
          callback(nil, true)
          return true
        end
      elseif lsp_error then
        if not options.quiet then
          log.warn(string.format('[LSP][%s] %s', client.name, lsp_error))
        end
        return callback(string.format('[LSP][%s] %s', client.name, lsp_error))
      end
    end
    callback(nil, did_edit)
  end
end

---Map of formatter name to if the last run of that formatter produced an error
---@type table<string, boolean>
local last_run_errored = {}
---@param bufnr integer
---@param formatter conform.FormatterInfo
---@param config conform.FormatterConfig
---@param ctx conform.Context
---@param input_lines string[]
---@param opts conform.RunOpts
---@param callback fun(err?: conform.Error, output?: string[])
---@return integer? job_id
local run_formatter = function(bufnr, formatter, config, ctx, input_lines, opts, callback)
  local autocmd_data = {
    formatter = {
      name = formatter.name,
    },
  }
  vim.api.nvim_exec_autocmds('User', {
    pattern = 'ConformFormatPre',
    data = autocmd_data,
  })
  log.info('Run %s on %s', formatter.name, vim.api.nvim_buf_get_name(bufnr))
  log.trace('Input lines: %s', input_lines)
  callback = util.wrap_callback(callback, function(err)
    if err then
      if last_run_errored[formatter.name] then
        err.debounce_message = true
      end
      last_run_errored[formatter.name] = true
    else
      last_run_errored[formatter.name] = false
    end
    autocmd_data['err'] = err
    vim.api.nvim_exec_autocmds('User', {
      pattern = 'ConformFormatPost',
      data = autocmd_data,
    })
  end)
  if config.format then
    local err_string_cb = function(err, ...)
      if err then
        callback({
          code = errors.ERROR_CODE.RUNTIME,
          message = err,
        }, ...)
      else
        callback(nil, ...)
      end
    end
    ---@cast config conform.LuaFormatterConfig
    local ok, err = pcall(config.format, config, ctx, input_lines, err_string_cb)
    if not ok then
      err_string_cb(string.format("Formatter '%s' error: %s", formatter.name, err))
    end
    return
  end
  ---@cast config conform.JobFormatterConfig
  local cmd = M.build_cmd(formatter.name, ctx, config)
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

  if not config.stdin then
    log.info('Creating temp file %s', ctx.filename)
    dir_manager.ensure_parent(ctx.filename)
    local fd = assert(uv.fs_open(ctx.filename, 'w', 448)) -- 0700
    uv.fs_write(fd, buffer_text)
    uv.fs_close(fd)
    callback = util.wrap_callback(callback, function()
      log.debug('Cleaning up temp file %s', ctx.filename)
      uv.fs_unlink(ctx.filename)
      dir_manager.cleanup()
    end)
  end

  log.debug('Run command: %s', cmd)
  if cwd then
    log.debug('Run CWD: %s', cwd)
  else
    log.debug('Run default CWD: %s', vim.fn.getcwd())
  end
  if env then
    log.debug('Run ENV: %s', env)
  end
  local exit_codes = config.exit_codes or { 0 }
  local pid
  local ok, job_or_err = pcall(
    vim.system,
    cmd,
    {
      cwd = cwd,
      env = env,
      stdin = config.stdin and buffer_text or nil,
      text = true,
    },
    vim.schedule_wrap(function(result)
      local code = result.code
      local stdout = result.stdout and vim.split(result.stdout, '\r?\n') or {}
      local stderr = result.stderr and vim.split(result.stderr, '\r?\n') or {}
      if vim.tbl_contains(exit_codes, code) then
        local output = stdout
        if not config.stdin then
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
        log.debug('%s exited with code %d', formatter.name, code)
        log.trace('Output lines: %s', output)
        log.trace('%s stderr: %s', formatter.name, stderr)
        callback(nil, output)
      else
        log.info('%s exited with code %d', formatter.name, code)
        log.debug('%s stdout: %s', formatter.name, stdout)
        log.debug('%s stderr: %s', formatter.name, stderr)
        local err_str
        if not is_empty_output(stderr) then
          err_str = table.concat(stderr, '\n')
        elseif not is_empty_output(stdout) then
          err_str = table.concat(stdout, '\n')
        else
          err_str = 'unknown error'
        end
        if vim.api.nvim_buf_is_valid(bufnr) and pid ~= vim.b[bufnr].conform_pid and opts.exclusive then
          callback {
            code = errors.ERROR_CODE.INTERRUPTED,
            message = string.format("Formatter '%s' was interrupted", formatter.name),
          }
        else
          callback {
            code = errors.ERROR_CODE.RUNTIME,
            message = string.format("Formatter '%s' error: %s", formatter.name, err_str),
          }
        end
      end
    end)
  )
  if not ok then
    callback {
      code = errors.ERROR_CODE.VIM_SYSTEM,
      message = string.format("Formatter '%s' error in vim.system: %s", formatter.name, job_or_err),
    }
    return
  end
  pid = job_or_err.pid
  if opts.exclusive then
    vim.b[bufnr].conform_pid = pid
  end

  return pid
end

---@param bufnr integer
---@param formatters conform.FormatterInfo[]
---@param timeout_ms integer
---@param range? conform.Range
---@param opts conform.RunOpts
---@return conform.Error? error
---@return string[] output_lines
---@return boolean all_support_range_formatting
M.format_lines_sync = function(bufnr, formatters, timeout_ms, range, input_lines, opts)
  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  local start = uv.hrtime() / 1e6

  local all_support_range_formatting = true
  local final_err = nil
  for _, formatter in ipairs(formatters) do
    local remaining = timeout_ms - (uv.hrtime() / 1e6 - start)
    if remaining <= 0 then
      return errors.coalesce(final_err, {
        code = errors.ERROR_CODE.TIMEOUT,
        message = string.format("Formatter '%s' timeout", formatter.name),
      }),
        input_lines,
        all_support_range_formatting
    end
    local done = false
    local result = nil
    ---@type conform.FormatterConfig
    local config = assert(require('conform').get_formatter_config(formatter.name, bufnr))
    local ctx = M.build_context(bufnr, config, range)
    local pid = run_formatter(bufnr, formatter, config, ctx, input_lines, opts, function(err, output)
      final_err = errors.coalesce(final_err, err)
      done = true
      result = output
    end)
    all_support_range_formatting = all_support_range_formatting and truthy(config.range_args)

    local wait_result, wait_reason = vim.wait(remaining, function()
      return done
    end, 5)

    if not wait_result then
      if pid then
        uv.kill(pid)
      end
      if wait_reason == -1 then
        return errors.coalesce(final_err, {
          code = errors.ERROR_CODE.TIMEOUT,
          message = string.format("Formatter '%s' timeout", formatter.name),
        }),
          input_lines,
          all_support_range_formatting
      else
        return errors.coalesce(final_err, {
          code = errors.ERROR_CODE.INTERRUPTED,
          message = string.format("Formatter '%s' was interrupted", formatter.name),
        }),
          input_lines,
          all_support_range_formatting
      end
    end

    input_lines = result or input_lines
  end

  return final_err, input_lines, all_support_range_formatting
end
return M
