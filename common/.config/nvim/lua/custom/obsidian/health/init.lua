-- Obsidian Vault Health: interactive maintenance of orphans, deadends,
-- missing/inconsistent frontmatter, and unknown tags/categories.
--
-- Usage (in a project-local .nvim.lua or wherever):
--   require('custom.obsidian.health').setup({ name = 'Techie' })
---@class obsidian.health.action
---@field name string
---@field title string|fun(pd:obsidian.health.ctx):string
---@field cond fun(pd:obsidian.health.ctx):boolean
---@field fn fun(pd:obsidian.health.ctx, vault:string):(string?, string?)
---@field after? 'remove_block' | 'remove_entity' | 'none'

local FM = require 'custom.obsidian.frontmatter'

local URI_RX = '^obsidian%-health://confirm#(%d+)$'
local URI_PREFIX = 'obsidian-health://confirm#'
---Re-gather issues and replace the buffer's contents in place.
---@param vault_path string
---@param bufnr integer
local function refresh(vault_path, bufnr)
  vim.validate('path', vault_path, 'string')
  if not vim.uv.fs_stat(vault_path) then
    return
  end

  local render, gather = require 'custom.obsidian.health.render', require 'custom.obsidian.health.gather'
  local issues = gather.run(vault_path)
  local lines = render.lines(issues)

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable, vim.bo[bufnr].modified = false, false
  vim.notify('Vault Health: refreshed', vim.log.levels.INFO)
end

-- Code-action registry. Each action declares: name, title, cond(pd) → bool,
-- fn(pd, vault) → (msg, warn), and an `after` mode for buffer mutation.
-- Each registered action is exposed via `vim.lsp.commands` so neovim
-- dispatches client-side without a `workspace/executeCommand` round-trip.

---@param vault string
---@param name string
local function add_tag_to_canonical(vault, name) end

---@param vault string
---@param name string
local function create_category(vault, name)
  local p = vault .. '/_categories/' .. name .. '.md'
  if vim.fn.filereadable(p) == 1 then
    return
  end
  local today = os.date '%Y-%m-%d'
  vim.fn.writefile({
    '---',
    'note_type: _categories',
    'categories: []',
    'created: ' .. today,
    'last: ' .. today,
    'tags: []',
    '---',
    '',
    '## ' .. name,
    '',
  }, p)
end

-- ── Buffer mutations after a successful action ───────────────────────────
local function buf_remove_range(bufnr, from, to)
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, math.max(0, from - 2), to, false, {})
  vim.bo[bufnr].modifiable, vim.bo[bufnr].modified = false, false
end

local function buf_remove_entity(bufnr, pd)
  local lines = vim.api.nvim_buf_get_lines(bufnr, pd.from - 1, pd.to, false)
  for i, l in ipairs(lines) do
    if l == '- ' .. pd.entity then
      vim.bo[bufnr].modifiable = true
      vim.api.nvim_buf_set_lines(bufnr, pd.from + i - 2, pd.from + i - 1, false, {})
      vim.bo[bufnr].modifiable, vim.bo[bufnr].modified = false, false
      return
    end
  end
end

-- ── Public API ────────────────────────────────────────────────────────────
local actions = {
  -- ── Orphans / Deadends ────────────────────────────────────────────────────
  {
    name = 'open',
    title = 'Open',
    cond = function(pd)
      return pd.file ~= nil and pd.entity == nil
    end,
    after = 'none',
    fn = function(pd, vault)
      vim.cmd('vsplit ' .. vim.fn.fnameescape(vault .. '/' .. pd.file))
      return ('Opened %s'):format(pd.file)
    end,
  },
  {
    name = 'tag_orphan_review',
    title = 'Tag #orphan-review',
    cond = function(pd)
      return pd.group == 'Orphans' or pd.group == 'Deadends'
    end,
    after = 'remove_block',
    fn = function(pd, vault)
      FM.add_tag(vault .. '/' .. pd.file, 'orphan-review')
      return ('Tagged %s with #orphan-review'):format(pd.file)
    end,
  }, -- ── Missing properties ────────────────────────────────────────────────────
  {
    name = 'autofill',
    title = 'Auto-fill missing properties',
    cond = function(pd)
      return pd.group == 'Missing properties'
    end,
    after = 'remove_block',
    fn = function(pd, vault)
      local folder = pd.file:match '^([^/]+)/'
      FM.autofill(vault .. '/' .. pd.file, folder)
      return ('Auto-filled %s'):format(pd.file)
    end,
  }, -- ── Mismatched note_type ──────────────────────────────────────────────────
  {
    name = 'set_note_type',
    title = 'Set note_type to folder',
    cond = function(pd)
      return pd.group == 'Mismatched note_type'
    end,
    after = 'remove_block',
    fn = function(pd, vault)
      local folder = pd.file:match '^([^/]+)/'
      FM.set_note_type(vault .. '/' .. pd.file, folder)
      return ('Set note_type=%s on %s'):format(folder, pd.file)
    end,
  }, -- ── Unknown tags ──────────────────────────────────────────────────────────
  {
    name = 'rename_tag',
    title = function(pd)
      return 'Rename tag `' .. pd.entity .. '` →…'
    end,
    cond = function(pd)
      return pd.group == 'Unknown tags' and pd.entity ~= nil
    end,
    after = 'remove_entity',
    fn = function(pd, vault)
      local new = vim.fn.input('Rename `' .. pd.entity .. '` to: ')
      if new == '' then
        return nil, 'Rename cancelled'
      end
      FM.rename_tag(vault .. '/' .. pd.file, pd.entity, new)
      return ('Renamed tag `%s` → `%s` in %s'):format(pd.entity, new, pd.file)
    end,
  },
  {
    name = 'remove_tag',
    title = function(pd)
      return 'Remove tag `' .. pd.entity .. '` from note'
    end,
    cond = function(pd)
      return pd.group == 'Unknown tags' and pd.entity ~= nil
    end,
    after = 'remove_entity',
    fn = function(pd, vault)
      FM.remove_tag(vault .. '/' .. pd.file, pd.entity)
      return ('Removed tag `%s` from %s'):format(pd.entity, pd.file)
    end,
  },
  {
    name = 'add_canonical_tag',
    title = function(pd)
      return 'Add `' .. pd.entity .. '` to canonical TAGS'
    end,
    cond = function(pd)
      return pd.group == 'Unknown tags' and pd.entity ~= nil
    end,
    after = 'remove_entity',
    fn = function(pd, vault)
      add_tag_to_canonical(vault, pd.entity)
      return ('Added `%s` to canonical TAGS'):format(pd.entity)
    end,
  }, -- ── Unknown categories ────────────────────────────────────────────────────
  {
    name = 'create_category',
    title = function(pd)
      return 'Create _categories/' .. pd.entity .. '.md'
    end,
    cond = function(pd)
      return pd.group == 'Unknown categories' and pd.entity ~= nil
    end,
    after = 'remove_entity',
    fn = function(pd, vault)
      create_category(vault, pd.entity)
      return ('Created _categories/%s.md'):format(pd.entity)
    end,
  },
  {
    name = 'remove_category',
    title = function(pd)
      return 'Remove `' .. pd.entity .. '` from note'
    end,
    cond = function(pd)
      return pd.group == 'Unknown categories' and pd.entity ~= nil
    end,
    after = 'remove_entity',
    fn = function(pd, vault)
      FM.remove_category(vault .. '/' .. pd.file, pd.entity)
      return ('Removed category `%s` from %s'):format(pd.entity, pd.file)
    end,
  },
}

---Build the LSP code-action list for `pd`.
---@param pd obsidian.health.ctx
---@param bufnr integer
---@return table[]
local function code_actions_for(pd, bufnr)
  local res = {}
  for _, a in ipairs(actions) do
    if a.cond(pd) then
      local title = type(a.title) == 'function' and a.title(pd) or a.title
      table.insert(res, {
        title = title,
        command = {
          title = title,
          command = 'obsidian.health.' .. a.name,
          arguments = { bufnr, pd },
        },
      })
    end
  end
  return res
end

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
    local g = l:match '^# (.+)$'
    local f = l:match '^## (.+)$'
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

  local pd = require('custom.obsidian.health.render').ctx_at(bufnr, params.range.start.line + 1)
  if not pd.file then
    return cb(nil, {})
  end
  cb(nil, code_actions_for(pd, bufnr))
end

methods['textDocument/definition'] = function(params, cb, vault_path)
  local bufnr = uri_to_bufnr(params.textDocument.uri)
  if not bufnr or not vault_path then
    return cb(nil, nil)
  end
  local lnum = params.position.line + 1
  local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ''
  local file = line:match '^## (.+)$'
  if not file then
    return cb(nil, nil)
  end
  cb(nil, {
    uri = vim.uri_from_fname(vault_path .. '/' .. file),
    range = {
      start = { line = 0, character = 0 },
      ['end'] = { line = 0, character = 0 },
    },
  })
end

methods['textDocument/hover'] = function(params, cb, vault_path)
  local bufnr = uri_to_bufnr(params.textDocument.uri)
  if not bufnr then
    return
  end
  local lnum = params.position.line + 1
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local file = lines[lnum] and lines[lnum]:match '^## (.+)$'
  if not file or not vault_path then
    return
  end
  local content = readlines(vault_path .. '/' .. file)
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
local function ensure_client(root_dir)
  if _client_id then
    return _client_id
  end
  _client_id = vim.lsp.start({ cmd = server_cmd, name = 'obsidian-health', root_dir = root_dir }, { attach = false })
  return _client_id
end

---Register every action's handler in `vim.lsp.commands` so neovim dispatches
---client-side without a server round-trip.
local function register_lsp_commands(vault_path)
  for _, action in ipairs(actions) do
    vim.lsp.commands['obsidian.health.' .. action.name] = vim.schedule_wrap(function(command)
      local bufnr, pd = command.arguments[1], command.arguments[2]
      if not vault_path then
        vim.notify('Vault Health: setup() not called', vim.log.levels.ERROR)
        return
      end
      local ok, msg, warn = pcall(action.fn, pd, vault_path)
      if not ok then
        vim.notify('Vault Health: ' .. tostring(msg), vim.log.levels.ERROR)
        return
      end

      if action.after == 'remove_block' and pd.from then
        buf_remove_range(bufnr, pd.from, pd.to)
      elseif action.after == 'remove_entity' and pd.entity then
        buf_remove_entity(bufnr, pd)
      end

      if msg then
        vim.notify(msg, vim.log.levels.INFO)
      elseif warn then
        vim.notify(warn, vim.log.levels.WARN)
      end
    end)
  end
end

return {
  ---@param vault_path string
  check = function(vault_path)
    vim.validate('vault_path', vault_path, 'string')
    if not vim.uv.fs_stat(vault_path) then
      vim.notify('Vault Health: setup() not called', vim.log.levels.ERROR)
      return
    end

    local render, gather = require 'custom.obsidian.health.render', require 'custom.obsidian.health.gather'
    local issues = gather.run(vault_path)
    local lines = render.lines(issues)

    VimRc.show_in_split(lines, '__vh_' .. tostring(vim.uv.hrtime()), 'markdown')
    local bufnr = vim.api.nvim_get_current_buf()
    pcall(vim.api.nvim_buf_set_name, bufnr, '')
    vim.api.nvim_buf_set_name(bufnr, URI_PREFIX .. bufnr)

    vim.bo[bufnr].buftype = 'nofile'
    vim.bo[bufnr].modifiable = false
    vim.bo[bufnr].modified = false

    local cid = ensure_client(vault_path)
    if cid then
      vim.lsp.buf_attach_client(bufnr, cid)
    end
    register_lsp_commands(vault_path)
    local kmap = function(lhs, fn, desc)
      vim.keymap.set('n', lhs, fn, { buffer = bufnr, desc = 'Vault Health: ' .. desc })
    end
    kmap('gA', vim.lsp.buf.code_action, 'code action')
    kmap('K', vim.lsp.buf.hover, 'preview note')
    kmap('gd', vim.lsp.buf.definition, 'go to note')
    kmap('R', function()
      refresh(vault_path, bufnr)
    end, 'refresh')
  end,
}
