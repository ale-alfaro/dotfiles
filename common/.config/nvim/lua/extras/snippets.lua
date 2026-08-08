local snippets = require 'mini.snippets'
local topdir = vim.g.west_topdir or ''
local gen_loader = snippets.gen_loader
-- snippets.setup {
--   expand = {
--     prepare = function(snips, opts)
--   local buf_id = vim.api.nvim_get_current_buf()
--
--   -- TODO: Remove `opts.error` after compatibility with Neovim=0.11 is dropped
--   local has_parser, parser = pcall(vim.treesitter.get_parser, buf_id, nil, { error = false })
--   if not has_parser or parser == nil then return { buf_id = buf_id, lang = vim.bo[buf_id].filetype } end
--
--   -- Compute local (at cursor) TS language
--   local pos = vim.api.nvim_win_get_cursor(0)
--   local lang_tree = parser:language_for_range({ pos[1] - 1, pos[2], pos[1] - 1, pos[2] })
--   local lang = lang_tree:lang() or vim.bo[buf_id].filetype
--       return MiniSnippets.default_prepare(snips, { buf_id = buf_id, lang = lang })
--     end,
--   },
-- }
local header_guard = function()
  return { string.upper(string.gsub(vim.fn.expand '%:p:.', '[/%-%.]', '_')) }
end
local insert_with_lookup = function(snippet)
  local lookup = {
    TM_SELECTED_TEXT = table.concat(vim.fn.getreg('a', true, true), '\n'),
    HEADER_FILE_GUARD = table.concat(header_guard(), '\n'),
  }
  return MiniSnippets.default_insert(snippet, { lookup = lookup })
end

require('mini.snippets').setup {
  snippets = {
    -- Always load 'snippets/global.json' from config directory
    gen_loader.from_runtime 'global/*.lua',
    -- Load from 'snippets/' directory of plugins, like 'friendly-snippets'
    gen_loader.from_file(vim.fs.joinpath(topdir, '.nvim', 'snippets.lua')),
    gen_loader.from_file(vim.fs.joinpath(vim.fn.getcwd(), '.nvim', 'snippets.lua')),
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
  },
  -- ... Set up snippets ...
  expand = { insert = insert_with_lookup },
}
