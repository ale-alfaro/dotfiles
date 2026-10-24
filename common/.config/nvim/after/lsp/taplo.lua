---@return vim.lsp.Config
return {
    cmd = { 'taplo', 'lsp', '--no-auto-config', 'stdio' },
    filetypes = { 'toml' },
    root_dir = function(bufnr, on_dir)
        local path = vim.api.nvim_buf_get_name(bufnr)
        local ext = vim.fs.ext(path)
        if ext and string.match(ext, 'toml$') then
            on_dir(vim.fs.dirname(path))
        end
    end,
    -- settings = {
  --   -- Use the defaults that the VSCode extension uses: https://github.com/tamasfe/taplo/blob/2e01e8cca235aae3d3f6d4415c06fd52e1523934/editors/vscode/package.json
  --   taplo = {
  --     configFile = { enabled = false},
  --   },
  -- },
  -- before_init = function (_, cfg)
  --   cfg.settings.taplo.schemas = require('schemastore').json.load()
  -- end
}
