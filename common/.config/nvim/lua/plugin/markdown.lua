local ok, render_md = pcall(require, 'render-markdown')
if ok then
  render_md.setup {
    preset = 'obsidian',
    completions = { lsp = { enabled = true } },
  }
else
  VimRc.error "Couldn't load render-markdown.nvim plugin"
end
