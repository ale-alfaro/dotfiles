local term = vim.fn.getenv 'TERM' or ''
if not term:find 'tmux-.*' and not term:find '.*ghostty' and not term:find '.*kitty' then
  vim.notify('TERM not supported for image rendering!', vim.log.levels.ERROR)
  return
end

---@param file string Markdown or other type of file where image is embedded
---@param image_src string Embedded image by name of relative path that needs to be resolved
---@return string absolute path of image
local resolve_image = function(file, image_src)
  local working_dir = vim.api.nvim_buf_get_name(0)

  local obsidian_vault_root = vim.fs.root(0, { '.obsidian' }) or vim.fs.root(file, { '.obsidian' })
  local obsidian_conf = vim.fs.joinpath(obsidian_vault_root, '.obsidian', 'app.json')
  if obsidian_vault_root and vim.uv.fs_stat(obsidian_conf) then
    local fh = io.open(obsidian_conf, 'r')
    local json = nil
    if fh then
      json = fh:read 'a'
      fh:close()
      json = vim.json.decode(json)
    end
    if json and json.attachmentFolderPath then
      path = obsidian_vault_root .. '/' .. json.attachmentFolderPath .. '/' .. image_src
    end
  end
  return path
end

return {

  setup_image_snacks = function()
    require('snacks').setup {
      image = {
        enabled = true,
        resolve = resolve_image,
        doc = {
          -- enable image viewer for documents
          -- a treesitter parser must be available for the enabled languages.
          enabled = true,
          -- render the image inline in the buffer
          -- if your env doesn't support unicode placeholders, this will be disabled
          -- takes precedence over `opts.float` on supported terminals
          inline = true,
          -- render the image in a floating window
          -- only used if `opts.inline` is disabled
          -- float = true,
          max_width = 200,
          max_height = 200,
          -- Set to `true`, to conceal the image text when rendering inline.
          -- (experimental)
          ---@param lang string tree-sitter language
          ---@param type snacks.image.Type image type
          conceal = function(lang, type)
            -- only conceal math expressions
            return type == 'math'
          end,
        },
      },
    }
  end,
  setup_image_nvim = function()
    require('image').setup {
      backend = 'kitty',
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          filetypes = { 'markdown', 'vimwiki' }, -- markdown extensions (ie. quarto) can go here
          -- Custom function to resolve image paths
          resolve_image_path = function(document_path, image_path, fallback)
            local path = fallback(document_path, image_path)
            return resolve_image(document_path, image_path) or path
          end,
        },
      },
    }
  end,
}
