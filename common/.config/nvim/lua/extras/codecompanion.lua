require('codecompanion').setup {
  adapters = {
    http = {
      ['llama.cpp'] = function()
        return require('codecompanion.adapters').extend('openai_compatible', {
          env = {
            url = 'http://llama-cpp.tail5a0932.ts.net:8080',
            api_key = 'TERM',
            chat_url = '/v1/chat/completions',
          },
          handlers = {
            parse_message_meta = function(self, data)
              local extra = data.extra
              if extra and extra.reasoning_content then
                data.output.reasoning = { content = extra.reasoning_content }
                if data.output.content == '' then
                  data.output.content = nil
                end
              end
              return data
            end,
          },
        })
      end,
    },
  },
  interactions = {
    chat = {
      adapter = 'llama.cpp',
      opts = {
        completion_provider = 'blink', -- blink|cmp|coc|default
      },
    },
    inline = {
      adapter = 'llama.cpp',
    },
  },
  opts = {
    triggers = {
      acp_slash_commands = '\\',
      editor_context = '#',
      slash_commands = '/',
      tools = '@',
    },
  },
}
