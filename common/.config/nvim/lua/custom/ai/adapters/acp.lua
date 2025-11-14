return {
  gemini_cli = function()
    return require('codecompanion.adapters').extend('gemini_cli', {
      commands = {
        ['Gemini 2.5 Pro'] = { 'gemini', '--experimental-acp', '-m', 'gemini-2.5-pro' },
        ['default'] = { 'gemini', '--experimental-acp', '-m', 'gemini-2.5-flash' },
      },
      defaults = { auth_method = 'gemini-api-key', mcpServers = {}, timeout = 20000 },
      env = { GEMINI_API_KEY = vim.fn.expand '$GEMINI_API_KEY' },
    })
  end,
}
