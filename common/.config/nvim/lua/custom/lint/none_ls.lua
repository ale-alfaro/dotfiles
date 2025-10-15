local h = require 'null-ls.helpers'
local methods = require 'null-ls.methods'
local DIAGNOSTICS = methods.internal.DIAGNOSTICS
local FORMATTING = methods.internal.FORMATTING
local CODE_ACTION = methods.internal.CODE_ACTION

local severities = {
  error = vim.lsp.protocol.DiagnosticSeverity.Error,
  warning = vim.lsp.protocol.DiagnosticSeverity.Warning,
  ignored = vim.lsp.protocol.DiagnosticSeverity.Information,
}
return h.make_builtin {
  name = 'uv_ruff_check',
  method = DIAGNOSTICS,
  filetypes = { 'python' },
  generator_opts = {
    command = 'uv',
    args = { 'run', 'ruff', 'check', '--output-format', 'json-lines', '--stdin-filename', '$FILENAME' },
    format = 'json',
    to_stdin = true,
    from_stderr = false,
    ignore_stderr = true,
    multiple_files = true,
    -- check_exit_code = function(code)
    --     return code <= 1
    -- end,
    on_output = function(line)
      local decoded = vim.json.decode(line)
      return {
        row = decoded.location.row,
        col = decoded.location.column,
        end_row = decoded['end'].row,
        end_col = decoded['end'].column,
        source = 'ruff',
        code = decoded.code,
        message = decoded.message,
        severity = severities[decoded.severity],
        filename = decoded.filename,
      }
    end,
    -- cwd = h.cache.by_bufnr(M.get_project_root),
  },
  factory = h.generator_factory,
}
--   ty_check = h.make_builtin {
--     name = 'uv_ty_check',
--     method = DIAGNOSTICS,
--     filetypes = { 'python' },
--     generator_opts = {
--       command = 'uv',
--       args = { 'run', 'ty', 'check', '--output-format', 'concise', '$FILENAME' },
--       format = 'line',
--       to_stdin = false,
--       on_output = function(output)
--
--         local filename, lnum_str, col_str, severity_str, code, message = output_str:match '^([^:]+):(%d+):(%d+): (%a+)%[([%w%-]+)%] (.+)$'
--         if filename then
--           local lnum = tonumber(lnum_str)
--           local col = tonumber(col_str)
--           local sev = vim.diagnostic.severity.INFO
--           if severity_str == 'error' then
--             sev = vim.diagnostic.severity.ERROR
--           elseif severity_str == 'warn' then
--             sev = vim.diagnostic.severity.WARN
--           end
--
--           table.insert(diagnostics, {
--             bufnr = 0,
--             lnum = lnum - 1,
--             col = col - 1,
--             -- ty check doesn't provide end_location, so we'll just use the start
--             end_lnum = lnum - 1,
--             end_col = col,
--             message = string.format('[%s] %s', code, message),
--             severity = sev,
--             source = 'ty',
--           })
--
--         end
--       end,
--       cwd = h.cache.by_bufnr(M.get_project_root),
--     },
--     factory = h.generator_factory,
--   },
-- },
-- formatting = {
--   ruff_format = h.make_builtin {
--     name = 'uv_ruff_format',
--     method = FORMATTING,
--     filetypes = { 'python' },
--     generator_opts = {
--       command = 'uv',
--       args = { 'run', '--all-packages', 'ruff', 'format', '$FILENAME' },
--       to_stdin = true,
--       cwd = h.cache.by_bufnr(M.get_project_root),
--     },
--     factory = h.formatter_factory,
--   },
-- },
-- code_actions = {
--   ruff_fix = h.make_builtin {
--     name = 'uv_ruff_fix',
--     method = CODE_ACTION,
--     filetypes = { 'python' },
--     generator_opts = {
--       command = 'uv',
--       args = { 'run', 'ruff', 'check', '--fix' },
--       to_stdin = false,
--       on_output = function(output)
--         return M.handle_output(output, 0, 'ruff check')
--       end,
--       cwd = h.cache.by_bufnr(M.get_project_root),
--     },
--     factory = h.generator_factory,
--   },
