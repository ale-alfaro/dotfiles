-- Minimal format-on-save: CLI formatters + LSP fallback.
---@class Fmt
---@field config table
---@field setup fun()
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
local prettier = { command = 'prettier', args = { '--stdin-filepath', '$FILENAME' } }
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
local kconfigsyle = { command = 'mise', args = { 'run', 'kconfigstyle:fmt', '$FILENAME' }, post = true }

local dtslinter = { cmd = 'dts-linter', args = { '--formatFixAll', '--file', '$FILENAME' }, lsp_prefer = true }

Fmt.config = {
  timeout_ms = 1000,
  ---@type table<string, FormatList>
  formatters_by_ft = {
    c = clang_format,
    cpp = clang_format,
    cmake = { command = 'gersemi', args = { '-' } },
    css = prettier,
    dts = dtslinter,
    html = dprint,
    kconfig = kconfigsyle,
    javascript = dprint,
    json = dprint,
    jsonc = dprint,
    lua = stylua,
    markdown = dprint,
    sh = shfmt,
    python = ruff,
    rust = { command = 'rustfmt', args = { '$FILENAME' }, lsp_prefer = true },
    typescript = dprint,
    typst = { command = 'typstyle', args = { '$FILENAME' }, lsp_prefer = true },
    yaml = dprint,
    zsh = shfmt,
  },
}

---@param options {bufnr:integer,id?:integer,name?:string,range?:boolean,filter?:fun(vim.lsp.Client):boolean}
---@return table[] clients
local function get_format_clients(options)
  local method = options.range and 'textDocument/rangeFormatting' or 'textDocument/formatting'

  local clients = vim.lsp.get_clients {
    id = options.id,
    bufnr = options.bufnr,
    name = options.name,
    method = method,
  }
  if options.filter then
    clients = vim.tbl_filter(options.filter, clients)
  end
  return clients
end
function Fmt.setup()
  vim.g.autoformat = true
  _G.Fmt = Fmt
  -- local aug = vim.api.nvim_create_augroup('CustomFormat', { clear = true })
  -- vim.api.nvim_create_autocmd('BufWritePost', {
  --   desc = 'Format after save',
  --   pattern = '*',
  --   group = aug,
  --   callback = function(args)
  --     if not vim.api.nvim_buf_is_valid(args.buf) or vim.b[args.buf].autoformat or vim.bo[args.buf].buftype ~= '' then
  --       return
  --     end
  --     local ft = vim.bo[args.buf].filetype
  --
  --     local formatter = Fmt.config.formatters_by_ft[ft]
  --     if not formatter or not formatter.post then
  --       return
  --     end
  --     local callback = function(err)
  --       if not err and vim.api.nvim_buf_is_valid(args.buf) then
  --         vim.api.nvim_buf_call(args.buf, function()
  --           vim.b[args.buf].conform_applying_formatting = true
  --           vim.cmd.update()
  --           vim.b[args.buf].conform_applying_formatting = false
  --         end)
  --       end
  --     end
  --     Fmt.format(args.buf, { async_cb = callback })
  --   end,
  -- })
end
--- Format buffer
---@param bufnr integer buf id
---@param opts? {async_cb:fun(err?:string)}
Fmt.format = function(bufnr, opts)

  bufnr = bufnr or vim.api.nvim_get_current_buf()
  opts = opts or {}
  local ft = vim.bo[bufnr].filetype
---@type fmt.FormatterConfig
    local formatter = Fmt.config.formatters_by_ft[ft]
    if not formatter or formatter.post then
      return
    end
  -- vim.b[] returns nil for unset vars; nvim_buf_get_var would throw.
  if   opts.async_cb then
    local input_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
    require('custom.docgen').run_formatter(bufnr, ft, formatter, input_lines, function(output)
      local err = nil
      if not output then
        err = 'Failed to format'
        VimRc.err(err)
      end
      input_lines = output or input_lines
      -- discard formatting if buffer has changed
      if not vim.api.nvim_buf_is_valid(bufnr) then
        err = string.format('Async formatter discarding changes for %d: concurrent modification', bufnr)
        VimRc.err(err)
      else
        require('custom.docgen').apply_format(bufnr, input_lines, output or input_lines)
      end
      opts.async_cb(err)
    end)
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
        VimRc.err(string.format("Formatter '%s' timeout", formatter.command))
      else
        VimRc.err(string.format("Formatter '%s' was interrupted", formatter.command))
      end
      return
    end
    require('custom.docgen').apply_format(bufnr, input_lines, result or input_lines)
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

return Fmt
