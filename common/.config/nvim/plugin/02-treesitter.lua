local languages = {
  'bash',
  'c',
  'cpp',
  'cmake',
  'diff',
  'devicetree',
  'json',
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
  'tera',
  'vim',
  'vimdoc',
  'xml',
  'yaml',
}

VimRc.now_if_args(function()
  -- Define hook to update tree-sitter parsers after plugin is updated
  local ts_update = function()
    vim.cmd 'TSUpdate'
  end
  VimRc.on_packchanged('nvim-treesitter', { 'update' }, ts_update, ':TSUpdate')

  vim.pack.add {
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/nvim-treesitter/nvim-treesitter-textobjects',
  }

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
  FeatureFlags:add {
    name = 'Fold',
    gl_enabled = true,
  }
  local ts_start = function(ev)
    vim.treesitter.start(ev.buf)

    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    if FeatureFlags:get 'Fold' then
      vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      vim.wo[0][0].foldmethod = 'expr'
    end
  end
  VimRc.new_autocmd('FileType', ts_start, vim._ensure_list(filetypes), 'Start tree-sitter')

  ---@param match table<integer,TSNode[]>,
  ---@param pattern integer
  ---@param bufnr integer|string
  ---@param pred any[]
  ---@param metadata vim.treesitter.query.TSMetadata
  ---@return boolean?
  vim.treesitter.query.add_predicate('is-mise?', function(match, pattern, bufnr, pred, metadata)
    local filepath = vim.api.nvim_buf_get_name(tonumber(bufnr) or 0)
    local filename = vim.fn.fnamemodify(filepath, ':t')
    for dir in vim.fs.parents(filepath) do
      if dir:match 'mise-tasks' ~= nil then
        return true
      end
    end
    return string.match(filename, '.*mise.*%.toml$') ~= nil
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
    VimRc.write_to_buffer(lines, 'VimRc-treesitter-list')
  end

  vim.api.nvim_create_user_command('TSList', treesitter_list, { desc = 'View log messages' })
end)
