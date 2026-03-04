D = {}
D.create_namespace = vim.api.nvim_create_namespace
D.default_ns = D.create_namespace 'VimRc'
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
  vim.validate('diags', diags, 'table')
  if #diags > 0 then
    VimRc.error 'Zero diags were matched'
  end

  source = vim.F.if_nil(source, 'custom')

  local ns = ns_id or D.create_namespace 'custom'
  vim.diagnostic.set(ns, 0, diags)
  vim.diagnostic.setqflist {
    namespace = ns,
    open = true,
    severity = vim.diagnostic.severity.ERROR,
  }
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
  local default = vim.defaulttable(function(key)
    if key == 'col' then
      return 0
    elseif key == 'severity' then
      return vim.diagnostic.severity.ERROR
    end
  end)
  defaults = vim.tbl_extend('force', default, defaults or {})

  local decoded = vim
    .iter(mapping)
    :map(function(field, keys_to_json_val)
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
    end)
    :totable()

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
  if mapping_to_diag_field['diagnostics'] and decoded[mapping_to_diag_field['diagnostics']] then
    entries = mapping_to_diag_field['diagnostics']
  end

  vim.validate('entries', entries, 'table')
  local diags = vim
    :iter(entries, function(entry)
      return D.mapping_to_diag_field(entry, mapping_to_diag_field)
    end)
    :totable()
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
        warn = vim.diagnostic.WARN,
      })
      if diag then
        diags[#diags + 1] = diag
      end
    end
  end
  vim.schedule(function()
    D.add_diagnostics(diags, source, ns_id)
  end)
end

local _loaded_clients = {}

--- Plugin configuration with its default values.
---
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
---

local function _populate_workspace_diagnostics(client, bufnr)
  local workspace_files = VimRc.utils.get_workspace_files()

  for _, path in ipairs(workspace_files) do
    local filetype = VimRc.utils.get_filetype(path)

    if path == vim.api.nvim_buf_get_name(bufnr) then
      goto continue
    end

    if not vim.tbl_contains(client.config.filetypes, filetype) then
      goto continue
    end

    vim.defer_fn(function()
      local params = {
        textDocument = {
          uri = vim.uri_from_fname(path),
          version = 0,
          text = vim.fn.join(vim.fn.readfile(path), '\n'),
          languageId = filetype,
        },
      }
      client.notify('textDocument/didOpen', params)
    end, 0)

    ::continue::
  end
end
--- Populate workspace diagnostics.
---
---@param client table Lsp client.
---@param bufnr number Buffer number.
---
---@usage `require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)`
function D.populate_workspace_diagnostics(client, bufnr)
  if vim.tbl_contains(_loaded_clients, client.id) then
    return
  end
  table.insert(_loaded_clients, client.id)

  if not vim.tbl_get(client.config, 'filetypes') then
    local msg = '[workspace-diagnostics.nvim] ' .. client.name .. ' is skipped: please define `config.filetypes` when setting up the client.'
    vim.api.nvim_echo({ { msg, 'WarningMsg' } }, true, {})
    return
  end

  _populate_workspace_diagnostics(client, bufnr)
end
return D
