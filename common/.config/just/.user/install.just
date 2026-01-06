[group('install')]
nvim_install tag="nightly":
    nvimv install '{{ tag }}'
    nvimv use '{{ tag }}'

zdotdir := env('ZDOTDIR')
npm_init_cmd := if os() == "linux" { ". /usr/share/nvm/init-nvm.sh" } else if os() == "macos" { "export NVM_DIR=/Users/alealfaro/.nvm; [ -s /opt/homebrew/opt/nvm/nvm.sh ] && . /opt/homebrew/opt/nvm/nvm.sh; [ -s /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm ] && . /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" } else { error("Unsupported os!") }

[group('install')]
npm_setup:
    {{ if os() == "macos" { shell('brew', 'install nvm') } else { shell('sudo pacman', '-S', 'nvm') } }}
    echo {{ npm_init_cmd }} >> "{{ zdotdir }}/zshrc.d/099-apps.zsh"
    nvm install v22.19.0
    nvm alias default v22.19.0
