local languages = {
  'bash',
  'c',
  'cmake',
  'comment',
  'cpp',
  'css',
  'csv',
  'devicetree',
  'diff',
  'dockerfile',
  'dot',
  'doxygen',
  'editorconfig',
  'gdscript',
  'git_config',
  'git_rebase',
  'gitattributes',
  'gitcommit',
  'gitignore',
  'go',
  'html',
  'html_tags',
  'hyprlang',
  'ini',
  'javascript',
  'jinja',
  'jinja_inline',
  'jq',
  'jsdoc',
  'json',
  'just',
  'kconfig',
  'linkerscript',
  'lua',
  'luadoc',
  'make',
  'markdown',
  'markdown_inline',
  'mermaid',
  'ninja',
  'printf',
  'python',
  'query',
  'swift',
  'regex',
  'requirements',
  'rst',
  'rust',
  'tera',
  'toml',
  'tsv',
  'typescript',
  'typst',
  'vim',
  'vimdoc',
  'xml',
  'yaml',
  'zsh',
}

  -- Define hook to update tree-sitter parsers after plugin is updated

local isnt_installed = function(lang)
  return #vim.api.nvim_get_runtime_file('parser/' .. lang .. '.*', false) == 0
end
local to_install = vim.tbl_filter(isnt_installed, languages)
if #to_install > 0 then
  require('nvim-treesitter').install(to_install)
end
local filetypes = {}
for _, lang in ipairs(languages) do
  for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
    table.insert(filetypes, ft)
  end
end

vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('mariasolos/treesitter_folding', { clear = true }),
    desc = 'Enable Treesitter folding',
    callback = function(args)
        local bufnr = args.buf

        -- Enable Treesitter folding when not in huge files and when Treesitter
        -- is working.
        if vim.bo[bufnr].filetype ~= 'bigfile' and pcall(vim.treesitter.start, bufnr) then
            vim.api.nvim_buf_call(bufnr, function()
                vim.wo[0][0].foldmethod = 'expr'
                vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
                vim.cmd.normal 'zx'
            end)
        end
    end,
})
vim.treesitter.query.add_predicate('is-mise?', function(_, _, _, _, _)
  return true
end, { force = true, all = false })


local function treesitter_list()
  ---@type vim.pack.PlugData[]
  local installed = require('nvim-treesitter').get_installed()
  local available = vim
    .iter(require('nvim-treesitter.config').get_available())
    :filter(function(parser)
      return not vim.list_contains(installed, parser)
    end)
    :totable()
  ---@type string[]
  local lines = vim
    .iter({ 'Installed Parser/Grammars:', '--------------------', installed, 'Available Parser/Grammars:', '-------------------- ', available })
    :flatten(2)
    :totable()
  VimRc.show_in_split(lines, 'vimrc://treesitter')
end
local usercmd = vim.api.nvim_create_user_command
usercmd('TSList', treesitter_list, { desc = 'Treesitter Parsers List' })
usercmd('TSObjCheck', function(args)
  vim.print(vim.inspect(vim.treesitter.query.get_files(args.args[1], 'textobjects')))
end, { nargs = 1, complete = 'filetype', desc = 'Treesitter Check TextObjecs' })
