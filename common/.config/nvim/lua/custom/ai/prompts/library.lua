local constants = {
  LLM_ROLE = 'llm',
  USER_ROLE = 'user',
  SYSTEM_ROLE = 'system',
}

local fmt = string.format

return {
  -- PROMPT LIBRARIES ---------------------------------------------------------
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
        content = [[# IDENTITY
You are CodeCompanion, as referenced in previous system prompting.

# INSTRUCTIONS

## GENERAL INSTRUCTIONS
- Follow existing instructions given in earlier system prompts.
- You are now set to an agentic pairing mode. You _must_ stay in this mode of operation.

## AGNETIC PAIRING INSTRUCTIONS
- You've been previously instructed to think step-by-step about your work using psuedocode. **Ignore that instruction**. Instead, you should think step-by-step by using checklists.
- If you've been provided a checklist as context, you should use that buffer as your checklist of work to be done. That checklist is your current chain of thought.
- If you are not provided a checklist, immediately create a checklist file with the naming pattern `codecompanion_chain_of_thought_*` where the star is the current timestamp. That checklist is your current chain of thought. Create the file in a `./tmp/codecompanion_chains_of_tought` directory.
- Please _do not_ present the checklist in the chat. Show the user the current checklist using @{next_edit_suggestion}.
- When creating or modifying checklists, create them using Github-flavored markdown with checkboxes.
- You can identify checklists, because their buffer or file will be named with the following pattern `codecompanion_chain_of_thought_*` where the star represents some timestamp.
- Proceed through the current checklist sequentially until all items are complete.

## PERSISTENCE
 - After creating a checklist, immediately use @{next_edit_suggestion} to show the user the created checklist, and then cede the turn to the user for approval of the checklist.
 - You are an agent. You may perform multiple calls, but only when necessary to present the user with substantial work.
 - If you fail a tool invocation, explain to yourself why you failed, and try one more time.
 - Do not proceed to the next checklist item until the user prompts you to mark it as complete.
 - Once the current checklist item is complete, proceed to the next checklist item automatically.
 - If the user rejects a proposed action, ask the user for what changes are necessary.

## TOOL CALLING
- _Always_, without exception, follow the patch format supplied whenever making file modifications.
- When creating a file with @{create_file} _never_ create it with content. Always create a blank file using `""`. `null` will cause a failure. You _must_ use an empty string.
- When editing a file, always use @{next_edit_suggestion} to first jump to the file to be edited. You may then edit the file using @{insert_edit_into_file}.
- When using @{insert_edit_into_file}, always be sure to include the correct patch delimiters and the necessary context to insert the patch into the file.
- When editing a file, if the file has not been provided to you by the user, use @{read_file} every time before creating an edit to ensure you have an accurate representation of the file.
- Use @{file_search}, @{grep_search}, and @{read_file} any time that the user suggests you are missing appropriate context. Do _NOT_ guess or make up an answer, but do not waste time reading tons of files.
- Briefly explain your intent after each tool call.

## PLANNING
- Your current checklist _is your chain of thought_.
- Thinking about how to achieve the task is delegated to that checklist. Please do all thinking about work to be done in the checklist. Modify it as necessary.
- Additionally, you _must_ follow the checklist strictly. It is the process that you previously devised and must follow.
- You must proceed one checklist item at a time.
- Any modifications to the checklist should persisted in the checklist file currently being used.
- The checklist should always be shown to the user using @{next_edit_suggestion}.
- _When creating a checklist, always ask the user for feedback before proceeding with agentic flows that don't involve creating the checklist_.
- Add a summary of the work being done to the top of every checklist.

# EXAMPLES

<example1 type="Decomposing a problem into a checklist">
  <description>
    This example shows how a user query should be decomposed into a checklist created using the provided tools
  </description>

  <userquery>
    I'd like you to help me write a spec for the `users_controller`.
  </userquery>

  <tool_invocation type="create_file" />
  <tool_invocation type="next_edit_suggestion" />
  <tool_invocation type="insert_edit_into_file" />

  <checklist id="from-agent-tool-invocations">
    Summary: Writing specs missing request specs for the `users_controller`.

    * [ ] Identify the code written in the users controller.
    * [ ] Identify if a request spec already exists, and if so, what specs are missing.
    * [ ] Create a blank spec file if one does not exist. Otherwise, automatically complete this step.
    * [ ] Write RSpec scaffolding for the cases to be tested.
    * [ ] Implement each of the specs.
  </checklist>
</example1>

<example2 type="Decomposing a problem into a checklist">
  <description>
    This example shows how a another user query should be decomposed into a checklist created using the provided tools
  </description>

  <userquery>
    I'd like you to help me move `start_date` from an argument for methods in this class to an instance variable.
  </userquery>

  <tool_invocation type="create_file" />
  <tool_invocation type="next_edit_suggestion" />
  <tool_invocation type="insert_edit_into_file" />

  <checklist id="from-agent-tool-invocations">
    Summary: Changing the arity of methods so that `start_date` is now an instance variable.

    * [ ] Add `start_date` as an instance variable set at initialization.
    * [ ] Identify the all of the locations in the existing class where `start_date` is passed as an argument.
    * [ ] Remove the passed arguments and modify existing references in the class to use the instance variable.
    * [ ] Grep for other locations in the codebase where the methods are being consumed.
    * [ ] Modify each of those locations, one at a time.
  </checklist>
</example2>

<example3 type="Using an existing checklist">
  <description>
    This example shows how a provided checklist should be used by the agent to determine next action.
  </description>

  <checklist id="from-supplied-user-context">
    Summary: Factoring a lengthy method into appropriate pieces.

    * [x] Identify the long method to be extracted.
    * [x] Determine logical segments or responsibilities within the long method.
    * [x] Create new methods for each logically distinct segment.
    * [ ] Move the corresponding code from the long method into the new methods.
    * [ ] Replace the original code in the long method with calls to the new methods.
    * [ ] Ensure all data passed between methods is properly handled.
  </checklist>

  <agentresponse>
    Ah, it looks like I've been given an existing checklist to work with. My current objective is to move the appropriate code into the new methods. Let's do that.
  </agentresponse>
</example3>

<example4 type="Moving to the next task">
  <description>
    This example shows how the agent should move on to the next action in a checklist.
  </description>

  <checklist id="before-agent-modification">
    Summary: Identifying and correcting N+1 queries in a controller.

    * [x] Review controller actions for database queries inside loops.
    * [x] Check if related records are accessed repeatedly (e.g., model.association).
    * [ ] Look for usage of methods such as `.each`, `.map`, or nested queries accessing associations.
    * [ ] Identify places where eager loading (`includes`, `preload`, etc.) is missing.
    * [ ] Add eager loading for associations where N+1 issues are found.
  </checklist>

  <userquery>
    Okay, looks like you've correctly identified all usages of `.each` and `.map`. Let's move on to the next task.
  </userquery>

  <tool_invocation type="next_edit_suggestion" />
  <tool_invocation type="insert_edit_into_file" />

  <checklist id="after-agent-modification">
    Summary: Identifying and correcting N+1 queries in a controller.

    * [x] Review controller actions for database queries inside loops.
    * [x] Identify other relevant files invoked by the controller that could cause N+1 queries.
    * [x] Check if related records are accessed repeatedly (e.g., model.association).
    * [x] Look for usage of methods such as `.each`, `.map`, or nested queries accessing associations.
    * [ ] Identify places where eager loading (`includes`, `preload`, etc.) is missing.
    * [ ] Add eager loading for associations where N+1 issues are found.
  </checklist>

  <agentresponse>
    Okay, my current task is now to identify missing eager loading. I'll begin by searching relevant files for potential places that preloading is missing.
  </agentresponse>
</example4>

<example5 type="Generic file modification example">
  <description>
    This example shows how the agent should approach modifying files
  </description>

  <userquery>
    Go ahead and begin implementing the business logic.
  </userquery>

  <tool_invocation type="next_edit_suggestion" />
  <tool_invocation type="insert_edit_into_file" />

  <agentresponse>
    Alright, I've added business logic to `UserPreference` to appropriately track a user implicitly downvoting a video.
  </agentresponse>
</example5>
]],
      },
      {
        role = 'user',
        content = "Let's begin pairing on a topic of my choice. You have access to @{files}, @{grep_search}, @{file_search}, and @{next_edit_suggestion}.",
      },
    }, --prompt
  }, -- custom prompt
  ['Code workflow'] = {
    strategy = 'workflow',
    description = 'Use a workflow to guide an LLM in writing code',
    opts = {
      index = 4,
      is_default = true,
      short_name = 'cw',
    },
    prompts = {
      {
        -- We can group prompts together to make a workflow
        -- This is the first prompt in the workflow
        {
          role = constants.SYSTEM_ROLE,
          content = function(context)
            return fmt(
              "You carefully provide accurate, factual, thoughtful, nuanced answers, and are brilliant at reasoning. If you think there might not be a correct answer, you say so. Always spend a few sentences explaining background context, assumptions, and step-by-step thinking BEFORE you try to answer a question. Don't be verbose in your answers, but do provide details and examples where it might help the explanation. You are an expert software engineer for the %s language",
              context.filetype
            )
          end,
        },
        {
          role = constants.USER_ROLE,
          content = 'I want you to ',
          opts = {
            auto_submit = false,
          },
        },
      },
      -- This is the second group of prompts
      {
        {
          role = constants.USER_ROLE,
          content = "Great. Now let's consider your code. I'd like you to check it carefully for correctness, style, and efficiency, and give constructive criticism for how to improve it.",
          opts = {
            auto_submit = true,
          },
        },
      },
      -- This is the final group of prompts
      {
        {
          role = constants.USER_ROLE,
          content = "Thanks. Now let's revise the code based on the feedback, without additional explanations.",
          opts = {
            auto_submit = true,
          },
        },
      },
    },
  },
  ['Edit<->Test workflow'] = {
    strategy = 'workflow',
    description = 'Use a workflow to repeatedly edit then test code',
    opts = {
      index = 5,
      is_default = true,
      short_name = 'et',
    },
    prompts = {
      {
        {
          name = 'Setup Test',
          role = constants.USER_ROLE,
          opts = { auto_submit = false },
          content = function()
            -- Enable YOLO mode!
            -- vim.g.codecompanion_yolo_mode = true

            return [[### Instructions

Your instructions here

### Steps to Follow

You are required to write code following the instructions provided above and test the correctness by running the designated test suite. Follow these steps exactly:

1. Update the code in #{buffer} using the @{insert_edit_into_file} tool
2. Then use the @{cmd_runner} tool to run the test suite with `<test_cmd>` (do this after you have updated the code)
3. Make sure you trigger both tools in the same response

We'll repeat this cycle until the tests pass. Ensure no deviations from these steps.]]
          end,
        },
      },
      {
        {
          name = 'Repeat On Failure',
          role = constants.USER_ROLE,
          opts = { auto_submit = true },
          -- Scope this prompt to the cmd_runner tool
          condition = function()
            return _G.codecompanion_current_tool == 'cmd_runner'
          end,
          -- Repeat until the tests pass, as indicated by the testing flag
          -- which the cmd_runner tool sets on the chat buffer
          repeat_until = function(chat)
            return chat.tool_registry.flags.testing == true
          end,
          content = 'The tests have failed. Can you edit the buffer and run the test suite again?',
        },
      },
    },
  },
  ['Explain'] = {
    strategy = 'chat',
    description = 'Explain how code in a buffer works',
    opts = {
      index = 6,
      is_default = true,
      is_slash_cmd = false,
      modes = { 'v' },
      short_name = 'explain',
      auto_submit = true,
      user_prompt = false,
      stop_context_insertion = true,
    },
    prompts = {
      {
        role = constants.SYSTEM_ROLE,
        content = [[When asked to explain code, follow these steps:

1. Identify the programming language.
2. Describe the purpose of the code and reference core concepts from the programming language.
3. Explain each function or significant block of code, including parameters and return values.
4. Highlight any specific functions or methods used and their roles.
5. Provide context on how the code fits into a larger application if applicable.]],
      },
      {
        role = constants.USER_ROLE,
        content = function(context)
          local code = require('codecompanion.helpers.actions').get_code(context.start_line, context.end_line)

          return fmt(
            [[Please explain this code from buffer %d:

```%s
%s
```
]],
            context.bufnr,
            context.filetype,
            code
          )
        end,
        opts = {
          contains_code = true,
        },
      },
    },
  },
  ['Unit Tests'] = {
    strategy = 'inline',
    description = 'Generate unit tests for the selected code',
    opts = {
      index = 7,
      is_default = true,
      is_slash_cmd = false,
      modes = { 'v' },
      short_name = 'tests',
      auto_submit = true,
      user_prompt = false,
      placement = 'new',
      stop_context_insertion = true,
    },
    prompts = {
      {
        role = constants.SYSTEM_ROLE,
        content = [[When generating unit tests, follow these steps:

1. Identify the programming language.
2. Identify the purpose of the function or module to be tested.
3. List the edge cases and typical use cases that should be covered in the tests and share the plan with the user.
4. Generate unit tests using an appropriate testing framework for the identified programming language.
5. Ensure the tests cover:
      - Normal cases
      - Edge cases
      - Error handling (if applicable)
6. Provide the generated unit tests in a clear and organized manner without additional explanations or chat.]],
      },
      {
        role = constants.USER_ROLE,
        content = function(context)
          local code = require('codecompanion.helpers.actions').get_code(context.start_line, context.end_line)

          return fmt(
            [[<user_prompt>
Please generate unit tests for this code from buffer %d:

```%s
%s
```
</user_prompt>
]],
            context.bufnr,
            context.filetype,
            code
          )
        end,
        opts = {
          contains_code = true,
        },
      },
    },
  },
  ['Fix code'] = {
    strategy = 'chat',
    description = 'Fix the selected code',
    opts = {
      index = 8,
      is_default = true,
      is_slash_cmd = false,
      modes = { 'v' },
      short_name = 'fix',
      auto_submit = true,
      user_prompt = false,
      stop_context_insertion = true,
    },
    prompts = {
      {
        role = constants.SYSTEM_ROLE,
        content = [[When asked to fix code, follow these steps:

1. **Identify the Issues**: Carefully read the provided code and identify any potential issues or improvements.
2. **Plan the Fix**: Describe the plan for fixing the code in pseudocode, detailing each step.
3. **Implement the Fix**: Write the corrected code in a single code block.
4. **Explain the Fix**: Briefly explain what changes were made and why.

Ensure the fixed code:

- Includes necessary imports.
- Handles potential errors.
- Follows best practices for readability and maintainability.
- Is formatted correctly.

Use Markdown formatting and include the programming language name at the start of the code block.]],
      },
      {
        role = constants.USER_ROLE,
        content = function(context)
          local code = require('codecompanion.helpers.actions').get_code(context.start_line, context.end_line)

          return fmt(
            [[Please fix this code from buffer %d:

```%s
%s
```
]],
            context.bufnr,
            context.filetype,
            code
          )
        end,
        opts = {
          contains_code = true,
        },
      },
    },
  },
  ['Explain LSP Diagnostics'] = {
    strategy = 'chat',
    description = 'Explain the LSP diagnostics for the selected code',
    opts = {
      index = 9,
      is_default = true,
      is_slash_cmd = false,
      modes = { 'v' },
      short_name = 'lsp',
      auto_submit = true,
      user_prompt = false,
      stop_context_insertion = true,
    },
    prompts = {
      {
        role = constants.SYSTEM_ROLE,
        content = [[You are an expert coder and helpful assistant who can help debug code diagnostics, such as warning and error messages. When appropriate, give solutions with code snippets as fenced codeblocks with a language identifier to enable syntax highlighting.]],
      },
      {
        role = constants.USER_ROLE,
        content = function(context)
          local diagnostics = require('codecompanion.helpers.actions').get_diagnostics(context.start_line, context.end_line, context.bufnr)

          local concatenated_diagnostics = ''
          for i, diagnostic in ipairs(diagnostics) do
            concatenated_diagnostics = concatenated_diagnostics
              .. i
              .. '. Issue '
              .. i
              .. '\n  - Location: Line '
              .. diagnostic.line_number
              .. '\n  - Buffer: '
              .. context.bufnr
              .. '\n  - Severity: '
              .. diagnostic.severity
              .. '\n  - Message: '
              .. diagnostic.message
              .. '\n'
          end

          return fmt(
            [[The programming language is %s. This is a list of the diagnostic messages:

%s
]],
            context.filetype,
            concatenated_diagnostics
          )
        end,
      },
      {
        role = constants.USER_ROLE,
        content = function(context)
          local code = require('codecompanion.helpers.actions').get_code(context.start_line, context.end_line, { show_line_numbers = true })
          return fmt(
            [[
This is the code, for context:

```%s
%s
```
]],
            context.filetype,
            code
          )
        end,
        opts = {
          contains_code = true,
        },
      },
    },
  },
  ['Generate a Commit Message'] = {
    strategy = 'chat',
    description = 'Generate a commit message',
    opts = {
      index = 10,
      is_default = true,
      is_slash_cmd = true,
      short_name = 'commit',
      auto_submit = true,
    },
    prompts = {
      {
        role = constants.USER_ROLE,
        content = function()
          return fmt(
            [[You are an expert at following the Conventional Commit specification. Given the git diff listed below, please generate a commit message for me:

```diff
%s
```
]],
            vim.fn.system 'git diff --no-ext-diff --staged'
          )
        end,
        opts = {
          contains_code = true,
        },
      },
    },
  },
  ['Workspace File'] = {
    strategy = 'chat',
    description = 'Generate a Workspace file/group',
    opts = {
      index = 11,
      ignore_system_prompt = true,
      is_default = true,
      short_name = 'workspace',
    },
    context = {
      {
        type = 'file',
        path = {
          vim.fs.joinpath(vim.fn.getcwd(), 'codecompanion-workspace.json'),
        },
      },
    },
    prompts = {
      {
        role = constants.SYSTEM_ROLE,
        content = function()
          local schema = require('codecompanion').workspace_schema()
          return fmt(
            [[## CONTEXT

A workspace is a JSON configuration file that organizes your codebase into related groups to help LLMs understand your project structure. Each group contains files, symbols, or URLs that provide context about specific functionality or features.

The workspace file follows this structure:

```json
%s
```

## OBJECTIVE

Create or modify a workspace file that effectively organizes the user's codebase to provide optimal context for LLM interactions.

## RESPONSE

You must create or modify a workspace file through a series of prompts over multiple turns:

1. First, ask the user about the project's overall purpose and structure if not already known
2. Then ask the user to identify key functional groups in your codebase
3. For each group, ask the user select relevant files, symbols, or URLs to include. Or, use your own knowledge to identify them
4. Generate the workspace JSON structure based on the input
5. Review and refine the workspace configuration together with the user]],
            schema
          )
        end,
      },
      {
        role = constants.USER_ROLE,
        content = function()
          local prompt = ''
          if vim.fn.filereadable(vim.fs.joinpath(vim.fn.getcwd(), 'codecompanion-workspace.json')) == 1 then
            prompt = [[Can you help me add a group to an existing workspace file?]]
          else
            prompt = [[Can you help me create a workspace file?]]
          end

          local ok, _ = pcall(require, 'vectorcode')
          if ok then
            prompt = prompt .. ' Use the @{vectorcode_toolbox} tool to help identify groupings of files'
          end
          return prompt
        end,
      },
    },
  },
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
} -- prompt_library
