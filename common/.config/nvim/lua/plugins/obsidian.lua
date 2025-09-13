return {
  'obsidian-nvim/obsidian.nvim',
  version = '*', -- recommended, use latest release instead of latest commit
  ft = 'markdown',
  opts = {
    workspaces = {
      {
        name = 'personal-geek-notes',
        path = '/home/alealfaro/Documents/Obsidian/Personal-Geek-Notes',
      },
      {
        name = 'Embedded-Cpp',
        path = '/home/alealfaro/Documents/Obsidian/Embedded-Cpp-Notes',
      },
      {
        name = 'Sibel',
        path = '/home/alealfaro/Documents/Obsidian/Sibel-Notes',
      },
    },
  },
}