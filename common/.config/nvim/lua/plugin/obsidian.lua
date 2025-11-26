local ok, _ = pcall(require, 'obsidian')
if ok then
  require('obsidian').setup(
    ---@type obsidian.config
    {
      attachments = {
        img_folder = 'res/imgs',
        img_text_func = require('obsidian.builtin').img_text_func,
        img_name_func = function()
          return string.format('Pasted image %s', os.date '%Y%m%d%H%M%S')
        end,
        confirm_img_paste = true,
      },
      legacy_commands = false,
      workspaces = {
        {
          name = 'Main',
          path = function()
            for dir in vim.fs.parents(vim.api.nvim_buf_get_name(0)) do
              if vim.fn.isdirectory(dir .. '/Personal-Geek') == 1 or vim.fn.isdirectory(dir .. '/Sibel-Work') == 1 then
                return dir
              end
            end
            return vim.fs.dirname(vim.api.nvim_buf_get_name(0))
          end,
          strict = true,
        },
      },
    }
  )
else
  _G.error "Couldn't load obsidian.nvim plugin"
end

_G.new_autocmd('User', function(ev)
  require('conform').format {
    bufnr = ev.buf,
    formatters = { 'prettier', 'injected' },
  }
end, 'ObsidianNoteWritePost')

_G.new_autocmd('User', function(ev)
  local note = require('obsidian.note').from_buffer(ev.buf)
  if note and note.metadata and note.metadata.spell == false then
    vim.wo.spell = false
  end
  vim.keymap.del('n', '<CR>', { buffer = ev.buf })
  vim.keymap.set('n', '<leader><CR>', require('obsidian.api').smart_action, { buffer = ev.buf })
end, 'ObsidianNoteEnter')
