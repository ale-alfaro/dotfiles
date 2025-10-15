return {
  root_markers = {
    'pyproject.toml',
    'uv.lock',
    'pyproject.lock',
  },
  settings = {
    basedpyright = {
      analysis = {
        autoSearchPaths = true,
        -- useLibraryCodeForTypes = true,
        diagnosticMode = 'off',
        typeCheckingMode = 'off',         -- Set type-checking mode to off
      },
    },
  },
  -- capabilities = {
  --   offsetEncoding = { 'utf-16' },
  -- },
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightOrganizeImports', function()
      local params = {
        command = 'basedpyright.organizeimports',
        arguments = { vim.uri_from_bufnr(bufnr) },
      }

      -- Using client.request() directly because "basedpyright.organizeimports" is private
      -- (not advertised via capabilities), which client:exec_cmd() refuses to call.
      -- https://github.com/neovim/neovim/blob/c333d64663d3b6e0dd9aa440e433d346af4a3d81/runtime/lua/vim/lsp/client.lua#L1024-L1030
      client.request('workspace/executeCommand', params, nil, bufnr)
    end, {
      desc = 'Organize Imports',
    })
  end,
}
