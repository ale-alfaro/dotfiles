vim.pack.add(_G.plug_spec {
  'neovim/nvim-lspconfig',
  'rachartier/tiny-code-action.nvim',
})
-- local diagnostics_opts = {
--   virtual_text = {
--     spacing = 4,
--     source = 'if_many',
--     prefix = '●',
--     current_line = true,
--     -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
--     -- prefix = "icons",
--   },
--   severity_sort = true,
--   signs = { priority = 9999, severity = { min = 'WARN', max = 'ERROR' } },
--   -- Don't update diagnostics when typing
--   update_in_insert = false,
--   underline = { severity = { min = 'HINT', max = 'ERROR' } },
-- }
-- vim.diagnostic.config(diagnostics_opts)
VimRc.lsp.config()
-- build = 'cargo install --release',
-- get all the servers that are available through mason-lspconfig
local lspau = vim.api.nvim_create_augroup('vimrc.lsp', {})
-- Update mappings when registering dynamic capabilities.
local register_capability = vim.lsp.handlers['client/registerCapability']
vim.lsp.handlers['client/registerCapability'] = function(err, res, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  if not client then
    return
  end

  VimRc.lsp.on_attach(client, vim.api.nvim_get_current_buf())
  return register_capability(err, res, ctx)
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = lspau,
  desc = 'Configure LSP keymaps',
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    -- I don't think this can happen but it's a wild world out there.
    if not client then
      return
    end

    VimRc.lsp.on_attach(client, args.buf)
  end,
})

local lsp_servers = {
  'lua_ls',
  'clangd',
  'ruff',
  'ty',
  'bashls',
  'taplo',
  'yamls',
  'jsonls',
  'basedpyright',
  'dts-lsp',
}
-- -- Set up LSP servers.
vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
  group = lspau,
  once = true,
  callback = function()
    -- stylua: ignore
    local server_configs = vim.iter(vim.api.nvim_get_runtime_file('lsp/*.lua', true))
        :map(function(file)
          return vim.fn.fnamemodify(file, ':t:r')
        end)
        :filter(function(file_name)
          return vim.list_contains(lsp_servers, file_name)
        end)
        :totable()
    vim.lsp.enable(server_configs)
  end,
})
