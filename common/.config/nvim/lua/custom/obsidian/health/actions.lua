-- Code-action registry. Each action declares: name, title, cond(pd) → bool,
-- fn(pd, vault) → (msg, warn), and an `after` mode for buffer mutation.
-- Each registered action is exposed via `vim.lsp.commands` so neovim
-- dispatches client-side without a `workspace/executeCommand` round-trip.
local fm_mod = require('custom.obsidian.health.frontmatter')
local sources = require('custom.obsidian.health.sources')
local config = require('custom.obsidian.health.config')

local M = {}
local NS = 'obsidian.health.'

---@class obsidian.health.action
---@field name string
---@field title string|fun(pd:obsidian.health.ctx):string
---@field cond fun(pd:obsidian.health.ctx):boolean
---@field fn fun(pd:obsidian.health.ctx, vault:string):(string?, string?)
---@field after? 'remove_block' | 'remove_entity' | 'none'

---@type obsidian.health.action[]
M.actions = {}

local function push(a)
  table.insert(M.actions, a)
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

-- ── Orphans / Deadends ────────────────────────────────────────────────────
push({
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
})

push({
  name = 'tag_orphan_review',
  title = 'Tag #orphan-review',
  cond = function(pd)
    return pd.group == 'Orphans' or pd.group == 'Deadends'
  end,
  after = 'remove_block',
  fn = function(pd, vault)
    fm_mod.add_tag(vault .. '/' .. pd.file, 'orphan-review')
    return ('Tagged %s with #orphan-review'):format(pd.file)
  end,
})

-- ── Missing properties ────────────────────────────────────────────────────
push({
  name = 'autofill',
  title = 'Auto-fill missing properties',
  cond = function(pd)
    return pd.group == 'Missing properties'
  end,
  after = 'remove_block',
  fn = function(pd, vault)
    local folder = pd.file:match('^([^/]+)/')
    fm_mod.autofill(vault .. '/' .. pd.file, folder)
    return ('Auto-filled %s'):format(pd.file)
  end,
})

-- ── Mismatched note_type ──────────────────────────────────────────────────
push({
  name = 'set_note_type',
  title = 'Set note_type to folder',
  cond = function(pd)
    return pd.group == 'Mismatched note_type'
  end,
  after = 'remove_block',
  fn = function(pd, vault)
    local folder = pd.file:match('^([^/]+)/')
    fm_mod.set_note_type(vault .. '/' .. pd.file, folder)
    return ('Set note_type=%s on %s'):format(folder, pd.file)
  end,
})

-- ── Unknown tags ──────────────────────────────────────────────────────────
push({
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
    fm_mod.rename_tag(vault .. '/' .. pd.file, pd.entity, new)
    return ('Renamed tag `%s` → `%s` in %s'):format(pd.entity, new, pd.file)
  end,
})

push({
  name = 'remove_tag',
  title = function(pd)
    return 'Remove tag `' .. pd.entity .. '` from note'
  end,
  cond = function(pd)
    return pd.group == 'Unknown tags' and pd.entity ~= nil
  end,
  after = 'remove_entity',
  fn = function(pd, vault)
    fm_mod.remove_tag(vault .. '/' .. pd.file, pd.entity)
    return ('Removed tag `%s` from %s'):format(pd.entity, pd.file)
  end,
})

push({
  name = 'add_canonical_tag',
  title = function(pd)
    return 'Add `' .. pd.entity .. '` to canonical TAGS'
  end,
  cond = function(pd)
    return pd.group == 'Unknown tags' and pd.entity ~= nil
  end,
  after = 'remove_entity',
  fn = function(pd, vault)
    sources.add_tag_to_canonical(vault, pd.entity)
    return ('Added `%s` to canonical TAGS'):format(pd.entity)
  end,
})

-- ── Unknown categories ────────────────────────────────────────────────────
push({
  name = 'create_category',
  title = function(pd)
    return 'Create _categories/' .. pd.entity .. '.md'
  end,
  cond = function(pd)
    return pd.group == 'Unknown categories' and pd.entity ~= nil
  end,
  after = 'remove_entity',
  fn = function(pd, vault)
    sources.create_category(vault, pd.entity)
    return ('Created _categories/%s.md'):format(pd.entity)
  end,
})

push({
  name = 'remove_category',
  title = function(pd)
    return 'Remove `' .. pd.entity .. '` from note'
  end,
  cond = function(pd)
    return pd.group == 'Unknown categories' and pd.entity ~= nil
  end,
  after = 'remove_entity',
  fn = function(pd, vault)
    fm_mod.remove_category(vault .. '/' .. pd.file, pd.entity)
    return ('Removed category `%s` from %s'):format(pd.entity, pd.file)
  end,
})

-- ── Public API ────────────────────────────────────────────────────────────

---Register every action's handler in `vim.lsp.commands` so neovim dispatches
---client-side without a server round-trip.
function M.register_lsp_commands()
  for _, action in ipairs(M.actions) do
    vim.lsp.commands[NS .. action.name] = vim.schedule_wrap(function(command)
      local bufnr, pd = command.arguments[1], command.arguments[2]
      local vault = config.vault.path
      if not vault then
        vim.notify('Vault Health: setup() not called', vim.log.levels.ERROR)
        return
      end
      local ok, msg, warn = pcall(action.fn, pd, vault)
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

---Build the LSP code-action list for `pd`.
---@param pd obsidian.health.ctx
---@param bufnr integer
---@return table[]
function M.code_actions_for(pd, bufnr)
  local res = {}
  for _, a in ipairs(M.actions) do
    if a.cond(pd) then
      local title = type(a.title) == 'function' and a.title(pd) or a.title
      table.insert(res, {
        title = title,
        command = {
          title = title,
          command = NS .. a.name,
          arguments = { bufnr, pd },
        },
      })
    end
  end
  return res
end

return M
