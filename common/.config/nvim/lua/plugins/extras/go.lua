return {
  'ray-x/go.nvim',
  dependencies = { -- optional packages
    'ray-x/guihua.lua',
    'neovim/nvim-lspconfig',
    'nvim-treesitter/nvim-treesitter',
    'mfussenegger/nvim-dap',
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'theHamsta/nvim-dap-virtual-text',
  },
  opts = {
    -- lsp_keymaps = false,
    --
    goimports = 'gopls', -- if set to 'gopls' will use gopls format, also goimports
    gofmt = 'gofumpt', -- if set to gopls will use gopls format
    -- max_line_len = 120, -- only effecteved when gofmt is 'golines'
    tag_transform = false,
    test_dir = '',
    comment_placeholder = '   ',
    -- icons = { breakpoint = '🧘', currentpos = '🏃' }, -- set to false to disable

    -- this option
    verbose = false,
    log_path = vim.fn.expand '$HOME' .. '/tmp/gonvim.log',
    lsp_cfg = false, -- false: do nothing
    -- true: apply non-default gopls setup defined in go/lsp.lua
    -- if lsp_cfg is a table, merge table with with non-default gopls setup in go/lsp.lua, e.g.
    lsp_gofumpt = false, -- true: set default gofmt in gopls format to gofumpt
    lsp_on_attach = nil, -- nil: do nothing
    -- if lsp_on_attach is a function: use this function as on_attach function for gopls,
    -- when lsp_cfg is true
    lsp_keymaps = true, -- true: apply default lsp keymaps
    lsp_codelens = true,
    diagnostic = { -- set diagnostic to false to disable vim.diagnostic setup
      -- in go.nvim
      hdlr = false, -- hook lsp diag handler and send diag to quickfix
      underline = true,
      -- virtual text setup
      virtual_text = { spacing = 0, prefix = '■' },
      signs = true,
      update_in_insert = false,
    },
    lsp_inlay_hints = {
      enable = true,
    },
    gopls_remote_auto = true,
    gocoverage_sign = '█',
    sign_priority = 7,
    dap_delve_config = {
      stopOnEntry = true,
      logOutput = 'dap-ui',
    },
    dap_debug = true,
    dap_debug_gui = true,
    dap_debug_keymap = true, -- true: use keymap for debugger defined in go/dap.lua
    -- false: do not use keymap in go/dap.lua.  you must define your own.
    -- windows: use visual studio style of keymap
    dap_vt = true, -- false, true and 'all frames'
    textobjects = true,
    gopls_cmd = nil, --- you can provide gopls path and cmd if it not in PATH, e.g. cmd = {  "/home/ray/.local/nvim/data/lspinstall/go/gopls" }
    build_tags = '', --- you can provide extra build tags for tests or debugger
    test_runner = 'go', -- one of {`go`, `richgo`, `dlv`, `ginkgo`}
    run_in_floaterm = false, -- set to true to run in float window.
    luasnip = false, -- set true to enable included luasnip
    iferr_vertical_shift = 4, -- defines where the cursor will end up vertically from the begining of if err statement after GoIfErr command
    -- other options
  },
  config = function(_, opts)
    require('go').setup(opts)
  end,
  event = { 'CmdlineEnter' },
  ft = { 'go', 'gomod' },
  build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
}
