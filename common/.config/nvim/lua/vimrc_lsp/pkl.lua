local bin_path = vim.g.pkl_bin_path or vim.fs.joinpath(vim.env['HOME'], '.local', 'bin', 'pkl-lsp-0.7.1.jar')
VimRc.info 'Registering the pkl-lsp'
---@alias LspHandlerCtx {method:string,client_id:number,bufnr:number,params?:table,version:number}
---Opens the provided `pkl-lsp://` scheme file in the current buffer.
---
---@param fname string URI of the file to open
local function open_lspfile(fname)
  local buf = vim.api.nvim_get_current_buf()
  local client = vim.lsp.get_clients({ name = 'pkl' })[1]
  assert(client, 'No Pkl LSP instance found attached to the current buffer')
  local timeout_ms = 5000
  vim.bo[buf].modifiable = true
  vim.bo[buf].swapfile = false
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].filetype = 'pkl'
  local function handler(err, result)
    assert(not err, vim.inspect(err))
    local normalized = string.gsub(result, '\r\n', '\n')
    local source_lines = vim.split(normalized, '\n', { plain = true })

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, source_lines)
    vim.bo[buf].modifiable = false
  end
  local out = client:request_sync('pkl/fileContents', { uri = fname }, timeout_ms, buf)
  if out then
    handler(out.err, out.result)
  else
    VimRc.err 'Failed to run pkl/fileContents'
  end
end
vim.api.nvim_create_autocmd('BufReadCmd', {
  pattern = 'pkl-lsp://*',
  callback = function()
    open_lspfile(vim.fn.expand '<amatch>')
  end,
})
---Tells the existing Pkl LSP to run the syncProjects action.
---Scans the workspace directories for PklProject files, and creates a graph of dependencies.
---@param ctx LspHandlerCtx
local function sync_projects(ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)()
  assert(client, 'No Pkl LSP instance found attached to the current buffer')
  client:request('pkl/syncProjects', nil, function() end, ctx.bufnr)
end

---Tells the LSP to download the specified package.
---This requires that `vim.g.pkl_neovim.pkl_cli_path` has been set to the Pkl executable.
---@param packageUri string
---@param ctx LspHandlerCtx
local function download_package(packageUri, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)

  assert(client, 'No Pkl LSP instance found attached to the current buffer')
  client:request_sync('pkl/downloadPackage', { uri = packageUri }, 1000, ctx.bufnr)
end
---@type vim.lsp.Config
vim.lsp.config['pkl'] = {
  -- name = 'pkl',
  filetypes = { 'pkl' },
  settings = {
    ['pkl.cli.path'] = bin_path,
    -- ['pkl.formatter.grammarVersion'] = config.pkl_formatter_grammar_version,
    -- ['pkl.projects.excludedDirectories'] = config.pkl_projects_excluded_directories,
    -- ['pkl.modulepath'] = config.pkl_modulepath,
  },
  -- first look for a `.pkl-lsp` dir
  -- failing that, look for a `.git` dir
  -- failing that, look for a PklProject file
  root_markers = { 'hk.pkl', '.git' },
  cmd = { 'java', '-jar', bin_path },
  handlers = {
    ['pkl/actionableNotification'] = function(_, notification, ctx)
      local commands_iter = vim.iter(notification.commands)

      local titles = commands_iter
        :map(function(it)
          return it.title
        end)
        :totable()

      local client = vim.lsp.clients.find_by_id(ctx.client_id)
      if not client then
        return
      end
      local msgprefix = {
        [1] = '[ERROR] ',
        [2] = '[WARNING] ',
      }
      vim.ui.select(titles, {
        prompt = msgprefix[notification.type] .. notification.message,
      }, function(response)
        if not response then
          return
        end
        local command = commands_iter:find(function(it)
          return it.title == response
        end)
        if not command then
          return
        end
        client:exec_cmd(command, { bufnr = ctx.bufnr })
      end)
    end,
  },
  commands = {
    ['pkl.syncProjects'] = function(_, ctx)
      sync_projects(ctx)
    end,
    ['pkl.downloadPackage'] = function(cmd, ctx)
      assert(#cmd.arguments == 1, 'Expected one argument')
      download_package(cmd.arguments[1], ctx)
    end,
  },
  init_options = {
    extendedClientCapabilities = {
      actionableRuntimeNotifications = true,
    },
  },
}
vim.lsp.enable 'pkl'
