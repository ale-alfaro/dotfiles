---@type vim.lsp.Config
return {
  cmd = { 'devicetree-language-server', '--stdio' },
  filetypes = { 'dts', 'dtsi' },
  root_markers = { '.west', '.git', '.' },
  on_attach = function(client, bufnr)
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    local zephyr_base = vim.fn.getenv 'ZEPHYR_BASE'
    if zephyr_base ~= vim.v.null and vim.uv.fs_stat(zephyr_base) then
      local topdir = vim.fn.getenv 'WEST_TOPDIR'
      local cwd = vim.fn.getcwd()
      if topdir ~= vim.v.null and vim.uv.fs_stat(topdir) then
        cwd = topdir
      end

      client.settings.devicetree = {
        defaultIncludePaths = {
          zephyr_base .. '/dts',
          zephyr_base .. '/dts/arm',
          zephyr_base .. '/dts/arm64/',
          zephyr_base .. '/dts/riscv',
          zephyr_base .. '/dts/common',
          zephyr_base .. '/dts/vendor',
          zephyr_base .. '/include',
        },
        cwd = cwd,
        defaultZephyrBindings = {
          zephyr_base .. 'dts/bindings',
        },
        defaultBindingType = 'Zephyr',
        autoChangeContext = true,
        allowAdhocContexts = true,
        contexts = {
          {
            dtsFile = zephyr_base .. '/boards/native/native_sim/native_sim.dts',
            overlays = { cwd .. '/sh_sdk/tests/bmi323/boards/native_sim.overlay' },
          },
        },
      }
    end
    -- Enable semantic tokens
    capabilities.textDocument = capabilities.textDocument or {}
    capabilities.textDocument.semanticTokens = {
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
    }

    -- Enable formatting
    capabilities.textDocument.formatting = {
      dynamicRegistration = true,
    }

    -- Enable folding range support
    capabilities.textDocument.foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    }

    _G.info 'Custom devicetree_ls LSP loaded with semantic tokens & folding'

    -- Setup the LSP
    client.capabilities = capabilities
  end,
}
