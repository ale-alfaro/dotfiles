return function(opts)
  opts.extensions = {
    history = {
      enabled = true,
      opts = {
        keymap = 'gh',
        save_chat_keymap = 'sc',
        auto_save = true,
        expiration_days = 7,
        picker = 'fzf_lua',
      },
    },
    spinner = {
      enabled = true,
      opts = { style = 'native' },
    },
  }
end
