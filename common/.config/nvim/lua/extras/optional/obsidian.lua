local obsidian_vault_root = VimRc.getenv('OBSIDIAN_HOME', '/home/alealfaro/Documents/Obsidian')
local vault = function(name)
  return vim.fs.joinpath(obsidian_vault_root, name)
end

local note_types = { 'literature', 'permanent', 'fleeting', 'reference', 'todo' }
return {
  legacy_commands = false, -- this will be removed in the next major release
  workspaces = {
    {
      name = 'personal',
      path = vault 'Personal',
    },
    {
      name = 'work',
      path = vault 'Techie',
    },
  },
  note = {
    template = obsidian_vault_root .. '/Sibel-Work/Templates/simple.md',
  },

  ---@type obsidian.config.FrontmatterOpts
  frontmatter = {
    enabled = true,
  },

  templates = {
    enabled = true,
    folder = 'Templates',
    date_format = 'YYYY-MM-DD',
    time_format = 'HH:mm',
    substitutions = {
      path = function(ctx)
        return ctx.partial_note and tostring(ctx.partial_note.path)
      end,
    },

    customizations = {},
  },
  ui = { enabled = false },
  picker = {
    name = nil,
    note_mappings = {
      new = '<C-x>',
      insert_link = '<C-l>',
    },
    tag_mappings = {
      tag_note = '<C-x>',
      insert_tag = '<C-l>',
    },
  },

  search = {
    sort_by = 'modified',
    sort_reversed = true,
    max_lines = 1000,
  },

  daily_notes = {
    enabled = false,
    folder = 'Daily',
    date_format = 'MM-DD-YYYY',
    alias_format = nil,
    default_tags = { 'daily' },
    workdays_only = true,
  },
}
