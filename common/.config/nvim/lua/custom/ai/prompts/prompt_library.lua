return {
  ['Code Expert'] = {
    strategy = 'chat',
    description = 'Get some special advice from an LLM',
    opts = {
      mapping = '<LocalLeader>ce',
      modes = { 'v' },
      short_name = 'expert',
      auto_submit = true,
      stop_context_insertion = true,
      user_prompt = true,
    },
    prompts = {
      {
        role = 'system',
        content = function(context)
          return 'I want you to act as a senior '
            .. context.filetype
            .. ' developer. I will ask you specific questions and I want you to return concise explanations and codeblock examples.'
        end,
      },
      {
        role = 'user',
        content = function(context)
          local text = require('codecompanion.helpers.actions').get_code(context.start_line, context.end_line)

          return 'I have the following code:\n\n```' .. context.filetype .. '\n' .. text .. '\n```\n\n'
        end,
        opts = {
          contains_code = true,
        },
      },
    },
  }, -- code expert
  --   ['Codebase Q&A'] = {
  --     strategy = 'chat',
  --     description = 'Answer a question about the codebase using vector search context.',
  --     opts = {
  --       mapping = '<LocalLeader>ca', -- 'c'ode 'a'ssistant
  --       modes = { 'n' }, -- Normal mode action
  --       auto_submit = true,
  --       stop_context_insertion = true,
  --     },
  --     prompts = {
  --       {
  --         role = 'system',
  --         content = [[
  -- You are an expert software developer assistant.
  -- The user will ask a question about their codebase.
  -- Use the following context, retrieved from a `vectorcode` semantic search of the repository, to provide a comprehensive and accurate answer.
  -- The context will contain file paths and relevant snippets of code or text.
  -- Base your answer primarily on the provided context.
  -- ]],
  --       },
  --       {
  --         role = 'user',
  --         content = function()
  --           local question = vim.fn.input 'Ask a question about the codebase: '
  --           if question == '' then
  --             vim.notify('Query cannot be empty.', vim.log.levels.WARN)
  --             return nil -- Abort the prompt
  --           end
  --
  --           -- Construct and run the vectorcode command
  --           -- Use --pipe for JSON output, get 3 results, include path and document
  --           local command = 'vectorcode query --pipe -n 3 --include path document ' .. vim.fn.shellescape(question)
  --           local result_json = vim.fn.system(command)
  --
  --           if vim.v.shell_error ~= 0 then
  --             vim.notify('Vectorcode query failed: ' .. result_json, vim.log.levels.ERROR)
  --             return nil -- Abort
  --           end
  --
  --           local ok, result_data = pcall(vim.fn.json_decode, result_json)
  --           if not ok or not result_data then
  --             vim.notify('Failed to parse vectorcode JSON output.', vim.log.levels.ERROR)
  --             return nil -- Abort
  --           end
  --
  --           local context_str = '--- Vector Search Context ---\n\n'
  --           if #result_data == 0 then
  --             context_str = context_str .. 'No relevant code found in the vector search.'
  --           else
  --             for _, item in ipairs(result_data) do
  --               context_str = context_str .. 'File: ' .. (item.path or 'N/A') .. '\n'
  --               context_str = context_str .. '```' .. (vim.fn.fnamemodify(item.path or '', ':e') or '') .. '\n'
  --               context_str = context_str .. (item.document or 'N/A') .. '\n'
  --               context_str = context_str .. '```\n\n'
  --             end
  --           end
  --           context_str = context_str .. '--- End of Context ---\n\n'
  --
  --           return context_str .. 'Question: ' .. question
  --         end,
  --       },
  -- },
  -- }, -- Codebase Q&A
} -- prompt_library
