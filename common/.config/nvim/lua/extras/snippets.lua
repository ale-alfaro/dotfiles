local snippets = require 'mini.snippets'
local config_path = vim.fn.stdpath 'config'

local gen_loader = snippets.gen_loader
snippets.setup {
  snippets = {
    -- Always load 'snippets/global.json' from config directory
    -- snippets.gen_loader.from_file(config_path .. '/snippets/markdown.lua'),
    -- Load from 'snippets/' directory of plugins, like 'friendly-snippets'
    gen_loader.from_lang {
      lang_patterns = {
        -- Recognize special injected language of markdown tree-sitter parser
        markdown_inline = { 'markdown.lua' },
        c = { 'c/**/*.lua', 'c/**/*.json', '**/c.lua', '**/c.json' },
        cpp = { 'cpp/**/*.json', '**/cpp.json', '**/cppdoc.json' },
        cmake = { 'cmake/**/*.json', '**/cmake.json' },
        python = { 'python/**/*.json', '**/python.json' },
        bash = { 'bash/**/*.json', '**/bash.json' },
        sh = { 'sh/**/*.json', '**/sh.json', 'shell/**/*.json', '**/shell.json' },
        zsh = { 'zsh/**/*.json', '**/zsh.json' },
      },
    },

---       -- Load project-local snippets with `gen_loader.from_file()`
---       -- and relative path (file doesn't have to be present)
    gen_loader.from_file('.nvim/snippets.lua'),
    function(context)
      local rel_path = '.nvim/snippets/' .. context.lang .. '.lua'
      if vim.fn.filereadable(rel_path) == 0 then
        return
      end
      VimRc.info('Loading snippets from ' .. rel_path)
      return MiniSnippets.read_file(rel_path)
    end,
  },
}
