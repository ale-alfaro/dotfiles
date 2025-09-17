return {
  'milanglacier/minuet-ai.nvim',
  cond = require('_utils').no_vscode,
  event = 'VeryLazy',
  config = function(_, opts)
    local num_docs = 10
    opts = {
      add_single_line_entry = true,
      n_completions = 1,
      after_cursor_filter_length = 0,
      provider = 'gemini',
      provider_options = {
        gemini = {
          model = 'gemini-2.0-flash',
          chat_input = {
            template = '{{{language}}}\n{{{tab}}}\n{{{repo_context}}}{{{git_diff}}}<|fim_prefix|>{{{context_before_cursor}}}<|fim_suffix|>{{{context_after_cursor}}}<|fim_middle|>',
            repo_context = function()
              local has_vc, vectorcode_config = pcall(require, 'vectorcode.config')
              if has_vc then
                return vectorcode_config.get_cacher_backend().make_prompt_component(0, function(file)
                  return '<|file_separator|>' .. file.path .. '\n' .. file.document
                end).content
              else
                return ''
              end
            end,
            git_diff = function()
              if vim.bo.filetype == 'gitcommit' then
                local git_diff_job = vim.system({ 'git', 'diff', '--cached' }, {}, nil)
                local recent_commits_job = vim.system({ 'git', 'log', 'HEAD~10..HEAD', '--' }, {}, nil)
                local curr_branch_job = vim.system({ 'git', 'branch', '--show-current' }, {}, nil)
                local git_diff = vim.trim(git_diff_job:wait().stdout)
                local curr_branch = vim.trim(curr_branch_job:wait().stdout)
                if git_diff then
                  local recent_commits = recent_commits_job:wait().stdout

                  local prompt = ''
                  if curr_branch then
                    prompt = string.format('The current branch name is `%s`\n', curr_branch)
                  end
                  if recent_commits then
                    prompt = prompt
                      .. string.format('The following are the most recent 10 commits in the repo:\n%s\nFollow their style of writing.\n', recent_commits)
                  end
                  prompt = prompt .. 'Write a concise conventional commit message for the following git diff: ' .. git_diff
                  return prompt
                end
              end
              return ''
            end,
          },
          optional = {
            generationConfig = { stop_sequences = { '<|file_separator|>' } },
          },
        },
      },
      request_timeout = 10,
    }
    local num_ctx = 1024 * 32
    local job = require('plenary.job'):new {
      command = 'curl',
      args = { os.getenv 'OLLAMA_HOST', '--connect-timeout', '1' },
      on_exit = function(self, code, signal)
        if code == 0 then
          opts.provider_options.openai_fim_compatible = {
            api_key = 'TERM',
            name = 'Ollama',
            stream = false,
            end_point = os.getenv 'OLLAMA_HOST' .. '/v1/completions',
            model = os.getenv 'OLLAMA_CODE_MODEL',
            optional = {
              max_tokens = 256,
              num_ctx = num_ctx,
            },
            template = {
              prompt = function(pref, suff)
                if vim.bo.filetype == 'gitcommit' then
                  local git_diff = vim.system({ 'git', 'diff' }, {}, nil):wait().stdout
                  if git_diff then
                    return 'You are a experienced software developer, writing a conventional git commit message for the following patch.<|file_sep|>'
                      .. git_diff
                      .. '<|fim_middle|>'
                  end
                end
                local prompt_message = ([[Perform fill-in-middle from the following snippet of a %s code. Respond with only the filled in code.]]):format(
                  vim.bo.filetype
                )
                local has_vc, vectorcode_config = pcall(require, 'vectorcode.config')
                if has_vc then
                  local cache_result = vectorcode_config.get_cacher_backend().make_prompt_component(0)
                  num_docs = cache_result.count
                  prompt_message = prompt_message .. cache_result.content
                end

                return prompt_message .. '<|fim_prefix|>' .. pref .. '<|fim_suffix|>' .. suff .. '<|fim_middle|>'
              end,
              suffix = false,
            },
          }
        end
        vim.schedule(function()
          require('minuet').setup(opts)
          local openai_fim_compatible = require 'minuet.backends.openai_fim_compatible'
          local orig_get_text_fn = openai_fim_compatible.get_text_fn
          openai_fim_compatible.get_text_fn = function(json)
            local bufnr = vim.api.nvim_get_current_buf()
            local co = coroutine.create(function()
              vim.b[bufnr].ai_raw_response = json
              local has_vc, vectorcode_config = pcall(require, 'vectorcode.config')
              if not has_vc then
                return
              end
              if vectorcode_config.get_cacher_backend().buf_is_registered() then
                local new_num_query = num_docs
                if json.usage.total_tokens > num_ctx then
                  new_num_query = math.max(num_docs - 1, 1)
                elseif json.usage.total_tokens < num_ctx * 0.9 then
                  new_num_query = num_docs + 1
                end
                vectorcode_config.get_cacher_backend().register_buffer(0, { n_query = new_num_query })
              end
            end)
            coroutine.resume(co)
            return orig_get_text_fn(json)
          end
        end)
      end,
    }
    job:start()
  end,
  dependencies = { 'ibhagwan/fzf-lua' },
}
