---@class Formatter
---@field name string
---@field primary? boolean
---@field format fun(bufnr:number)
---@field sources fun(bufnr:number):string[]
---@field priority number


function M.formatexpr()
  -- return require('conform').formatexpr()
  return vim.lsp.formatexpr { timeout_ms = 3000 }
end

---@param enable? boolean
---@param buf? number buffer number
local function autoformat_enable(enable, buf)
  if enable == nil then
    enable = true
  end
  if buf then
    vim.b.autoformat = enable
  else
    vim.g.autoformat = enable
    vim.b.autoformat = nil
  end
end
-- ---@param buf? number
local function autoformat_enabled(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  local gaf = vim.g.autoformat
  local baf = vim.b[buf].autoformat

  -- If the buffer has a local value, use that
  if baf ~= nil then
    return baf
  end

  -- Otherwise use the global value if set, or true by default
  return gaf == nil or gaf
end

---@param buf? number buffer number
function M.toggle(buf)
  autoformat_enable(not autoformat_enabled(), buf)
end


---@param client vim.lsp.Client
---@param bufnr number
function M.format(client, bufnr)
  if not autoformat_enabled(bufnr) then
    return
  end

  -- Don't format when minifiles is open, since that triggers the "confirm without
  -- synchronization" message.
  if vim.g.minifiles_active then
    return nil
  end

  vim.lsp.buf.format { bufnr = bufnr, id = client.id, timeout_ms = 1000 }
end

function M.setup()
  -- Use conform for gq.
  vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

  -- Start auto-formatting by default (and disable with my ToggleFormat command).
  vim.g.autoformat = true

  _G.info 'Registering as a formatter '
  -- M.register {
  --   name = 'conform.nvim',
  --   priority = 100,
  --   primary = true,
  --   format = function(buf)
  --     require('conform').format { bufnr = buf }
  --   end,
  --   sources = function(buf)
  --     local ret = require('conform').list_formatters(buf)
  --     return vim.tbl_map(function(v)
  --       return v.name
  --     end, ret)
  --   end,
  -- }
  -- Autoformat autocmd


  local command = vim.api.nvim_create_user_command --[[@type function]]
  command('ToggleAutoformat', function()
    M.toggle()
  end, { desc = 'Toggle Autoformat (Global)' })

  command('ToggleBufAutoformat', function()
    M.toggle(vim.api.nvim_buf_get_current_buf())
  end, { desc = 'Toggle Autoformat (Buffer)' })

end

return M
