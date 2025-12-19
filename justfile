set shell := ["zsh", "-uc"]
set unstable := true

mod stow x"${JUST_HOME}/gnu-stow.just"

# ==============================================================================
# Stow Management
# ==============================================================================

export xdg_config_target_location := if env('XDG_CONFIG_HOME', '') =~ '^/' { absolute_path(env('XDG_CONFIG_HOME')) } else { home_directory() / '.config' }
home := home_directory()

#set this to 1 to run a simulated or dry-run (i.e j restow-user-bin stow_simulate=1)

stow_simulate := "1"
stow_cmd := "just stow::restow" + if stow_simulate == "1" { "-sim" } else { "" }

# By default, show the list of available recipes
default:
    @just --list
    @echo "Running on OS: {{ os() }}"

[group('maintanance')]
restow-platform-dotfiles:
    {{ stow_cmd }} {{ absolute_path(justfile_directory() / os()) }} {{ xdg_config_target_location }} ".config"
    echo "Stowed {{ os() }} packages"

[group('maintanance')]
restow-user-home:
    {{ stow_cmd }} {{ absolute_path(justfile_directory() / "common") }} {{ home_dir() }} "home"

[group('maintanance')]
restow-user-bin:
    {{ stow_cmd }} {{ absolute_path(justfile_directory() / "common") }} {{ executable_dir() }} "bin" " --ignore='/*.venv' "

[group('maintanance')]
restow-common-dotfiles:
    {{ stow_cmd }} {{ absolute_path(justfile_directory() / "common") }} {{ xdg_config_target_location }} ".config"  " --ignore='chromium' "
    echo "Stowed common packages"

[group('maintanance')]
restow-dotfiles: restow-common-dotfiles restow-platform-dotfiles

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
