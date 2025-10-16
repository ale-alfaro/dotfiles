---@module "mini.nvim"
-- ┌─────────────────────────┐
-- │ Plugins outside of MINI │
-- └─────────────────────────┘
--
-- This file contains installation and configuration of plugins outside of MINI.
-- They significantly improve user experience in a way not yet possible with MINI.
-- These are mostly plugins that provide programming language specific behavior.
--
-- Use this file to install and configure other such plugins.

-- Make concise helpers for installing/adding plugins in two stages.
-- Add some plugins now if Neovim is started like `nvim -- some-file` because
-- they are needed during startup to work correctly.
local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later
local now_if_args = vim.fn.argc(-1) > 0 and now or later


-- Tree-sitter ================================================================

-- Tree-sitter is a tool for fast incremental parsing. It converts text into
-- a hierarchical structure (called tree) that can be used to implement advanced
-- and/or more precise actions: syntax highlighting, textobjects, indent, etc.
--
-- Tree-sitter support is built into Neovim (see `:h treesitter`). However, it
-- requires two extra pieces that don't come with Neovim directly:
-- - Language parsers: programs that convert text into trees. Some are built-in
--   (like for Lua), 'nvim-treesitter' provides many others.
-- - Query files: definitions of how to extract information from trees in
--   a useful manner (see `:h treesitter-query`). 'nvim-treesitter' also provides
--   these, while 'nvim-treesitter-textobjects' provides the ones for Neovim
--   textobjects (see `:h text-objects`, `:h MiniAi.gen_spec.treesitter()`).
--
-- Add these plugins now if file (and not 'mini.starter') is shown after startup.
now_if_args(function()
  add({
    source = 'nvim-treesitter/nvim-treesitter',
    -- Use `main` branch since `master` branch is frozen, yet still default
    checkout = 'main',
    -- Update tree-sitter parser after plugin is updated
    hooks = { post_checkout = function() vim.cmd('TSUpdate') end },
  })
  add({
    source = 'nvim-treesitter/nvim-treesitter-textobjects',
    -- Same logic as for 'nvim-treesitter'
    checkout = 'main',
  })

  -- Ensure installed parsers for listed languages. Add to `languages`
  -- array languages which you want to have installed. To see available languages:
  -- - Execute `:=require('nvim-treesitter').get_available()`
  -- - Visit
  --   https://github.com/nvim-treesitter/nvim-treesitter/blob/main/SUPPORTED_LANGUAGES.md
  local ensure_languages = {
    -- These are already installed. Used as an example.
    'bash',
    'c',
    'cpp',
    'cmake',
    'diff',
    'html',
    'kconfig',
    'lua',
    'luadoc',
    'markdown',
    'markdown_inline',
    'query',
    'vim',
    'vimdoc',
    'just',
    'json5',
    'toml',
    "ninja",
    "rst"
  }
  local isnt_installed = function(lang)
    return #vim.api.nvim_get_runtime_file('parser/' .. lang .. '.*', false) == 0
  end
  local to_install = vim.tbl_filter(isnt_installed, ensure_languages)
  if #to_install > 0 then require('nvim-treesitter').install(to_install) end

  -- Ensure tree-sitter enabled after opening a file for target language
  local filetypes = {}
  for _, lang in ipairs(ensure_languages) do
    for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
      table.insert(filetypes, ft)
    end
  end
  local ts_start = function(ev) vim.treesitter.start(ev.buf) end
  _G.Config.new_autocmd('FileType', filetypes, ts_start, 'Start tree-sitter')
end)

-- Language servers ===========================================================

-- Language Server Protocol (LSP) is a set of conventions that power creation of
-- language specific tools. It requires two parts:
-- - Server - program that performs language specific computations.
-- - Client - program that asks server for computations and shows results.
--
-- Here Neovim itself is a client (see `:h vim.lsp`). Language servers need to
-- be installed separately based on your OS, CLI tools, and preferences.
-- See note about 'mason.nvim' at the bottom of the file.
--
-- Neovim's team collects commonly used configurations for most language servers
-- inside 'neovim/nvim-lspconfig' plugin.
--
-- Add it now if file (and not 'mini.starter') is shown after startup.
now_if_args(function()
  add('neovim/nvim-lspconfig')

  -- Use `:h vim.lsp.enable()` to automatically enable language server based on
  -- the rules provided by 'nvim-lspconfig'.
  -- Use `:h vim.lsp.config()` or 'ftplugin/lsp/' directory to configure servers.
  vim.lsp.config('lua_ls', {
    stylua = { enabled = false },
    lua_ls = {
      cmd = { 'lua-language-server' },
      filetypes = { 'lua' },
      root_markers = {
        '.luarc.json',
        '.luarc.jsonc',
        '.luacheckrc',
        '.stylua.toml',
        'stylua.toml',
        'selene.toml',
        'selene.yml',
        '.git',
      },
      -- mason = false, -- set to false if you don't want this server to be installed with mason
      -- Use this to add any additional keymaps
      -- for specific lsp servers
      -- ---@type LazyKeysSpec[]
      -- keys = {},
      settings = {
        Lua = {
          workspace = {
            checkThirdParty = false,
          },
          codeLens = {
            enable = true,
          },
          completion = {
            callSnippet = 'Replace',
          },
          doc = {
            privateName = { '^_' },
          },
          hint = {
            enable = true,
            setType = false,
            paramType = true,
            paramName = 'Disable',
            semicolon = 'Disable',
            arrayIndex = 'Disable',
          },
        },
      },
    },
  })
  -- Uncomment and tweak the following `vim.lsp.enable()` call to enable servers.
  vim.lsp.enable({
    "lua_ls", "ruff", "ty", "bashls", "taplo", "yamls", "jsonls"
    --   -- For example, if `lua-language-server` is installed, use `'lua_ls'` entry
  })
end)

-- Formatting =================================================================

-- Programs dedicated to text formatting (a.k.a. formatters) are very useful.
-- Neovim has built-in tools for text formatting (see `:h gq` and `:h 'formatprg'`).
-- They can be used to configure external programs, but it might become tedious.
--
-- The 'stevearc/conform.nvim' plugin is a good and maintained solution for easier
-- formatting setup.
later(function()
  add('stevearc/conform.nvim')

  -- See also:
  -- - `:h Conform`
  -- - `:h conform-options`
  -- - `:h conform-formatters`
  require('conform').setup({
    -- Map of filetype to formatters
    -- Make sure that necessary CLI tool is available
    formatters = {
      -- # Example of using shfmt with extra args
      shfmt = {
        prepend_args = { '-i', '2', '-ci' },
      },
      just = {
        env = {
          JUST_UNSTABLE = 1,
        },
      },
    },
    formatters_by_ft = {
      python = {
        -- To fix auto-fixable lint errors.
        'ruff_fix',
        -- To run the Ruff formatter.
        'ruff_format',
        -- To organize the imports.
        'ruff_organize_imports',
      },
      zsh = { 'shfmt' },
      markdown = { 'mdformat' },
      yaml = { 'yamlfmt' },
      just = { 'just' },
      -- ['*'] = { 'codespell' },
      -- ['_'] = { 'trim_whitespace' },
    }
  })
end)

later(function()
  add('benomahony/uv.nvim')

  require('uv').setup({
    keymaps = {
      prefix = '<leader>x',    -- Main prefix for uv commands
      commands = true,         -- Show uv commands menu (<leader>x)
      run_file = false,        -- Run current file (<leader>xr)
      run_selection = false,   -- Run selected code (<leader>xs)
      run_function = false,    -- Run function (<leader>xf)
      venv = true,             -- Environment management (<leader>xe)
      init = true,             -- Initialize uv project (<leader>xi)
      add = true,              -- Add a package (<leader>xa)
      remove = true,           -- Remove a package (<leader>xd)
      sync = false,            -- Sync packages (<leader>xc)
      sync_all = false,        -- Sync all packages, extras and groups (<leader>xC)
    }
  })

  require('custom.python.uv').setup()
end)


-- Snippets ===================================================================

-- Although 'mini.snippets' provides functionality to manage snippet files, it
-- deliberately doesn't come with those.
--
-- The 'rafamadriz/friendly-snippets' is currently the largest collection of
-- snippet files. They are organized in 'snippets/' directory (mostly) per language.
-- 'mini.snippets' is designed to work with it as seamlessly as possible.
-- See `:h MiniSnippets.gen_loader.from_lang()`.
later(function() add('rafamadriz/friendly-snippets') end)

local pattern = '([^:]+):(%d+):(%d+):(%d+):(%d+): (%a+): (.*) %[(%a[%a-]+)%]'
local groups = { 'file', 'lnum', 'col', 'end_lnum', 'end_col', 'severity', 'message', 'code' }
local severities = {
  error = vim.diagnostic.severity.ERROR,
  warning = vim.diagnostic.severity.WARN,
  note = vim.diagnostic.severity.HINT,
}
-- nvim-lint
later(function()
  add('mfussenegger/nvim-lint')
  local Lint = require('lint')

  -- Event to trigger linters
  Lint.linters_by_ft = {
    cmake = { 'cmakelint' },              -- Install: uv tool install cmakelint, repo: https://github.com/cmake-lint/cmake-lint
    python = { 'ruff', 'ty' },
    yaml = { 'yamlint' },                 --Install: uv tool install yamllint, repo: https://github.com/adrienverge/yamllint
    zsh = { 'zsh' },
    ['yaml.ghaction'] = { 'actionlint' }, -- Install: go install github.com/rhysd/actionlint/cmd/actionlint@latest, repo: https://github.com/rhysd/actionlint
  }
  Lint.linters = {
    ty = {
      cmd = 'ty',
      stdin = false,
      stream = 'stdout',
      ignore_exitcode = true,
      args = {
        'check',
        '--output-format',
        'concise',
        '--color',
        'never',
      },
      parser = require('lint.parser').from_pattern(pattern, groups, severities, { ['source'] = 'ty' },
        { end_col_offset = 0 }),
    }
  }

  -- local lint_progress = function()
  --   local linters = require("lint").get_running()
  --   if #linters == 0 then
  --     return "󰦕"
  --   end
  --   return "󱉶 " .. table.concat(linters, ", ")
  -- end
  -- vim.api.nvim_create_user_command("ViewLinter", lint_progress, {
  --   desc = 'View Running Linters',
  -- })
end)

--
-- local ns = require("lint").get_namespace("my_linter_name")
-- vim.diagnostic.config({ virtual_text = true }, ns)
-- Smart Splits
now(function()
 add(
   {
     source = 'mrjones2014/smart-splits.nvim',
     depends = {
       'folke/snacks.nvim',
     },
   }
 )
 -- add(spec[1])
 --
 local spec = require('custom.better_mux')
 -- for _, dep in ipairs(spec.dependencies) do add(type(dep) == 'string' and dep or dep[1]) end
 local opts = spec.opts or {}
 require('smart-splits').setup(opts)
 for _, key in ipairs(spec.keys) do
   _G.nmap(key[1], key[2], key[3])
 end
 require('custom.wezterm.wezterm_terminal').setup()
end)
--
-- -- Bookmarks
-- later(function()
--   local spec = require('plugins.bookmarks')
--   add(spec[1])
--   for _, dep in ipairs(spec.dependencies) do add(dep[1]) end
--   spec.config()
-- end)
--
-- -- Obsidian
-- later(function()
--   local spec = require('plugins.obsidian')[1][1]
--   add(spec[1])
--   require('obsidian').setup(spec.opts)
--   if spec.post_setup then spec.post_setup() end
-- end)

-- Python / uv.nvim
-- later(function()
--   local spec = require('custom.python')[1]
--   add(spec[1])
--   spec.config(spec, spec.opts or {})
-- end)
-- Honorable mentions =========================================================

-- 'mason-org/mason.nvim' (a.k.a. "Mason") is a great tool (package manager) for
-- installing external language servers, formatters, and linters. It provides
-- a unified interface for installing, updating, and deleting such programs.
--
-- The caveat is that these programs will be set up to be mostly used inside Neovim.
-- If you need them to work elsewhere, consider using other package managers.
--
-- You can use it like so:
later(function()
  add(
    add({
      source = "saghen/blink.cmp",
      version = "main",
      depends = { "rafamadriz/friendly-snippets" },
    })
  )
  require('blink-cmp').setup({
    keymap = {
      preset = 'enter',
      ['<C-y>'] = { 'select_and_accept' },
    },
    appearance = {
      use_nvim_cmp_as_default = true,
      nerd_font_variant = 'mono',
    },
    completion = {
      accept = {
        auto_brackets = {
          enabled = true,
        },
      },
      menu = {
        draw = {
          treesitter = { 'lsp' },
        },
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 200,
      },
      ghost_text = {
        enabled = true,
      },
      trigger = {
        prefetch_on_insert = true,
        show_on_keyword = true,
        show_on_trigger_character = true,
        show_in_snippet = true,
        show_on_insert_on_trigger_character = true,
        show_on_accept_on_trigger_character = true,
      },
      list = {
        selection = {
          auto_insert = false,
          preselect = function(ctx)
            return ctx.mode ~= 'cmdline' and not require('blink.cmp').snippet_active { direction = 1 }
          end,
        },
      },
    },   -- completion
    signature = { enabled = true },
    sources = {
      compat = {},
      default = { 'lsp', 'path', 'snippets', 'buffer' },
      per_filetype = {
        lua = { inherit_defaults = true, 'lazydev' },
      },
      providers = {
        lazydev = {
          name = 'LazyDev',
          module = 'lazydev.integrations.blink',
          score_offset = 100,
        },
        lsp = { async = true, score_offset = 70 },
        snippets = { score_offset = 1, max_items = 3 },
      },
    },   -- sources
    cmdline = {
      enabled = true,
      keymap = { preset = 'cmdline' },
      completion = {
        list = { selection = { preselect = false } },
        menu = {
          auto_show = function(ctx)
            return vim.fn.getcmdtype() == ':'
          end,
        },
        ghost_text = { enabled = true },
      },
    },   --cmdline
  })
end)


now(function() add('nvim-lua/plenary.nvim') end)
-- Beautiful, usable, well maintained color schemes outside of 'mini.nvim' and
-- have full support of its highlight groups. Use if you don't like 'miniwinter'
-- enabled in 'plugin/30_mini.lua' or other suggested 'mini.hues' based ones.
now(function()
  -- Install only those that you need
  -- add('sainnhe/everforest')
  -- add('Shatur/neovim-ayu')
  -- add('ellisonleao/gruvbox.nvim')

  add('folke/tokyonight.nvim')

  require('tokyonight').setup({
    transparent = true,
    styles = {
      sidebars = 'transparent',
      floats = 'transparent',
    },
  })
  -- Enable only one
  vim.cmd('color tokyonight')
end)

now(function()
  add({ source = 'folke/snacks.nvim' })

  require('snacks').setup({
    bigfile = { enabled = false },
    dashboard = { enabled = false },
    explorer = { enabled = false },
    indent = { enabled = false },
    input = { enabled = true },
    notifier = {
      enabled = false,
      timeout = 3000,
    },
    quickfile = { enabled = false },
    scope = { enabled = false },
    scroll = { enabled = false },
    statuscolumn = { enabled = false },
    words = { enabled = false },
    styles = {
      notification = {},
    },
    terminal = { enabled = false },
    picker = {
      enabled = true,
      ---@type snacks.picker.Action.fn[]
      actions = {
        ---@param p snacks.Picker
        ---@param item snacks.picker.Item
        run_cmd = function(p, item)
          local uv = require 'custom.python.uv'
          uv.uv_run_tool_call(p, item)
        end,
      },
    },
  })
end)
