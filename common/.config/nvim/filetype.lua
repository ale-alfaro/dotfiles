-- vim.filetype.add {
--   filename = {
--     ['.eslintrc.json'] = 'jsonc',
--   },
--
--   pattern = {
--     ['tsconfig*.json'] = 'jsonc',
--     ['.*/%.vscode/.*%.json'] = 'jsonc',
--     -- Borrowed from LazyVim. Mark huge files to disable features later.
--   },
-- }
vim.filetype.add {
  extension = {
    overlay = 'dts',
  },
  pattern = {
    ['.*'] = function(path, bufnr)
      return vim.bo[bufnr]
          and vim.bo[bufnr].filetype ~= 'bigfile'
          and path
          and vim.fn.getfsize(path) > (1024 * 500) -- 500 KB
          and 'bigfile'
        or nil
    end,
  },
}
--     To add a fallback match on contents, use >lua
-- vim.filetype.add {
--   pattern = {
--     ['.*'] = {
--       function(path, bufnr)
--         local content = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ''
--         if vim.regex([[^#!.*\\<mine\\>]]):match_str(content) ~= nil then
--           return 'mine'
--         elseif vim.regex([[\\<drawing\\>]]):match_str(content) ~= nil then
--           return 'drawing'
--         end
--       end,
--       { priority = -math.huge },
--     },
--   },
-- }
