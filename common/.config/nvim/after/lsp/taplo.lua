local catalogs = require('schemastore').json.load()
return {
  cmd = { 'taplo', 'lsp', 'stdio' },
  filetypes = { 'toml' },
  root_markers = { "mise.toml", '.taplo.toml', 'taplo.toml', '.git' },

    settings = {
      -- Use the defaults that the VSCode extension uses: https://github.com/tamasfe/taplo/blob/2e01e8cca235aae3d3f6d4415c06fd52e1523934/editors/vscode/package.json
      taplo = {
        configFile = { enabled = true },
        schema = {
          enabled = true,
          catalogs = catalogs,
          cache = {
            memoryExpiration = 60,
            diskExpiration = 600,
          },
        },
      },
    },
}
