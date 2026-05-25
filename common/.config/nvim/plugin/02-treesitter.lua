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
  'regex',
  'requirements',
  'rst',
  'rust',
  'tera',
  'tmux',
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

VimRc.now_if_args(function()
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
  VimRc.g_ts_folds = true
  local ts_start = function(ev)
    vim.treesitter.start(ev.buf)

    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    if VimRc.g_ts_folds then
      vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      vim.wo[0][0].foldmethod = 'expr'
    end
  end
  VimRc.new_autocmd('FileType', ts_start, vim._ensure_list(filetypes), 'Start tree-sitter')
  VimRc.g_mise_injections = true
  vim.treesitter.query.add_predicate('is-mise?', function(_, _, _, _, _)
    return VimRc.g_mise_injections
  end, { force = true, all = false })
  vim.api.nvim_create_user_command('TSFolds', function()
    VimRc.g_ts_folds = not VimRc.g_ts_folds
    if VimRc.g_ts_folds then
      vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      vim.wo[0][0].foldmethod = 'expr'
    end
  end, { desc = 'Toggle Mise Treesitter Injections for syntax highlighting' })

  vim.api.nvim_create_user_command('TSMiseInjections', function()
    VimRc.g_mise_injections = not VimRc.g_mise_injections
  end, { desc = 'Toggle Mise Treesitter Injections for syntax highlighting' })

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
end)
