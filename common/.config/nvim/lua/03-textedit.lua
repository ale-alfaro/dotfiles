-- Treesitter
require 'plugin.mini-textedit'

_G.new_autocmd("PackChanged", function(ev)
  local kind = ev.data.kind
  local spec = ev.data.spec
  vim.validate("kind", kind, "string")
  vim.validate("spec", spec, "table")
  if not vim.list_contains({ "install", "update", "delete" }, kind) then
    _G.error("PackChanged event didn not contain expected kind value")
    return
  end
  if spec.name == "nvim-treesitter"
      and kind ~= "deleted" then
    vim.cmd [[ TSUpdate ]]
  end
end, "TSUpdate after installing treesitter")
local function gh(plug)
  return 'https://github.com/' .. plug
end
vim.pack.add {
  {
    src = gh 'nvim-treesitter/nvim-treesitter',
    version = 'main',
  },
}

local ensure_installed = {
  'bash',
  'c',
  'cpp',
  'cmake',
  'diff',
  'devicetree',
  'jsdoc',
  'json',
  'jsonc',
  'json5',
  'just',
  'kconfig',
  'lua',
  'luadoc',
  'luap',
  'markdown',
  'markdown_inline',
  'ninja',
  'printf',
  'python',
  'query',
  'regex',
  'rst',
  'toml',
  'vim',
  'vimdoc',
  'xml',
  'yaml',
}

require('nvim-treesitter').setup {
  ensure_installed = ensure_installed,
  highlighter = true,
}

_G.new_autocmd('FileType', function(ev)
  local ft, lang = ev.match, vim.treesitter.language.get_lang(ev.match)
  -- if not VimRc.treesitter_have(ft) then
  --   return
  -- end
  -- highlighting
  local ok, _ = pcall(vim.treesitter.start)
  if not ok then
    _G.error("Couldn't not start treesitter for filetype: " .. ft .. ' lang: ' .. lang)
    return
  end
  -- indents
  vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  -- indentation, provided by nvim-treesitter
  vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end, "Nvim-Treesitter start")

vim.pack.add(
  {
    { src = 'https://github.com/rafamadriz/friendly-snippets' }, --dependecy goes first,
    { src = 'https://github.com/L3MON4D3/LuaSnip',            version = '2.4.0' },
  }
)


_G.keymaps_define {
  {
    mode = 'i',
    lhs = '<C-r>s',
    rhs = function()
      require('luasnip.extras.otf').on_the_fly 's'
    end,
    { desc = 'Insert on-the-fly snippet' },
  },
  -- Use <C-c> to select a choice in a snippet.
  {
    mode = { 'i', 's' },
    lhs = '<C-c>',
    rhs = function()
      if require('luasnip').choice_active() then
        require 'luasnip.extras.select_choice' ()
      end
    end,
    { desc = 'Select choice' },
  },
}

local types = require 'luasnip.util.types'
local luasnip = require 'luasnip'

---@diagnostic disable: undefined-field
luasnip.setup {
  -- Check if the current snippet was deleted.
  delete_check_events = 'TextChanged',
  -- Display a cursor-like placeholder in unvisited nodes
  -- of the snippet.
  ext_opts = {
    [types.insertNode] = {
      unvisited = {
        virt_text = { { '|', 'Conceal' } },
        virt_text_pos = 'inline',
      },
    },
    [types.exitNode] = {
      unvisited = {
        virt_text = { { '|', 'Conceal' } },
        virt_text_pos = 'inline',
      },
    },
    [types.choiceNode] = {
      active = {
        virt_text = { { '(snippet) choice node', 'LspInlayHint' } },
      },
    },
  },
}

require('luasnip.loaders.from_vscode').lazy_load()



---@type VimPackBuildHooks
local blink_build_hook = {
  plugin = "blink.cmp",
  build_cmd_type = BuildHookCmdTypes.shell,
  build_cmd = 'cargo build --release'
}
vim.pack.add { _G.plug('Saghen/blink.cmp', blink_build_hook) }
require 'plugin.blink-cmp'
