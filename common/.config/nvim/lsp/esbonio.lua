return {
  cmd = { 'uv', 'run', 'esbonio' },
  filetypes = { 'rst' }, -- or 'markdown' if you use MyST
  root_markers = { 'pyproject.toml', 'uv.lock', '.git' },
  on_init = function(client)
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if vim.uv.fs_stat(path .. '/.vim/lsp/esbonio.lua') then
        client.config.init_options = vim.tbl_deep_extend('force', client.config.init_options, require(path .. '/.vim/lsp/esbonio.lua'))
        return
      end
    end
  end,
  init_options = {
    server = {
      logLevel = 'debug',
    },
    -- sphinx = {
    --   confDir = '/path/to/docs',
    --   srcDir = '${confDir}/../docs-src',
    -- },
  },
}
