D = {}
D.create_namespace = vim.api.nvim_create_namespace
D.default_ns = D.create_namespace("custom")
D.vim_diag_severity = {
  ERROR = 1,
  WARN = 2,
  INFO = 3,
  HINT = 4,
}

local vim_diag_severity_invert = {
  [1] = 'ERROR',
  [2] = 'WARN',
  [3] = 'INFO',
  [4] = 'HINT',
}

--- Parse a diag from a string.
---
--- For example, consider a line of output from a linter:
---
--- ```
--- WARNING filename:27:3: Variable 'foo' does not exist
--- ```
---
--- This can be parsed into |vim.diagnostic| structure with:
---
--- ```lua
--- local s = "WARNING filename:27:3: Variable 'foo' does not exist"
--- local pattern = "^(%w+) %w+:(%d+):(%d+): (.+)$"
--- local groups = { "severity", "lnum", "col", "message" }
--- vim.diagnostic.match(s, pattern, groups, { WARNING = vim.diagnostic.WARN })
--- ```
---{

---@param severity string
---@return integer
local function to_severity(severity)
  local ret = D.vim_diag_severity[severity:upper()]
  if not ret then
    error(('Invalid severity: %s'):format(severity))
  end
  return ret
end
---@param diags vim.Diagnostic[]
---@param source string?
---@param ns_id integer?
function D.add_diagnostics(diags, source, ns_id)
  vim.validate("diags", diags, "table")
  if #diags > 0 then
    _G.error("Zero diags were matched")
  end

  source = vim.F.if_nil(source, "custom")
  local ns = vim.F.if_nil(ns_id, D.default_ns) ---@type integer
  vim.diagnostic.set(ns, 0, diags)
  vim.diagnostic.setqflist(
    {
      namespace = ns,
      open = true,
      severity = vim.diagnostic.severity.ERROR

    })
end

--- Index into a table (first argument) via string keys passed as subsequent arguments.
--- Return `nil` if the key does not exist.
---
--- Examples:
---
--- ```lua
--- vim.tbl_get({ key = { nested_key = true }}, 'key', 'nested_key') == true
--- vim.tbl_get({ key = {}}, 'key', 'nested_key') == nil
--- ```
---
---@param json table
---@param mapping table<string,string|string[]>
-- mapping = {
--    ['end_col'] = { 'location', 'range', 'end' },
--   ]
---@param defaults table? Table of default values for any fields not listed in {groups}.
---                       When omitted, numeric values default to 0 and "severity" defaults to
---                       ERROR.
---@return vim.Diagnostic?: |vim.Diagnostic| structure or `nil` if {pat} fails to match {str}.
function D.match_json_field_to_diag_field(json, mapping, defaults)
  vim.validate {
    json = { json, 'table' },
    mapping = { mapping, 'table' },
    defaults = { defaults, 'table', true },
  }
  local default = vim.defaulttable((function(key)
    if key == "col" then return 0 elseif key == "severity" then return vim.diagnostic.severity.ERROR end
  end))
  defaults = vim.tbl_extend('force', default, defaults or {})

  local decoded = vim.iter(mapping):map(function(field, keys_to_json_val)
    local diagnostic = {} --- @type table<string,any>
    local value = vim.tbl_get(json, keys_to_json_val, unpack(vim._ensure_list(keys_to_json_val)))
    if field == 'severity' then
      if value and type(value) == 'string' then
        value = to_severity(value)
      end
      diagnostic[field] = value
    elseif field == 'lnum' or field == 'end_lnum' or field == 'col' or field == 'end_col' then
      diagnostic[field] = assert(tonumber(value)) - 1
    else
      diagnostic[field] = value
    end
    return diagnostic
  end):totable()

  decoded.end_lnum = decoded.end_lnum or decoded.lnum
  decoded.end_col = decoded.end_col or decoded.col
  return decoded
end

---@param json_output string
---@param mapping_to_diag_field table<string,string|string[]>
---@param source string?
---@param ns_id integer?
function D.json_to_diag(json_output, mapping_to_diag_field, source, ns_id)
  local decoded = vim.json.decode(json_output)
  local entries
  if mapping_to_diag_field["diagnostics"] and decoded[mapping_to_diag_field["diagnostics"]] then
    entries = mapping_to_diag_field["diagnostics"]
  end

  vim.validate('entries', entries, 'table')
  local diags = vim:iter(entries, function(entry)
    return D.mapping_to_diag_field(entry, mapping_to_diag_field)
  end):totable()
  D.add_diagnostics(diags, source, ns_id)
end

---@param lines string[] Cli output chunked into diag lines
---@param pattern string Lua pattern with capture groups.
---@param groups string[] List of fields in a |vim.diagnostic| structure to
---@param source string?
---@param ns_id integer?
function D.concise_line_output_to_diag(lines, pattern, groups, source, ns_id)
  local diags = {}
  for idx = 1, #lines do
    local d = lines[idx]
    if d ~= '' then
      local diag = vim.diagnostic.match(d, pattern, groups, {
        error = vim.diagnostic.severity.ERROR,
        warn = vim.diagnostic.WARN
      })
      if diag then
        diags[#diags + 1] = diag
      end
    end
  end
  vim.schedule(
    function() D.add_diagnostics(diags, source, ns_id) end
  )
end

function D.setup()
  local diagnostic_icons = VimRc.icons.diagnostics
  -- Disable inlay hints initially (and enable if needed with my ToggleInlayHints command).
  -- Define the diagnostic signs.
  for severity, icon in pairs(diagnostic_icons) do
    local hl = 'DiagnosticSign' .. severity:sub(1, 1) .. severity:sub(2):lower()
    vim.fn.sign_define(hl, { text = icon, texthl = hl })
  end
  vim.diagnostic.config {
    virtual_text = {
      prefix = '',
      spacing = 2,
      format = function(diagnostic)
        -- Use shorter, nicer names for some sources:
        local special_sources = {
          ['Lua Diagnostics.'] = 'lua',
          ['Lua Syntax Check.'] = 'lua',
        }

        local message = diagnostic_icons[vim.diagnostic.severity[diagnostic.severity]]
        if diagnostic.source then
          message = string.format('%s %s', message, special_sources[diagnostic.source] or diagnostic.source)
        end
        if diagnostic.code then
          message = string.format('%s[%s]', message, diagnostic.code)
        end

        return message .. ' '
      end,
    },
    float = {
      source = 'if_many',
      -- Show severity icons as prefixes.
      prefix = function(diag)
        local level = vim.diagnostic.severity[diag.severity]
        local prefix = string.format(' %s ', diagnostic_icons[level])
        return prefix, 'Diagnostic' .. level:gsub('^%l', string.upper)
      end,
    },
    -- Disable signs in the gutter.
    signs = false,
  }

  -- Override the virtual text diagnostic handler so that the most severe diagnostic is shown first.
  local show_handler = vim.diagnostic.handlers.virtual_text.show
  assert(show_handler)
  local hide_handler = vim.diagnostic.handlers.virtual_text.hide
  vim.diagnostic.handlers.virtual_text = {
    show = function(ns, bufnr, diagnostics, opts)
      table.sort(diagnostics, function(diag1, diag2)
        return diag1.severity > diag2.severity
      end)
      return show_handler(ns, bufnr, diagnostics, opts)
    end,
    hide = hide_handler,
  }
  _G.json_to_diag = D.json_to_diag
  _G.lines_to_diag = D.concise_line_output_to_diag
end

return D
