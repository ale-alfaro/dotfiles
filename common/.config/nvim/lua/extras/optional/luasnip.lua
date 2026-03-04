---@param ls LuaSnip
local function markdown_snippets(ls)
  -- Add prefix ";" to each one of my snippets using the extend_decorator
  -- I use this in combination with blink.cmp. This way I don't have to use
  -- the transform_items function in blink.cmp that removes the ";" at the
  -- beginning of each snippet. I added this because snippets that start with
  -- a symbol like ```bash aren't having their ";" removed
  -- https://github.com/L3MON4D3/LuaSnip/discussions/895
  -- NOTE: THis extend_decorator works great, but I also tried to add the ";"
  -- prefix to all of the snippets loaded from friendly-snippets, but I was
  -- unable to do so, so I still have to use the transform_items in blink.cmp
  local extend_decorator = require 'luasnip.util.extend_decorator'
  -- Create trigger transformation function
  local function auto_semicolon(context)
    if type(context) == 'string' then
      return { trig = ';' .. context }
    end
    return vim.tbl_extend('keep', { trig = ';' .. context.trig }, context)
  end
  -- Register and apply decorator properly
  extend_decorator.register(ls.s, {
    arg_indx = 1,
    extend = function(original)
      return auto_semicolon(original)
    end,
  })
  local s = extend_decorator.apply(ls.s, {})

  -- local s = ls.snippet
  local t = ls.text_node
  local i = ls.insert_node
  local f = ls.function_node

  local function clipboard()
    return vim.fn.getreg '+'
  end

  -- #####################################################################
  --                            Markdown
  -- #####################################################################

  -- Helper function to create code block snippets
  local function create_code_block_snippet(lang)
    return s({
      trig = lang,
      name = 'Codeblock',
      desc = lang .. ' codeblock',
    }, {
      t { '```' .. lang, '' },
      i(1),
      t { '', '```' },
    })
  end

  -- Define languages for code blocks
  local languages = {
    'txt',
    'lua',
    'sql',
    'go',
    'regex',
    'bash',
    'markdown',
    'markdown_inline',
    'yaml',
    'json',
    'jsonc',
    'cpp',
    'csv',
    'java',
    'javascript',
    'python',
    'dockerfile',
    'html',
    'css',
    'templ',
    'php',
  }

  -- Generate snippets for all languages
  local snippets = {}

  for _, lang in ipairs(languages) do
    table.insert(snippets, create_code_block_snippet(lang))
  end

  table.insert(
    snippets,
    s({
      trig = 'chirpy',
      name = 'Disable markdownlint and prettier for chirpy',
      desc = 'Disable markdownlint and prettier for chirpy',
    }, {
      t {
        ' ',
        '<!-- markdownlint-disable -->',
        '<!-- prettier-ignore-start -->',
        ' ',
        '<!-- tip=green, info=blue, warning=yellow, danger=red -->',
        ' ',
        '> ',
      },
      i(1),
      t {
        '',
        '{: .prompt-',
      },
      -- In case you want to add a default value "tip" here, but I'm having
      -- issues with autosave
      -- i(2, "tip"),
      i(2),
      t {
        ' }',
        ' ',
        '<!-- prettier-ignore-end -->',
        '<!-- markdownlint-restore -->',
      },
    })
  )

  table.insert(
    snippets,
    s({
      trig = 'markdownlint',
      name = 'Add markdownlint disable and restore headings',
      desc = 'Add markdownlint disable and restore headings',
    }, {
      t {
        ' ',
        '<!-- markdownlint-disable -->',
        ' ',
        '> ',
      },
      i(1),
      t {
        ' ',
        ' ',
        '<!-- markdownlint-restore -->',
      },
    })
  )

  table.insert(
    snippets,
    s({
      trig = 'prettierignore',
      name = 'Add prettier ignore start and end headings',
      desc = 'Add prettier ignore start and end headings',
    }, {
      t {
        ' ',
        '<!-- prettier-ignore-start -->',
        ' ',
        '> ',
      },
      i(1),
      t {
        ' ',
        ' ',
        '<!-- prettier-ignore-end -->',
      },
    })
  )

  table.insert(
    snippets,
    s({
      trig = 'linkt',
      name = 'Add this -> [](){:target="_blank"}',
      desc = 'Add this -> [](){:target="_blank"}',
    }, {
      t '[',
      i(1),
      t '](',
      i(2),
      t '){:target="_blank"}',
    })
  )

  table.insert(
    snippets,
    s({
      trig = 'blank',
      name = 'Add this {:target="_blank"}',
      desc = 'Add this {:target="_blank"}',
    }, {
      t '{:target="_blank"}',
    })
  )

  table.insert(
    snippets,
    s({
      trig = 'todo',
      name = 'Add TODO: item',
      desc = 'Add TODO: item',
    }, {
      t '<!-- TODO: ',
      i(1),
      t ' -->',
    })
  )

  -- Paste clipboard contents in link section, move cursor to ()
  table.insert(
    snippets,
    s({
      trig = 'linkc',
      name = 'Paste clipboard as .md link',
      desc = 'Paste clipboard as .md link',
    }, {
      t '[',
      i(1),
      t '](',
      f(clipboard, {}),
      t ')',
    })
  )

  -- Paste clipboard contents in link section, move cursor to ()
  table.insert(
    snippets,
    s({
      trig = 'linkex',
      name = 'Paste clipboard as EXT .md link',
      desc = 'Paste clipboard as EXT .md link',
    }, {
      t '[',
      i(1),
      t '](',
      f(clipboard, {}),
      t '){:target="_blank"}',
    })
  )

  table.insert(
    snippets,
    s({
      trig = 'newline',
      name = 'Adds a blank line in markdown file',
      desc = 'Adds a blank line in markdown file',
    }, {
      t '<div style="page-break-after: always; visibility: hidden"> pagebreak </div>',
    })
  )

  -- Inserting "my dotfiles" link
  table.insert(
    snippets,
    s({
      trig = 'pagebreak',
      name = 'Adds a blank line in markdown file',
      desc = 'Adds a blank line in markdown file',
    }, {
      t '<div style="page-break-after: always; visibility: hidden"> pagebreak </div>',
    })
  )

  -- Basic bash script template
  table.insert(
    snippets,
    s({
      trig = 'bashex',
      name = 'Basic bash script example',
      desc = 'Simple bash script template',
    }, {
      t {
        '```bash',
        '#!/bin/bash',
        '',
        "echo 'helix'",
        "echo 'deeznuts'",
        '```',
        '',
      },
    })
  )

  -- Basic Python script template
  table.insert(
    snippets,
    s({
      trig = 'pythonex',
      name = 'Basic Python script example',
      desc = 'Simple Python script template',
    }, {
      t {
        '```python',
        '#!/usr/bin/env python3',
        '',
        'def main():',
        "    print('helix dizpython')",
        '',
        "if __name__ == '__main__':",
        '    main()',
        '```',
        '',
      },
    })
  )

  ls.add_snippets('markdown', snippets)
end

-- Snippets.
---@return VimPackPlugin
return {
  name = 'luasnip',
  plugin = _G.plug_spec { 'L3MON4D3/LuaSnip' },
  config = function()
    local types = require 'luasnip.util.types'
    ---@diagnostic disable: undefined-field
    local ls = require 'extras.optional.luasnip'
    markdown_snippets(ls)
    ls.setup {
      -- Check if the current snippet was deleted.
      delete_check_events = 'TextChanged',
      -- Display a cursor-like placeholder in unvisited nodes
      -- of the snippet.
      ext_opts = {
        [types.insertNode] = {
          unvisited = {
            virt_text = { { '|', 'Conceal' } },
            virt_text_pos = 'inline',
          },
        },
        [types.exitNode] = {
          unvisited = {
            virt_text = { { '|', 'Conceal' } },
            virt_text_pos = 'inline',
          },
        },
        [types.choiceNode] = {
          active = {
            virt_text = { { '(snippet) choice node', 'LspInlayHint' } },
          },
        },
      },
    }

    -- Load my custom snippets:
    require('luasnip.loaders.from_vscode').lazy_load {
      paths = vim.fn.stdpath 'config' .. '/snippets',
    }

    -- Use <C-c> to select a choice in a snippet.
    vim.keymap.set({ 'i', 's' }, '<C-o>', function()
      if ls.choice_active() then
        require 'luasnip.extras.select_choice'()
      end
    end, { desc = 'Select choice' })
    ---@diagnostic enable: undefined-field
  end,
  keys = {
    {
      mode = { 'i' },
      lhs = '<C-r>s',
      rhs = function()
        require('luasnip.extras.otf').on_the_fly 's'
      end,
      opts = { desc = 'Insert on-the-fly snippet' },
    },
  },
}
