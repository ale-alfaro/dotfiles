local ok, splitjoin = pcall(require, 'mini.splitjoin')
if ok then
  local gen_hook = splitjoin.gen_hook
  local curly = { brackets = { '%b{}' } }

  -- Add trailing comma when splitting inside curly brackets
  local add_comma_curly = gen_hook.add_trailing_separator(curly)

  -- Delete trailing comma when joining inside curly brackets
  local del_comma_curly = gen_hook.del_trailing_separator(curly)

  -- Pad curly brackets with single space after join
  local pad_curly = gen_hook.pad_brackets(curly)

  -- Create buffer-local config
  vim.b.minisplitjoin_config = vim.tbl_deep_extend('force', vim.b.minisplitjoin_config or {}, {
    split = { hooks_post = { add_comma_curly } },
    join = { hooks_post = { del_comma_curly, pad_curly } },
  })
end
vim.b.minisurround_config = vim.tbl_deep_extend('force', vim.b.minisurround_config or {}, {
  custom_surroundings = {
    s = {
      input = { '%[%[().-()%]%]' },
      output = { left = '[[', right = ']]' },
    },
  },
})

vim.b.miniai_config = vim.tbl_deep_extend('force', vim.b.miniai_config or {}, {
  custom_textobjects = {
    s = { '%[%[().-()%]%]' },
  },
})
if MiniMisc then
  -- For setting the project root automatically
  MiniMisc.setup_auto_root { '.luarc.json' }
end
