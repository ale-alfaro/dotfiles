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
      -- force_fallback = '<C-Space>',
    },
  }

  --- To use `<Tab>` and `<S-Tab>` for navigation through completion list, make
  --- these mappings: >lua
  local map_multistep = require('mini.keymap').map_multistep
  local map_combo = require('mini.keymap').map_combo
  map_combo({ 'n', 'x' }, '<S-Left><S-Left>', 'g^')
  map_combo({ 'n', 'x' }, '<S-Right><S-Right>', 'g$')
  map_combo({ 'n', 'x' }, '<S-Up><S-Up>', '{')
  map_combo({ 'n', 'x' }, '<S-Down><S-Down>', '}')

  local tab_steps = { 'minisnippets_next', 'minisnippets_expand', 'pmenu_next' }
  map_multistep('i', '<Tab>', tab_steps)

  local shifttab_steps = { 'minisnippets_prev', 'pmenu_prev' }
  map_multistep('i', '<S-Tab>', shifttab_steps)
  --- <
  --- To get more consistent behavior of `<CR>`, you can use this template in
  --- your 'init.lua' to make customized mapping: >lua
  ---
  _G.cr_action = function()
    -- If there is selected item in popup, accept it with <C-y>
    if vim.fn.complete_info()['selected'] ~= -1 then
      return '\25'
    end
    return '\r'
  end

  vim.keymap.set('i', '<CR>', 'v:lua.cr_action()', { expr = true })
  local on_attach = function(ev)
    local bufnr = ev.buf
    vim.bo[bufnr].omnifunc = 'v:lua.MiniCompletion.completefunc_lsp'
    --
    local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
    --
    VimRc.info(string.format('[LspAttach autocmd] MiniCompletion.complefunc_lsp - Client %s', client.name))
  end
  -- Advertise to servers that Neovim now supports certain set of completion and
  -- signature features through 'mini.completion'.
  vim.lsp.config('*', { capabilities = MiniCompletion.get_lsp_capabilities() })
  VimRc.new_autocmd('LspAttach', on_attach, nil, "Set 'omnifunc'")

  -- Advertise to servers that Neovim now supports certain set of completion and
  -- signature features through 'mini.completion'.
end)

VimRc.now_if_args(function()
  local snippets = require 'mini.snippets'
  local match_strict = function(snips)
    return snippets.default_match(snips, { pattern_fuzzy = '%S' })
  end
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
    mappings = { expand = '', jump_next = '', jump_prev = '' },
    expand = { match = match_strict },
    snippets = {
      -- Always load 'snippets/global.json' from config directory
      snippets.gen_loader.from_file(config_path .. '/snippets/global.json'),
      -- Load from 'snippets/' directory of plugins, like 'friendly-snippets'
      snippets.gen_loader.from_lang { lang_patterns = lang_patterns },
    },
  }
  -- local expand_or_jump = function()
  --   local can_expand = #MiniSnippets.expand { insert = false } > 0
  --   if can_expand then
  --     vim.schedule(MiniSnippets.expand)
  --     return ''
  --   end
  --   local is_active = MiniSnippets.session.get() ~= nil
  --   if is_active then
  --     MiniSnippets.session.jump 'next'
  --     return ''
  --   end
  --   return '\t'
  -- end
  -- local jump_prev = function()
  --   MiniSnippets.session.jump 'prev'
  -- end
  -- vim.keymap.set('i', '<Tab>', expand_or_jump, { expr = true })
  -- vim.keymap.set('i', '<S-Tab>', jump_prev)

  -- Define language patterns to work better with 'friendly-snippets'

  -- By default snippets available at cursor are not shown as candidates in
  -- 'mini.completion' menu. This requires a dedicated in-process LSP server
  -- that will provide them. To have that, uncomment next line (use `gcc`).
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
