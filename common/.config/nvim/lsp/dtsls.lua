
---@type vim.lsp.Config
return {
  cmd = { "devicetree-language-server", '--stdio' },
  -- nvim maps .dts/.dtsi/.overlay all to the `dts` filetype.
  filetypes = { 'dts' },
  root_markers = { '.west' },
  capabilities = {
    textDocument = {
      foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      },
      formatting = {
        dynamicRegistration = false,
      },
      semanticToken = {
        dynamicRegistration = false,
        requests = {
          range = false,
          full = true,
        },
        tokenTypes = {
          'namespace',
          'class',
          'enum',
          'interface',
          'struct',
          'typeParameter',
          'type',
          'parameter',
          'variable',
          'property',
          'enumMember',
          'decorator',
          'event',
          'function',
          'method',
          'macro',
          'label',
          'comment',
          'string',
          'keyword',
          'number',
          'regexp',
          'operator',
        },
        tokenModifiers = {
          'declaration',
          'definition',
          'readonly',
          'static',
          'deprecated',
          'abstract',
          'async',
          'modification',
          'documentation',
          'defaultLibrary',
        },
        formats = { 'relative' },
      },
    },
  },
  settings = {
    devicetree = {
      defaultBindingType = 'Zephyr',
      defaultIncludePaths = {
        './external/zephyr/dts',
        './external/zephyr/dts/arm',
        './external/zephyr/dts/arm64',
        './external/zephyr/dts/riscv',
        './external/zephyr/dts/common',
        './external/zephyr/dts/vendor',
        './external/zephyr/include',
      },
      defaultZephyrBindings = { './external/zephyr/dts/bindings'},
      autoChangeContext = true,
      allowAdhocContexts = true,
      contexts = {},
    },
  },
}
