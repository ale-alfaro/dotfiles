local obsidian_vault_root = vim.fn.getenv 'OBSIDIAN_HOME'
if obsidian_vault_root == vim.v.null then
  obsidian_vault_root = '~/Documents/Obsidian'
end
local vault = function(name)
  return vim.fs.joinpath(obsidian_vault_root, name)
end

OBS = {
  HOME = obsidian_vault_root,
  note_types = { 'literature', 'permanent', 'fleeting', 'reference', 'todo' },
  plug_config = {
    legacy_commands = false, -- this will be removed in the next major release
    workspaces = {
      {
        name = 'personal',
        path = vault 'Personal-Geek',
      },
      {
        name = 'work',
        path = vault 'Sibel-Work',
      },
      -- {
      --   name = 'blog',
      --   path = '/home/alealfaro/GeekieStuff/quartz/content',
      --   strict = true,
      --   overrides = {
      --
      --     frontmatter = {
      --       enabled = true,
      --       func = function(note)
      --         local out = { title = note.title, created = note.created, modified = note.modified }
      --
      --         if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
      --           for k, v in pairs(note.metadata) do
      --             out[k] = v
      --           end
      --         end
      --         return out
      --       end,
      --       sort = { 'title', 'created', 'modified' },
      --     },
      --     templates = {
      --
      --       enabled = true,
      --       folder = nil,
      --       date_format = 'YYYY-MM-DD',
      --       time_format = 'HH:mm',
      --       substitutions = {
      --         date = function(_, suffix)
      --           local format = suffix or Obsidian.opts.templates.date_format
      --           return require('obsidian.util').format_date(os.time(), format)
      --         end,
      --         time = function(_, suffix)
      --           local format = suffix or Obsidian.opts.templates.time_format
      --           return require('obsidian.util').format_date(os.time(), format)
      --         end,
      --         title = function(ctx)
      --           return ctx.partial_note and ctx.partial_note:display_name()
      --         end,
      --         id = function(ctx)
      --           return ctx.partial_note and ctx.partial_note.id
      --         end,
      --         path = function(ctx)
      --           return ctx.partial_note and tostring(ctx.partial_note.path)
      --         end,
      --       },
      --     },
      --     note = {
      --       template = '/home/alealfaro/Documents/Obsidian/Techie/Templates/Blog Default Template.md',
      --     },
      --     daily_notes = {
      --       enabled = false,
      --     },
      --   }, -- overrides
      -- },
    }, -- workspaces
    --- OBSIDIAN VAULT DEFAULT CONFIG
    note = {
      template = obsidian_vault_root .. '/Sibel-Work/Templates/default_neovim.md',
    },

    ---@type obsidian.config.FrontmatterOpts
    frontmatter = {
      enabled = true,
      func = function(note)
        local now = require('obsidian.util').format_date(os.time(), 'YYYY-MM-DD')
        local note_dir = note.path
        if not note_dir then
          return {}
        end

        local root_folder = note_dir:vault_relative_path():match '^(%w+)[%s/]'
        local note_type = ''
        if root_folder then
          local root_type = root_folder:trim():lower()
          if vim.list_contains(OBS.note_types, root_type) then
            note_type = root_type
          end
        end
        local out = { created = now, last = now, tags = note.tags, note_type = note_type }
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            out[k] = v
          end
        end
        return out
      end,
      sort = { 'note_type', 'tags', 'created', 'last' },
    },

    templates = {
      enabled = true,
      folder = 'Templates',
      date_format = 'YYYY-MM-DD',
      time_format = 'HH:mm',
      substitutions = {
        date = function(_, suffix)
          local format = suffix or Obsidian.opts.templates.date_format
          return require('obsidian.util').format_date(os.time(), format)
        end,
        time = function(_, suffix)
          local format = suffix or Obsidian.opts.templates.time_format
          return require('obsidian.util').format_date(os.time(), format)
        end,
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
      enabled = true,
      folder = 'Daily',
      date_format = 'MM-DD-YYYY',
      alias_format = nil,
      default_tags = { 'daily' },
      workdays_only = true,
    },
  },
}
OBS.setup = function()
  if not Obsidian then
    require('obsidian').setup(OBS.plug_config)
  end
end

-- ---@param tag_locations obsidian.TagLocation[]
-- ---@return string[]
-- local list_tags = function(tag_locations)
--   local tags = {}
--   for _, tag_loc in ipairs(tag_locations) do
--     local tag = tag_loc.tag
--     if not tags[tag] then
--       tags[tag] = true
--     end
--   end
--   return vim.tbl_keys(tags)
-- end
--
-- ---@param tag_locations obsidian.TagLocation[]
-- ---@param tags string[]
-- local function gather_tag_picker_list(tag_locations, tags)
--   ---@type obsidian.PickerEntry[]
--   local entries = {}
--   for _, tag_loc in ipairs(tag_locations) do
--     for _, tag in ipairs(tags) do
--       if tag_loc.tag:lower() == tag:lower() or vim.startswith(tag_loc.tag:lower(), tag:lower() .. '/') then
--         local display = string.format('%s [%s] %s', tag_loc.note:display_name(), tag_loc.line, tag_loc.text)
--         entries[#entries + 1] = {
--           value = { path = tag_loc.path, line = tag_loc.line, col = tag_loc.tag_start },
--           display = display,
--           ordinal = display,
--           filename = tostring(tag_loc.path),
--           lnum = tag_loc.line,
--           col = tag_loc.tag_start,
--         }
--         break
--       end
--     end
--   end
--   if vim.tbl_isempty(entries) then
--     if #tags == 1 then
--       log.warn 'Tag not found'
--     else
--       log.warn 'Tags not found'
--     end
--     return
--   end
--
--   vim.schedule(function()
--     OBS.plug_obj.picker.pick(entries, { prompt_title = '#' .. table.concat(tags, ', #') })
--   end)
-- end
--
-- OBS.pick_tags = function(data)
--   local tags = data.fargs or {}
--
--   local dir = OBS.plug_obj.api.resolve_workspace_dir()
--
--   if vim.tbl_isempty(tags) then
--     local tag = OBS.plug_obj.api.cursor_tag()
--     if tag then
--       tags = { tag }
--     end
--   end
--
--   if not vim.tbl_isempty(tags) then
--     search.find_tags_async(tags, function(tag_locations)
--       return gather_tag_picker_list(tag_locations, util.tbl_unique(tags))
--     end, { dir = dir })
--   else
--     search.find_tags_async('', function(tag_locations)
--       tags = list_tags(tag_locations)
--       vim.schedule(function()
--         Obsidian.picker.pick(tags, {
--           callback = function(...)
--             tags = vim.tbl_map(function(v)
--               return v.user_data
--             end, { ... })
--             gather_tag_picker_list(tag_locations, tags)
--           end,
--           selection_mappings = Obsidian.picker._tag_selection_mappings(),
--           allow_multiple = true,
--         })
--       end)
--     end, { dir = dir })
--   end
-- end

return OBS
