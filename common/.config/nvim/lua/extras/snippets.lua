local snippets = require 'mini.snippets'
local config_path = vim.fn.stdpath 'config'
local common_sh_patterns = { 'sh/**/*.json', '**/sh.json', 'shell/**/*.json', '**/shell.json' }

local lang_patterns = {
  -- Recognize special injected language of markdown tree-sitter parser
  markdown_inline = { 'markdown.json' },
  c = { 'cdoc/**/*.json', 'c/**/*.json', '**/cdoc.json', '**/c.json' },
  cpp = { 'cpp/**/*.json', '**/cpp.json', '**/cppdoc.json' },
  cmake = { 'cmake/**/*.json', '**/cmake.json' },
  python = { 'python/**/*.json', '**/python.json' },
  bash = vim.list_extend({ 'bash/**/*.json', '**/bash.json' }, common_sh_patterns),
  sh = common_sh_patterns,
  zsh = vim.list_extend({ 'zsh/**/*.json', '**/zsh.json' }, common_sh_patterns),
}
snippets.setup {
  snippets = {
    -- Always load 'snippets/global.json' from config directory
    snippets.gen_loader.from_file(config_path .. '/snippets/global.json'),
    -- Load from 'snippets/' directory of plugins, like 'friendly-snippets'
    snippets.gen_loader.from_lang { lang_patterns = lang_patterns },
  },
}
