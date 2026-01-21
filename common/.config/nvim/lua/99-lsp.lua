vim.pack.add(_G.plug_spec {
  'neovim/nvim-lspconfig',
  'rachartier/tiny-code-action.nvim',
  'p00f/clangd_extensions.nvim',
})

local diagnostics = require 'lsp.diagnostics'
local lsp_servers = { 'lua_ls', 'esbonio', 'clangd', 'neocmake', 'bashls', 'taplo', 'yamls', 'jsonls', 'marksman', 'ruff', 'pyrefly' }
local lspau = vim.api.nvim_create_augroup('vimrc.lsp', {})
vim.api.nvim_create_autocmd('LspAttach', {
  group = lspau,
  desc = 'Configure LSP keymaps',
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    -- I don't think this can happen but it's a wild world out there.
    if not client then
      return
    end
    local bufnr = args.buf
    if client:supports_method 'textDocument/documentHighlight' then
      local under_cursor_highlights_group = vim.api.nvim_create_augroup('mariasolos/cursor_highlights', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'InsertLeave' }, {
        group = under_cursor_highlights_group,
        desc = 'Highlight references under the cursor',
        buffer = bufnr,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'InsertEnter', 'BufLeave' }, {
        group = under_cursor_highlights_group,
        desc = 'Clear highlight references',
        buffer = bufnr,
        callback = vim.lsp.buf.clear_references,
      })
    end

    if client:supports_method 'textDocument/inlayHint' then
      vim.api.nvim_create_user_command('InlayHints', function()
        vim.g.inlay_hints = false
        require('lsp.inlay_hints').add_inlay_hint_support(client, bufnr)
      end, { desc = 'Enable InlayHints' })
    end
    diagnostics.setup_diagnostics_cursorhold(bufnr)
    if client:supports_method 'textDocument/codeAction' then
      require('lsp.code_action').on_attach(bufnr, client)
    end
    if client:supports_method 'workspace/diagnostic' then
      local folders = vim.lsp.buf.list_workspace_folders()
      VimRc.info 'LSP Client supports workspace diagnostics. Adding user command to fetch them. Current workspace folder: '
      VimRc.info(folders)
      diagnostics.setup_workspace_diagnostics(client, bufnr)
    end

    -- vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = false })

    -- Don't check for the capability here to allow dynamic registration of the request.
    vim.lsp.document_color.enable(true, bufnr)
    require('lsp.keys').on_attach(bufnr, client)
  end,
})

-- Diagnostic configuration.
diagnostics.setup()

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

-- Set up LSP servers.
vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
  once = true,
  callback = function()
    -- Extend neovim's client capabilities with the completion ones.
    vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities(nil, true) })
    vim.lsp.enable(lsp_servers)
  end,
})

vim.api.nvim_create_user_command('LspInfo', ':checkhealth vim.lsp', { desc = 'Alias to `:checkhealth vim.lsp`' })

vim.api.nvim_create_user_command('LspLog', function()
  local logfile = vim.lsp.log.get_filename()
  if vim.uv.fs_stat(logfile) then
    VimRc.exec.run_cmd { 'touch', vim.lsp.log.get_filename() }
  end

  vim.cmd(string.format('tabnew %s', logfile))
end, {
  desc = 'Opens the Nvim LSP client log.',
})

vim.api.nvim_create_user_command('LspLogClean', function()
  VimRc.exec.run_cmd { 'rm', vim.lsp.log.get_filename() }
  VimRc.exec.run_cmd { 'touch', vim.lsp.log.get_filename() }
end, {
  desc = 'Opens the Nvim LSP client log.',
})
local complete_client = function(arg)
  return vim
    .iter(vim.lsp.get_clients())
    :map(function(client)
      return client.name
    end)
    :filter(function(name)
      return name:sub(1, #arg) == arg
    end)
    :totable()
end

local get_local_lsp_dir = function()
  local vim_proj_folder = vim.fs.find({ '.vim' }, { path = vim.fn.getcwd(), type = 'directory', upward = true, stop = vim.fn.expand '$HOME' })[1]
  if not vim_proj_folder then
    return nil
  end
  local lsp_dir = vim_proj_folder .. '/lsp'
  local stat = vim.uv.fs_stat(lsp_dir)
  if stat and stat.type == 'directory' then
    return lsp_dir
  end
  return nil
end

local list_local_lsp_configs = function()
  local lsp_dir = get_local_lsp_dir()
  if not lsp_dir then
    return {}
  end
  local configs = {}
  for name, type in vim.fs.dir(lsp_dir) do
    if type == 'file' and name:sub(-4) == '.lua' then
      configs[name:sub(1, -5)] = lsp_dir .. '/' .. name
    end
  end
  return configs
end

local apply_local_lsp_configs = function()
  local configs = list_local_lsp_configs()
  local loaded = {}
  for server, path in pairs(configs) do
    local chunk, load_err = loadfile(path)
    if not chunk then
      vim.notify(("Failed to load local LSP config '%s': %s"):format(path, load_err), vim.log.levels.WARN)
    else
      local ok, config = pcall(chunk)
      if not ok then
        vim.notify(("Error running local LSP config '%s': %s"):format(path, config), vim.log.levels.WARN)
      elseif type(config) ~= 'table' then
        vim.notify(("Local LSP config '%s' must return a table"):format(path), vim.log.levels.WARN)
      else
        vim.lsp.config(server, config)
        table.insert(loaded, server)
      end
    end
  end
  table.sort(loaded)
  return loaded
end

local unique_list = function(items)
  local seen = {}
  local out = {}
  for _, item in ipairs(items) do
    if not seen[item] then
      seen[item] = true
      table.insert(out, item)
    end
  end
  return out
end

local complete_configured = function(arg)
  local names = {}
  local configs = vim.lsp.config._configs or {}
  for name, _ in pairs(configs) do
    if type(name) == 'string' and name ~= '*' then
      table.insert(names, name)
    end
  end
  for name, _ in pairs(list_local_lsp_configs()) do
    table.insert(names, name)
  end
  return vim
    .iter(unique_list(names))
    :filter(function(name)
      return name:sub(1, #arg) == arg
    end)
    :totable()
end

vim.api.nvim_create_user_command('LspReconfigure', function(info)
  local client_names = info.fargs
  apply_local_lsp_configs()

  -- Default to restarting all active servers
  if #client_names == 0 then
    client_names = vim
      .iter(vim.lsp.get_clients())
      :map(function(client)
        return client.name
      end)
      :totable()
  end
  for name in vim.iter(client_names) do
    if vim.lsp.config[name] == nil then
      vim.notify(("Invalid server name '%s'"):format(name))
    else
      vim.lsp.enable(name, false)
      vim.iter(vim.lsp.get_clients { name = name }):each(function(client)
        client:stop(true)
      end)
    end
  end

  local timer = assert(vim.uv.new_timer())
  timer:start(500, 0, function()
    for name in vim.iter(client_names) do
      vim.schedule_wrap(vim.lsp.enable)(name)
    end
  end)
end, {
  desc = 'Restart the given client',
  nargs = '?',
  bang = true,
  complete = complete_configured,
})
vim.api.nvim_create_user_command('LspLocalStart', function(info)
  local servers = info.fargs
  local local_loaded = apply_local_lsp_configs()

  -- Default to enabling all servers matching the filetype of the current buffer.
  -- This assumes that they've been explicitly configured through `vim.lsp.config`,
  -- otherwise they won't be present in the private `vim.lsp.config._configs` table.
  if #servers == 0 then
    if #local_loaded > 0 then
      servers = local_loaded
    else
      local filetype = vim.bo.filetype
      for name, _ in pairs(vim.lsp.config()) do
        local filetypes = vim.lsp.config[name].filetypes
        if filetypes and vim.tbl_contains(filetypes, filetype) then
          table.insert(servers, name)
        end
      end
    end
  end

  vim.lsp.enable(unique_list(servers))
end, {
  desc = 'Enable and launch a language server',
  nargs = '?',
  complete = complete_configured,
})
--

-- vim.api.nvim_create_user_command('LspStop', function(info)
--   local client_names = info.fargs
--
--   -- Default to disabling all servers on current buffer
--   if #client_names == 0 then
--     client_names = vim
--   .    .iter(vim.lsp.get_clients())
--       :map(function(client)
--         return client.name
--       end)
--       :totable()
--   end
--
--   for name in vim.iter(client_names) do
--     if vim.lsp.config[name] == nil then
--       vim.notify(("Invalid server name '%s'"):format(name))
--     else
--       vim.lsp.enable(name, false)
--       if info.bang then
--         vim.iter(vim.lsp.get_clients { name = name }):each(function(client)
--           client:stop(true)
--         end)
--       end
--     end
--   end
-- end, {
--   desc = 'Disable and stop the given client',
--   nargs = '?',
--   bang = true,
--   complete = complete_client,
-- })
