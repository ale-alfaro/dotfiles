return {
  cmd = { 'ty', 'server' },
  root_markers = { 'uv.lock', 'pyproject.toml', 'ty.toml' },
  settings = {
    ty = {
      diagnosticMode = 'workspace',
      experimental = {
        autoImport = true,
        rename = true,
      },
      inlayHints = {
        variableTypes = false,
        callArgumentNames = false,
      },
    },
  },
}
