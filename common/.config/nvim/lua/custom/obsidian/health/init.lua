-- Obsidian Vault Health: interactive maintenance of orphans, deadends,
-- missing/inconsistent frontmatter, and unknown tags/categories.
--
-- Usage (in a project-local .nvim.lua or wherever):
--   require('custom.obsidian.health').setup({ name = 'Techie' })
local config = require('custom.obsidian.health.config')

local M = {}

---Resolve a vault name to its absolute path via `obsidian vaults verbose`.
---@param name string
---@return string?
local function resolve_vault(name)
  local out = vim.fn.systemlist({ 'obsidian', 'vaults', 'verbose' })
  for _, line in ipairs(out) do
    local n, p = line:match('^(%S+)%s+(.+)$')
    if n == name then
      return p
    end
  end
  return nil
end

---@param opts string | { name: string }
function M.setup(opts)
  local name = type(opts) == 'string' and opts or (opts and opts.name)
  if not name then
    error('obsidian.health.setup requires a vault name', 2)
  end
  local path = resolve_vault(name)
  if not path then
    error('Vault not found in `obsidian vaults`: ' .. name, 2)
  end
  config.vault.name = name
  config.vault.path = path

  -- Register code-action handlers in vim.lsp.commands (client-side dispatch)
  require('custom.obsidian.health.actions').register_lsp_commands()

  vim.api.nvim_create_user_command(
    'VaultHealth',
    M.open,
    { desc = 'Interactive Obsidian vault health' }
  )
end

---Re-gather issues and replace the buffer's contents in place.
---@param bufnr integer
function M.refresh(bufnr)
  if not config.vault.path then
    return
  end
  local gather = require('custom.obsidian.health.gather')
  local render = require('custom.obsidian.health.render')

  local issues = gather.run(config.vault.path)
  local lines = render.lines(issues)

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable, vim.bo[bufnr].modified = false, false
  vim.notify('Vault Health: refreshed', vim.log.levels.INFO)
end

function M.open()
  if not config.vault.path then
    vim.notify('Vault Health: setup() not called', vim.log.levels.ERROR)
    return
  end

  local gather = require('custom.obsidian.health.gather')
  local render = require('custom.obsidian.health.render')
  local lsp = require('custom.obsidian.health.lsp')

  local issues = gather.run(config.vault.path)
  local lines = render.lines(issues)

  VimRc.show_in_split(lines, '__vh_' .. tostring(vim.uv.hrtime()), 'markdown')
  local bufnr = vim.api.nvim_get_current_buf()
  pcall(vim.api.nvim_buf_set_name, bufnr, '')
  vim.api.nvim_buf_set_name(bufnr, lsp.URI_PREFIX .. bufnr)

  vim.bo[bufnr].buftype = 'nofile'
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].modified = false

  local cid = lsp.ensure_client(config.vault.path)
  if cid then
    vim.lsp.buf_attach_client(bufnr, cid)
  end

  local kmap = function(lhs, fn, desc)
    vim.keymap.set('n', lhs, fn, { buffer = bufnr, desc = 'Vault Health: ' .. desc })
  end
  kmap('gA', vim.lsp.buf.code_action, 'code action')
  kmap('K', vim.lsp.buf.hover, 'preview note')
  kmap('gd', vim.lsp.buf.definition, 'go to note')
  kmap('R', function()
    M.refresh(bufnr)
  end, 'refresh')
end

return M
