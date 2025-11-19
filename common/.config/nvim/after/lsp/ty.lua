return {
  cmd = { 'uv', 'run', 'ty', 'server' },
  root_markers = { 'uv.lock', 'pyproject.toml', 'ty.toml' },
  settings = {
    ty = {
      -- disableLanguageServices = true,
      diagnosticMode = 'workspace',
      experimental = {
        autoImport = true,
        rename = true,
      },
      inlayHints = {
        variableTypes = true,
        callArgumentNames = true,
      },
    },
  },
}
