# Reference plugin

```Lua

}
```

## system prompt

```lua
local prompt = [[
You are an AI programming assistant named "CodeCompanion". You are currently plugged in to the Neovim text editor on a user's machine.

Your core tasks include:
- Answering general programming questions.
- Explaining how the code in a Neovim buffer works.
- Reviewing the selected code in a Neovim buffer.
- Generating unit tests for the selected code.
- Proposing fixes for problems in the selected code.
- Scaffolding code for a new workspace.
- Finding relevant code to the user's query.
- Proposing fixes for test failures.
- Answering questions about Neovim.
- Running tools.
- Any other tasks that the user gives you.

You must:
- Follow the user's requirements carefully and to the letter.
- Keep your answers short and impersonal, especially if the user responds with context outside of your tasks.
- Minimize other prose.
- Use Markdown formatting in your answers.
- Include the programming language name at the start of the Markdown code blocks.
- Avoid including line numbers in code blocks.
- Avoid wrapping the whole response in triple backticks.
- Only return code that's relevant to the task at hand. You may not need to return all of the code that the user has shared.
- Use actual line breaks instead of '\n' in your response to begin new lines.
- Use '\n' only when you want a literal backslash followed by a character 'n'.
- The non-code response should be in the same language as the user input, unless the user asked you to reply in a particular language.

When given a task:
1. Think step-by-step and describe your plan for what to build in pseudocode, written out in great detail, unless asked not to do so.
2. Output the code in a single code block, being careful to only return relevant code.
3. You should always generate short suggestions for the next user turns that are relevant to the conversation.
4. You can only give one reply for each conversation turn
```

```Lua
      opts.adapters = {
        acp = {
          gemini_cli = function()
            return require("codecompanion.adapters").extend("gemini_cli", {
              commands = {
                ["Gemini 2.5 Pro"] = {
                  "gemini",
                  "--experimental-acp",
                  "-m",
                  "gemini-2.5-pro",
                },
                ["Gemini 2.5 Flash"] = {
                  "gemini",
                  "--experimental-acp",
                  "-m",
                  "gemini-2.5-flash",
                },
              },
              defaults = {
                auth_method = "oauth-personal",
                mcpServers = require("mcphub").get_hub_instance():get_servers(),
                timeout = 20000, -- 20 seconds
              },
            })
          end,
        },
```

## vectorcode

```lua
{
    "Davidyz/VectorCode",
    -- dir = "~/git/VectorCode/",
    version = "*",
    -- build = "uv tool upgrade vectorcode",
    build = function(plugin)
      if vim.fn.executable("uv") ~= 1 then
        return vim.notify(
          "Failed to install VectorCode because `uv` is missing.",
          vim.log.levels.WARN
        )
      end
      local stdpath = vim.fn.stdpath("data")
      if string.find(plugin.dir, stdpath) then
        local command
        if vim.fn.executable("vectorcode") == 1 then
          command = "uv tool upgrade vectorcode"
        else
          command = 'uv tool install "vectorcode[lsp,mcp]"'
        end
        vim.system(vim.split(command, " ", { trimempty = true }), {}, nil)
      end
    end,
    opts = function()
      return {
        async_backend = "lsp",
        notify = true,
        on_setup = { lsp = true },
        n_query = 10,
        timeout_ms = -1,
        async_opts = {
          events = { "BufWritePost" },
          single_job = true,
          query_cb = require("vectorcode.utils").make_surrounding_lines_cb(40),
          debounce = -1,
          n_query = 30,
        },
      }
    end,
    config = function(_, opts)
      vim.lsp.config("vectorcode_server", {
        cmd_env = {
          HTTP_PROXY = os.getenv("HTTP_PROXY"),
          HTTPS_PROXY = os.getenv("HTTPS_PROXY"),
        },
      })
      require("vectorcode").setup(opts)
      -- vim.api.nvim_create_autocmd("LspAttach", {
      --   callback = function()
      --     require("vectorcode.config").get_cacher_backend().register_buffer(0)
      --   end,
      -- })
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    cmd = "VectorCode",
    cond = function()
      return vim.fn.executable("vectorcode") == 1 and require("_utils").no_vscode()
    end,
  },
```

## McpHub

```Lua
  {
    "ravitemer/mcphub.nvim",
    version = "*",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    build = "bundled_build.lua",
    cmd = { "MCPHub" },
    opts = function()
      return {
        port = 3000,
        use_bundled_binary = true,
        extensions = { copilotchat = { enabled = false } },
      }
    end,
  },
```
