-- Minimal format-on-save: CLI formatters + LSP fallback.
---@class Fmt
---@field config table
---@field setup fun()
---@field format_buffer fun(bufnr?:integer)
local Fmt = {}
local H = {}

---@class FormatDef
---@field cmd string
---@field args string[]
---@field envs? table<string,string>

---@alias FormatList FormatDef|FormatDef[]

local prettier = { cmd = 'prettier', args = { '--stdin-filepath', '$FILENAME' } }
local dprint = {
  cmd = 'dprint',
  args = { 'fmt', '--stdin', '$FILENAME' },
  envs = { DPRINT_CONFIG_DIR = vim.fn.expand '~/.config/dprint', DPRINT_CONFIG_DISCOVERY = 'global' },
}
local shfmt = { cmd = 'shfmt', args = { '-i', '2', '-ci', '-filename', '$FILENAME' } }

Fmt.config = {
  timeout_ms = 1000,

  ---@type table<string, FormatList>
  formatters_by_ft = {
    sh = shfmt,
    cmake = { cmd = 'gersemi', args = { '-' } },
    css = prettier,
    html = prettier,
    json = { dprint, prettier },
    jsonc = { dprint, prettier },
    javascript = { dprint, prettier },
    javascriptreact = { dprint, prettier },
    lua = { cmd = 'stylua', args = { '--stdin-filepath', '$FILENAME', '-' } },
    markdown = prettier,
    python = {
      {
        cmd = 'ruff',
        args = { 'check', '--fix', '--force-exclude', '--exit-zero', '--no-cache', '--unsafe-fixes', '--select=I001', '--stdin-filename', '$FILENAME', '-' },
      },
      { cmd = 'ruff', args = { 'format', '--force-exclude', '--stdin-filename', '$FILENAME', '-' } },
    },
    rust = { cmd = 'rustfmt', args = { '$FILENAME' } },
    scss = prettier,
    typescript = { dprint, prettier },
    typescriptreact = { dprint, prettier },
    yaml = prettier,
    zsh = shfmt,
  },

  -- Filetypes that use LSP formatting exclusively when a client is attached.
  ---@type table<string, true>
  lsp_prefer = {
    c = true,
    cpp = true,
    dts = true,
    rust = true,
    toml = true,
  },
}

function Fmt.setup()
  vim.g.autoformat = true
  _G.Fmt = Fmt
  local aug = vim.api.nvim_create_augroup('CustomFormat', { clear = true })
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = aug,
    desc = 'Format on save',
    callback = function()
      if vim.g.minifiles_active then
        return
      end
      if vim.g.skip_formatting then
        vim.g.skip_formatting = false
        return
      end
      if not vim.g.autoformat then
        return
      end
      Fmt.format_buffer()
    end,
  })
end

---Substitute well-known placeholders in a formatter's argv.
---@param args string[]
---@param bufnr integer
---@return string[]
function H.expand_args(args, bufnr)
  local filename = vim.api.nvim_buf_get_name(bufnr)
  return vim
    .iter(args)
    :map(function(a)
      if a == '$FILENAME' then
        return filename
      end
      return a
    end)
    :totable()
end

---Run one formatter: pipe `text` to stdin, return stdout or nil on failure.
---@param fmt FormatDef
---@param text string
---@param bufnr integer
---@return string|nil
function H.run(fmt, text, bufnr)
  local cmd = { fmt.cmd, unpack(H.expand_args(fmt.args, bufnr)) }
  local result = vim.system(cmd, { stdin = text, text = true, env = fmt.envs }):wait(Fmt.config.timeout_ms)
  if result.code ~= 0 then
    vim.notify(string.format('[format] %s failed (%s): %s', fmt.cmd, result.code, result.stderr or ''), vim.log.levels.WARN)
    return nil
  end
  return result.stdout
end

---@param bufnr? integer
function Fmt.format_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype

  if Fmt.config.lsp_prefer[ft] then
    local clients = vim.lsp.get_clients { bufnr = bufnr, method = 'textDocument/formatting' }
    if #clients > 0 then
      vim.lsp.buf.format { bufnr = bufnr, timeout_ms = Fmt.config.timeout_ms }
      return
    end
  end

  local formatters = Fmt.config.formatters_by_ft[ft]
  if not formatters then
    return
  end
  if formatters.cmd then
    formatters = { formatters }
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local text = table.concat(lines, '\n') .. (vim.bo[bufnr].eol and '\n' or '')

  for _, fmt in ipairs(formatters) do
    local out = H.run(fmt, text, bufnr)
    if not out then
      return
    end
    text = out
  end

  if text:match '^%s*$' and #lines > 0 and lines[1] ~= '' then
    vim.notify('[format] empty output, aborting', vim.log.levels.WARN)
    return
  end

  local new_lines = vim.split(text, '\r?\n')
  if vim.bo[bufnr].eol and new_lines[#new_lines] == '' then
    table.remove(new_lines)
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
end

return Fmt
