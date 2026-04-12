local M = {}

M.setup = function()
  --- https://github.com/redhat-developer/yaml-language-server
  ---
  --- `yaml-language-server` can be installed via `yarn`:
  --- ```sh
  --- yarn global add yaml-language-server
  --- ```
  ---
  --- To use a schema for validation, there are two options:
  ---
  --- 1. Add a modeline to the file. A modeline is a comment of the form:
  ---
  --- ```
  --- # yaml-language-server: $schema=<urlToTheSchema|relativeFilePath|absoluteFilePath}>
  --- ```
  ---
  --- where the relative filepath is the path relative to the open yaml file, and the absolute filepath
  --- is the filepath relative to the filesystem root ('/' on unix systems)
  ---
  --- 2. Associated a schema url, relative , or absolute (to root of project, not to filesystem root) path to
  --- the a glob pattern relative to the detected project root. Check `:checkhealth vim.lsp` to determine the resolved project
  --- root.
  ---
  --- ```lua
  --- vim.lsp.config('yamlls', {
  ---   ...
  ---   settings = {
  ---     yaml = {
  ---       ... -- other settings. note this overrides the lspconfig defaults.
  ---       schemas = {
  ---         ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
  ---         ["../path/relative/to/file.yml"] = "/.github/workflows/*",
  ---         ["/path/from/root/of/project"] = "/.github/workflows/*",
  ---       },
  ---     },
  ---   }
  --- })
  local yaml_schemas = require('schemastore').yaml.schemas()
  vim.lsp.config('yamlls', {
    settings = {
      yaml = {
        schemas = yaml_schemas,
        validate = { enable = true },
        format = { enable = true },
      },
    },
  })
  local json_schemas = require('schemastore').json.schemas()
  vim.lsp.config('jsonls', {
    settings = {
      json = {
        schemas = json_schemas,
        validate = { enable = true },
      },
    },
  })
end

return M
