vim.pack.add(_G.plug_spec {
  'stevearc/conform.nvim',
  'stevearc/overseer.nvim',
  'mfussenegger/nvim-lint',
  'b0o/schemastore.nvim',
  'MeanderingProgrammer/render-markdown.nvim',
})

local miniclue = require 'mini.clue'
miniclue.enable_all_triggers()
miniclue.setup {
  triggers = {
    -- Builtins.
    { mode = { 'n', 'x' }, keys = 'g' },
    { mode = { 'n', 'x' }, keys = '`' },
    { mode = { 'n', 'x' }, keys = '"' },
    { mode = { 'i', 'c' }, keys = '<C-r>' },
    { mode = 'n', keys = '<C-w>' },
    { mode = 'i', keys = '<C-x>' },
    { mode = 'n', keys = 'z' },
    -- Leader triggers.
    { mode = { 'n', 'x' }, keys = '<leader>' },
    -- Moving between stuff.
    { mode = 'n', keys = '[' },
    { mode = 'n', keys = ']' },
  },
  clues = {
    -- Leader/movement groups.
    { mode = { 'n', 'x' }, keys = '<leader>a', desc = '+ai' },
    { mode = { 'n', 'x' }, keys = '<leader>c', desc = '+code' },
    { mode = { 'n', 'x' }, keys = '<leader>f', desc = '+find' },
    { mode = 'n', keys = '<leader>b', desc = '+buffers' },
    { mode = 'n', keys = '<leader>d', desc = '+debug' },
    { mode = 'n', keys = '<leader>t', desc = '+tabs' },
    { mode = 'n', keys = '<leader>x', desc = '+loclist/quickfix' },
    { mode = 'n', keys = '[', desc = '+prev' },
    { mode = 'n', keys = ']', desc = '+next' },
    -- Builtins.
    miniclue.gen_clues.g(),
    miniclue.gen_clues.marks(),
    miniclue.gen_clues.registers(),
    miniclue.gen_clues.windows(),
    miniclue.gen_clues.z(),
  },
  window = {
    delay = 500,
  },
}
require 'extras.overseer'
require 'extras.quicker'
--[[
--The table below shows all the highlight groups with their default link

  -----------------------------------------------------------------------------------------
  Highlight Group                 Default Group                        Description
  ------------------------------- ------------------------------------ --------------------
  RenderMarkdownH1                @markup.heading.1.markdown           H1 icons

  RenderMarkdownH2                @markup.heading.2.markdown           H2 icons

  RenderMarkdownH3                @markup.heading.3.markdown           H3 icons

  RenderMarkdownH4                @markup.heading.4.markdown           H4 icons

  RenderMarkdownH5                @markup.heading.5.markdown           H5 icons

  RenderMarkdownH6                @markup.heading.6.markdown           H6 icons

  RenderMarkdownH1Bg              DiffText                             H1 background line

  RenderMarkdownH2Bg              DiffAdd                              H2 background line

  RenderMarkdownH3Bg              DiffChange                           H3 background line

  RenderMarkdownH4Bg              DiffDelete                           H4 background line

  RenderMarkdownH5Bg              Visual                               H5 background line

  RenderMarkdownH6Bg              CursorColumn                         H6 background line

  RenderMarkdownCode              ColorColumn                          Code block
                                                                       background

  RenderMarkdownCodeInfo          @label                               Code info, after
                                                                       language

  RenderMarkdownCodeBorder        RenderMarkdownCode                   Code border
                                                                       background

  RenderMarkdownCodeFallback      Normal                               Fallback for code
                                                                       language

  RenderMarkdownCodeInline        RenderMarkdownCode                   Inline code
                                                                       background

  RenderMarkdownQuote             @markup.quote                        Default for block
                                                                       quote

  RenderMarkdownQuote1            RenderMarkdownQuote                  Level 1 block quote
                                                                       marker

  RenderMarkdownQuote2            RenderMarkdownQuote                  Level 2 block quote
                                                                       marker

  RenderMarkdownQuote3            RenderMarkdownQuote                  Level 3 block quote

  RenderMarkdownInlineHighlight   RenderMarkdownCodeInline             Inline highlights
                                                                       contents

  RenderMarkdownBullet            Normal                               List item bullet
                                                                       points

  RenderMarkdownIndent            Whitespace                           Indent icon

  RenderMarkdownHtmlComment       @comment                             HTML comment inline
                                                                       text

  RenderMarkdownLink              @markup.link.label.markdown_inline   Link icon

  RenderMarkdownLinkTitle         @markup.link.markdown_inline         Link title

  RenderMarkdownWikiLink          RenderMarkdownLink                   WikiLink icon

  RenderMarkdownUnchecked         @markup.list.unchecked               Unchecked checkbox

  RenderMarkdownChecked           @markup.list.checked                 Checked checkbox

  RenderMarkdownTodo              @markup.raw                          Todo custom checkbox

  RenderMarkdownTableHead         @markup.heading                      Pipe table heading
                                                                       rows

  RenderMarkdownTableRow          Normal                               Pipe table body rows

  RenderMarkdownTableFill         Conceal                              Pipe table inline
                                                                       padding

  RenderMarkdownSuccess           DiagnosticOk                         Success related
                                                                       callouts

  RenderMarkdownInfo              DiagnosticInfo                       Info related
                                                                       callouts

  RenderMarkdownHint              DiagnosticHint                       Hint related
                                                                       callouts

  RenderMarkdownWarn              DiagnosticWarn                       Warning related
                                                                       callouts

  RenderMarkdownError             DiagnosticError                      Error related
                                                                       callouts
--
--
--]]
--
require('render-markdown').setup(
  ---@type render.md.Settings
  {
    preset = 'obsidian',
    completions = {
      lsp = {
        enabled = true,
      },
    },
    pipe_table = {
      preset = 'round',
    },
  }
)
vim.api.nvim_set_hl(0, '@markup.heading.1.markdown', { fg = '#e46876' })
vim.api.nvim_set_hl(0, '@markup.heading.2.markdown', { fg = '#ff9e3b' })
vim.api.nvim_set_hl(0, '@markup.heading.3.markdown', { fg = '#e6c384' })
vim.api.nvim_set_hl(0, '@markup.heading.4.markdown', { fg = '#7fb4ca' })
-- Formatting
-- See also:
-- - `:h Conform`
-- - `:h conform-options`
-- - `:h conform-formatters`
vim.g.disable_autoformat = false
require 'custom.format'
vim.g.disabled_autolinting = false
require 'custom.lint'

vim.api.nvim_create_user_command('FormatDisable', function(args)
  if args.bang then
    -- FormatDisable! will disable formatting just for this buffer
    vim.b.disable_autoformat = true
  else
    vim.g.disable_autoformat = true
  end
end, {
  desc = 'Disable autoformat-on-save',
  bang = true,
})

vim.api.nvim_create_user_command('FormatEnable', function()
  vim.b.disable_autoformat = false
  vim.g.disable_autoformat = false
end, {
  desc = 'Re-enable autoformat-on-save',
})

vim.api.nvim_create_user_command('LintToggle', function()
  vim.g.disable_autolinting = not vim.g.disable_autolinting
end, {
  desc = 'Re-enable lint-on-save',
})
require 'extras.git'
require 'extras.optional.grug'
-- require 'extras.codecompanion'
