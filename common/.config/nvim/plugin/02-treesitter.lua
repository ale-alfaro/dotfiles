VimRc.now_if_args(function()
  local process_items_opts = { kind_priority = { Text = -1, Snippets = 99 } }
  local process_items = function(items, base)
    return MiniCompletion.default_process_items(items, base, process_items_opts)
  end
  require('mini.completion').setup {
    lsp_completion = {
      -- Without this config autocompletion is set up through `:h 'completefunc'`.
      -- Although not needed, setting up through `:h 'omnifunc'` is cleaner
      -- (sets up only when needed) and makes it possible to use `<C-u>`.
      source_func = 'omnifunc',
      auto_setup = false,
      process_items = process_items,
    },

    mappings = {
      -- Force two-step/fallback completions
      force_twostep = '<M-Space>',
      force_fallback = '<C-Space>',

      -- Scroll info/signature window down/up. When overriding, check for
      -- conflicts with built-in keys for popup menu (like `<C-u>`/`<C-o>`
      -- for 'completefunc'/'omnifunc' source function; or `<C-n>`/`<C-p>`).
      scroll_down = '<C-f>',
      scroll_up = '<C-b>',
    },
  }

  -- local on_attach = function(ev)
  --   local bufnr = ev.buf
  --
  --   local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
  --
  --   VimRc.info(string.format('[LspAttach autocmd] - Client %s', client.name))
  --   if client:supports_method 'textDocument/completion' then
  --     -- Optional: trigger autocompletion on EVERY keypress. May be slow!
  --     local chars = {}
  --     for i = 32, 126 do
  --       table.insert(chars, string.char(i))
  --     end
  --     client.server_capabilities.completionProvider.triggerCharacters = chars
  --     vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
  --     vim.bo[ev.buf].omnifunc = 'v:lua.MiniCompletion.completefunc_lsp'
  --   end
  -- end
  -- VimRc.new_autocmd('LspAttach', on_attach, nil, "Set 'omnifunc'")

  -- Advertise to servers that Neovim now supports certain set of completion and
  -- signature features through 'mini.completion'.
end)

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
end)
