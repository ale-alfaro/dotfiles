--vim.api.nvim_create_autocmd("PackChanged", {
--    pattern = "*",
--    callback = function(ev)
--        vim.notify(ev.data.spec.name .. " has been updated.")
--        if ev.data.spec.name == "nvim-treesitter"
--            and ev.data.spec.kind ~= "deleted" then
--            vim.cmd [[ TSUpdate ]]
--        end
--    end,
--})
local function gh(plug)
  return 'https://github.com/' .. plug
end
vim.pack.add({{
  src =  gh("nvim-treesitter/nvim-treesitter"),
  version = "main",
},
  -- {src = gh('nvim-treesitter/nvim-treesitter-textobjects')}

})

local ensure_installed = {
      "bash",
      "c",
      "diff",
      "html",
      "javascript",
      "jsdoc",
      "json",
      "jsonc",
      "lua",
      "luadoc",
      "luap",
      "markdown",
      "markdown_inline",
      "printf",
      "python",
      "query",
      "regex",
      "toml",
      "tsx",
      "typescript",
      "vim",
      "vimdoc",
      "xml",
      "yaml",
}
vim.list_extend(ensure_installed, {
    'cpp',
    'cmake',
    'devicetree',
    'kconfig',
    'python',
    'just',
    'json5',
    'toml',
    'ninja',
    'rst',
})

require('nvim-treesitter').setup(
  {
    ensure_installed = ensure_installed
  })

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('treesitter', { clear = true }),
  callback = function(ev)
    local ft, lang = ev.match, vim.treesitter.language.get_lang(ev.match)
    if not VimRc.treesitter_have(ft) then
      return
    end
    -- highlighting
    local ok, _ = pcall(vim.treesitter.start)
    if not ok then
      _G.error("Couldn't not start treesitter for filetype: " .. ft .. ' lang: ' .. lang)
      return
    end
    -- indents
    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    -- indentation, provided by nvim-treesitter
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

