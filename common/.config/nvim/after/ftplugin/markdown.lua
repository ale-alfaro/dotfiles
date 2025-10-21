-- ┌─────────────────────────┐
-- │ Filetype config example │
-- └─────────────────────────┘
--
-- This is an example of a configuration that will apply only to a particular
-- filetype, which is the same as file's basename ('markdown' in this example;
-- which is for '*.md' files).
--
-- It can contain any code which will be usually executed when the file is opened
-- (strictly speaking, on every 'filetype' option value change to target value).
-- Usually it needs to define buffer/window local options and variables.
-- So instead of `vim.o` to set options, use `vim.bo` for buffer-local options and
-- `vim.cmd('setlocal ...')` for window-local options (currently more robust).
--
-- This is also a good place to set buffer-local 'mini.nvim' variables.
-- See `:h mini.nvim-buffer-local-config` and `:h mini.nvim-disabling-recipes`.

-- Enable spelling and wrap for window
vim.cmd('setlocal spell wrap')

-- Fold with tree-sitter
vim.cmd('setlocal foldmethod=expr foldexpr=v:lua.vim.treesitter.foldexpr()')

-- Disable built-in `gO` mapping in favor of 'mini.basics'
-- vim.keymap.del('n', 'gO', { buffer = 0 })

-- Set markdown-specific surrounding in 'mini.surround'
vim.b.minisurround_config = {
  custom_surroundings = {
    -- Markdown link. Common usage:
    -- `saiwL` + [type/paste link] + <CR> - add link
    -- `sdL` - delete link
    -- `srLL` + [type/paste link] + <CR> - replace link
    L = {
      input = { '%[().-()%]%(.-%)' },
      output = function()
        local link = require('mini.surround').user_input('Link: ')
        return { left = '[', right = '](' .. link .. ')' }
      end,
    },
  },
}

---@type obsidian.config.Internal
local obsidian_opts = {
  ---@class obsidian.config.StatuslineOpts
  ---
  ---@field format? string
  ---@field enabled? boolean
  statusline = {
    format = "{{backlinks}} backlinks  {{properties}} properties  {{words}} words  {{chars}} chars",
    enabled = true,
  },

  -- TODO:: replace with more general options before 4.0.0
  follow_url_func = vim.ui.open,
  follow_img_func = vim.ui.open,
  notes_subdir = nil,
  new_notes_location = "current_dir",

  -- TODO: group into a search module
  sort_by = "modified",
  sort_reversed = true,
  search_max_lines = 1000,

  workspaces = {
    { name = 'Personal-Geek', path = vim.fn.expand '$OBSIDIAN_HOME' .. '/Personal-Geek' },
    { name = 'Sibel-Work',    path = vim.fn.expand '$OBSIDIAN_HOME' .. '/Sibel-Work' },
  },
  -- log_level = vim.log.levels.INFO,
  -- note_id_func = require("obsidian.builtin").zettel_id,
  -- wiki_link_func = require("obsidian.builtin").wiki_link_id_prefix,
  -- markdown_link_func = require("obsidian.builtin").markdown_link,
  -- preferred_link_style = "wiki",
  -- open_notes_in = "current",

  ---@class obsidian.config.FrontmatterOpts
  ---
  --- Whether to enable frontmatter, boolean for global on/off, or a function that takes filename and returns boolean.
  ---@field enabled? (fun(fname: string?): boolean)|boolean
  ---
  --- Function to turn Note attributes into frontmatter.
  ---@field func? fun(note: obsidian.Note): table<string, any>
  --- Function that is passed to table.sort to sort the properties, or a fixed order of properties.
  ---
  --- List of string that sorts frontmatter properties, or a function that compares two values, set to vim.NIL/false to do no sorting
  ---@field sort? string[] | (fun(a: any, b: any): boolean) | vim.NIL | boolean
  -- frontmatter = {
  --   enabled = true,
  --   func = require("obsidian.builtin").frontmatter,
  --   sort = { "id", "aliases", "tags" },
  -- },



  completion = {
    blink = true,
    min_chars = 2,
    match_case = true,
    create_new = true,
  },

  ---@class obsidian.config.PickerNoteMappingOpts
  ---
  ---@field new? string
  ---@field insert_link? string

  ---@class obsidian.config.PickerTagMappingOpts
  ---
  ---@field tag_note? string
  ---@field insert_tag? string

  ---@class obsidian.config.PickerOpts
  ---
  ---@field name obsidian.config.Picker|?
  ---@field note_mappings? obsidian.config.PickerNoteMappingOpts
  ---@field tag_mappings? obsidian.config.PickerTagMappingOpts
  picker = {
    name = "Telescope",
    note_mappings = {
      new = "<C-x>",
      insert_link = "<C-l>",
    },
    tag_mappings = {
      tag_note = "<C-x>",
      insert_tag = "<C-l>",
    },
  },

}
