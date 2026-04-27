-- In-process LSP server backing the Vault Health buffer. Provides
-- documentSymbol (for nav), codeAction (filtered through the action
-- registry), and hover (note preview). Commands themselves are dispatched
-- client-side via `vim.lsp.commands` (registered in actions.lua), so this
-- server has no `workspace/executeCommand` handler.
local render = require('custom.obsidian.health.render')
local actions = require('custom.obsidian.health.actions')
local config = require('custom.obsidian.health.config')

local M = {}
local URI_RX = '^obsidian%-health://confirm#(%d+)$'
M.URI_PREFIX = 'obsidian-health://confirm#'

local function uri_to_bufnr(uri)
  return tonumber(uri:match(URI_RX))
end

local function readlines(p)
  return vim.fn.filereadable(p) == 1 and vim.fn.readfile(p) or nil
end

local methods = {}

methods.initialize = function(_, cb)
  cb(nil, {
    capabilities = {
      codeActionProvider = true,
      documentSymbolProvider = true,
      hoverProvider = true,
      definitionProvider = true,
    },
  })
end

methods.shutdown = function(_, cb)
  cb(nil, nil)
end

methods['textDocument/documentSymbol'] = function(params, cb)
  local bufnr = uri_to_bufnr(params.textDocument.uri)
  if not bufnr then
    return cb(nil, {})
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local out, cur = {}, nil
  local function rng(s, e)
    return { start = { line = s, character = 0 }, ['end'] = { line = e, character = 0 } }
  end
  for i, l in ipairs(lines) do
    local g = l:match('^# (.+)$')
    local f = l:match('^## (.+)$')
    if g then
      if cur then
        cur.range['end'] = { line = i - 2, character = 0 }
      end
      cur = {
        name = g,
        kind = vim.lsp.protocol.SymbolKind.Namespace,
        range = rng(i - 1, i - 1),
        selectionRange = rng(i - 1, i - 1),
        children = {},
      }
      table.insert(out, cur)
    elseif f and cur then
      table.insert(cur.children, {
        name = f,
        kind = vim.lsp.protocol.SymbolKind.Module,
        range = rng(i - 1, i - 1),
        selectionRange = rng(i - 1, i - 1),
      })
    end
  end
  if cur then
    cur.range['end'] = { line = #lines - 1, character = 0 }
  end
  cb(nil, out)
end

methods['textDocument/codeAction'] = function(params, cb)
  local bufnr = uri_to_bufnr(params.textDocument.uri)
  if not bufnr then
    return cb(nil, {})
  end
  local empty = vim.lsp.protocol.CodeActionKind.Empty
  local only = params.context.only or { empty }
  if not vim.tbl_contains(only, empty) then
    return cb(nil, {})
  end
  local pd = render.ctx_at(bufnr, params.range.start.line + 1)
  if not pd.file then
    return cb(nil, {})
  end
  cb(nil, actions.code_actions_for(pd, bufnr))
end

methods['textDocument/definition'] = function(params, cb)
  local bufnr = uri_to_bufnr(params.textDocument.uri)
  if not bufnr or not config.vault.path then
    return cb(nil, nil)
  end
  local lnum = params.position.line + 1
  local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ''
  local file = line:match('^## (.+)$')
  if not file then
    return cb(nil, nil)
  end
  cb(nil, {
    uri = vim.uri_from_fname(config.vault.path .. '/' .. file),
    range = {
      start = { line = 0, character = 0 },
      ['end'] = { line = 0, character = 0 },
    },
  })
end

methods['textDocument/hover'] = function(params, cb)
  local bufnr = uri_to_bufnr(params.textDocument.uri)
  if not bufnr then
    return
  end
  local lnum = params.position.line + 1
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local file = lines[lnum] and lines[lnum]:match('^## (.+)$')
  if not file or not config.vault.path then
    return
  end
  local content = readlines(config.vault.path .. '/' .. file)
  if not content then
    return
  end

  local preview, in_fm, fm_done, body = {}, false, false, 0
  for _, l in ipairs(content) do
    if not fm_done then
      table.insert(preview, l)
      if l == '---' then
        if in_fm then
          fm_done = true
        else
          in_fm = true
        end
      end
    elseif body < 10 then
      table.insert(preview, l)
      body = body + 1
    else
      break
    end
  end
  cb(nil, {
    contents = {
      kind = vim.lsp.protocol.MarkupKind.Markdown,
      value = '```markdown\n' .. table.concat(preview, '\n') .. '\n```',
    },
  })
end

local dispatchers = {}
local function server_cmd(disp)
  dispatchers = disp
  local res, closing, rid = {}, false, 0
  function res.request(method, params, callback)
    local m = methods[method]
    if m then
      m(params, callback)
    end
    rid = rid + 1
    return true, rid
  end
  function res.notify(method, _)
    if method == 'exit' then
      dispatchers.on_exit(0, 15)
    end
    return false
  end
  function res.is_closing()
    return closing
  end
  function res.terminate()
    closing = true
  end
  return res
end

local _client_id

---@param root_dir string
---@return integer? client_id
function M.ensure_client(root_dir)
  if _client_id then
    return _client_id
  end
  _client_id = vim.lsp.start(
    { cmd = server_cmd, name = 'obsidian-health', root_dir = root_dir },
    { attach = false }
  )
  return _client_id
end

return M
