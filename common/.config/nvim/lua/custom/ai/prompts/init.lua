P = {}

-- Helpers

function P.load_prompt_library()
  local formatting_file = 'response_formatting_instructions'
  local prompt_md_files = {
    'bash_developer',
    'plan',
    'changelog_writer',
    'code_reviewer',
    'conventional_commits',
    'lua_developer',
    'pydocs',
    'python_developer',
    'quickfix',
  }
  local user_prompts = {
    conventional_commits = true,
    code_reviewer = true,
  }
  local nvim_conf = vim.fn.stdpath 'config'
  local prompt_dir = nvim_conf .. '/lua/custom/ai/prompts/library'
  local stat = vim.uv.fs_stat(prompt_dir)
  if not (stat and stat.type == 'directory') then
    vim.print "Couldn't load prompt library"
  end
  local prompt_library = {}

  local function read_and_filter(fname)
    local lines
    local path = vim.fs.joinpath(prompt_dir, fname .. '.md')
    local f = io.open(path, 'r')
    if f then
      local content = f:read '*a'
      f:close()
      lines = vim.split(vim.trim(content or ''), '\n', { plain = true })
    else
      lines = {}
    end

    local filtered = {}
    for _, line in ipairs(lines) do
      if not line:lower():find 'markdownlint' then
        table.insert(filtered, line)
      end
    end
    return table.concat(filtered, '\n'):gsub('\n$', '')
  end

  local formatting_content = read_and_filter(formatting_file)
  for _, fname in ipairs(prompt_md_files) do
    local content = read_and_filter(fname)
    if user_prompts[fname] then
      prompt_library[fname] = content
    else
      prompt_library[fname] = formatting_content .. '\n\n' .. content
    end
  end
  return prompt_library
end
function P.register_prompt_library(opts)
  opts.prompt_library = {
    [' Bash Developer'] = {
      strategy = 'chat',
      description = 'Act as an expert Bash developer.',
      opts = {
        short_name = 'bash_role',
        is_slash_cmd = true,
        ignore_system_prompt = true,
      },
      prompts = {
        { role = 'system', content = VimRc.PROMPT_LIBRARY['bash_developer'] },
      },
    },
    ['Plan'] = {
      strategy = 'chat',
      description = 'Plan next steps for a given task ',
      opts = {
        index = 3,
        is_default = true,
        is_slash_cmd = false,
        user_prompt = true,
      },
      prompts = {
        {
          role = 'system',
          content = VimRc.PROMPT_LIBRARY['plan'],
        },
        {
          role = 'user',
          content = "Let's begin pairing on a topic of my choice. You have access to @{files}, @{grep_search}, @{file_search}, and @{next_edit_suggestion}.",
        },
      }, --prompt
    }, -- custom prompt
    [' Lua Developer'] = {
      strategy = 'chat',
      description = 'Act as an expert Lua developer.',
      opts = {
        short_name = 'lua_role',
        is_slash_cmd = true,
        ignore_system_prompt = true,
      },
      context = {
        {
          type = 'file',
          path = {
            '/usr/share/nvim/runtime/doc/api.txt',
            '/usr/share/nvim/runtime/doc/lua.txt',
          },
        },
      },
      prompts = {
        { role = 'system', content = VimRc.PROMPT_LIBRARY['lua_developer'] },
      },
    },
    [' Python Developer'] = {
      strategy = 'chat',
      description = 'Act as an expert Python developer.',
      opts = {
        short_name = 'python_role',
        is_slash_cmd = true,
        ignore_system_prompt = true,
      },
      prompts = {
        { role = 'system', content = VimRc.PROMPT_LIBRARY['python_developer'] },
      },
    },
    [' PyDocs'] = {
      strategy = 'inline',
      description = 'Write inline Python docstrings following NumPy-style.',
      opts = {
        short_name = 'pydocs',
        ignore_system_prompt = true,
      },
      prompts = {
        { role = 'system', content = VimRc.PROMPT_LIBRARY['pydocs'] },
      },
    },
  }
end

return P
