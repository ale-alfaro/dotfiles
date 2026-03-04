L = {}
---@comment Get the lsp configuration in the runtime path or a directory
---@param loc string
---@return string[]
L.configs_get = function(loc)
  local runtime_dir = ''
  if loc:gmatch '$%$%w+' then
    runtime_dir = vim.fn.expand(loc)
  elseif vim.uv.fs_stat(loc) then
    runtime_dir = loc
  end
  local lsp_dir = vim.fs.joinpath(runtime_dir, 'lsp')
  if not vim.uv.fs_stat(lsp_dir) then
    VimRc.err('Workspace folder ' .. runtime_dir .. ' doesnt contain a lsp directory!')
    return {}
  end
  local lsps = {}
  if vim.uv.fs_stat(lsp_dir) then
    for name, type in vim.fs.dir(lsp_dir) do
      if type == 'file' then
        lsps[#lsps + 1] = name:gsub('(%w+)%.lua', '%1')
      end
    end
  end
  return lsps
end

L.enable_local_lsps = function(workspace_topdir)
  local nvim_dir = vim.fs.joinpath(workspace_topdir, '.nvim')
  if not vim.uv.fs_stat(nvim_dir) then
    VimRc.err('Workspace folder ' .. workspace_topdir .. ' doesnt contain a .nvim directory!')
    return
  end
  local lsps = L.configs_get(nvim_dir)
  if lsps and #lsps > 0 then
    VimRc.info(string.format('Enabling lsps in workspace %s :\n %s', workspace_topdir, table.concat(lsps, '\n')))
    vim.lsp.enable(lsps)
  else
    VimRc.err('Couldnt find any lsp configs in ' .. nvim_dir)
  end
end

L.diagnostics_setup = function()
  local diagnostic_icons = {
    ERROR = '',
    WARN = '',
    HINT = '',
    INFO = '',
  }

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
      source = true, --'if_many',
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

  local hover = vim.lsp.buf.hover
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.lsp.buf.hover = function()
    return hover {
      max_height = math.floor(vim.o.lines * 0.5),
      max_width = math.floor(vim.o.columns * 0.4),
    }
  end

  local signature_help = vim.lsp.buf.signature_help
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.lsp.buf.signature_help = function()
    return signature_help {
      max_height = math.floor(vim.o.lines * 0.5),
      max_width = math.floor(vim.o.columns * 0.4),
    }
  end
end

return L
