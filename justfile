#!/usr/bin/just --justfile
# set shell := ["bash", "-c"]
# set unstable := true

import "common/.config/just/justfile"

# ==============================================================================
# Stow Management
# ==============================================================================

export dotfiles_repo_location := absolute_path(justfile_directory())
export dotfiles_target_location := if env('XDG_CONFIG_HOME', '') =~ '^/' { absolute_path(env('XDG_CONFIG_HOME')) } else { home_directory() / '.config' }
home := home_directory()
common_extra_flags := " --ignore='bin' --ignore='zmk-config'"
# By default, show the list of available recipes
default:
    @just --list
    @echo "Running on OS: {{ os() }}"

[group('maintanance')]
restow-platform-dotfiles:
    just restow {{  absolute_path(justfile_directory() / os())  }} {{ dotfiles_target_location }} ".config"
    echo "Stowed {{ os() }} packages"

[group('maintanance')]
restow-common-dotfiles:
    just restow {{  absolute_path(justfile_directory() / "common")  }} {{ dotfiles_target_location  }} ".config"  " --ignore='chromium' "
    echo "Stowed common packages"

[group('maintanance')]
restow-dotfiles: restow-common-dotfiles restow-platform-dotfiles


neovim_install_prefix := home_directory() / ".local/nvim"
xdg_cache_home := if env('XDG_CACHE_HOME', '') =~ '^/' {
  env('XDG_CACHE_HOME')
} else {
  home_directory() / '.cache'
}
neovim_cache := xdg_cache_home / "nvim_build"
neovim_user_repo := "neovim/neovim"
[group('install')]
nvim_build:
    sudo rm -rf {{ neovim_cache }}
    sudo gh repo clone {{ neovim_user_repo }} {{ neovim_cache }} -- --filter=blob:none
    sudo mkdir -p {{ neovim_install_prefix }}
    sudo make -C {{ neovim_cache }} CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX="{{ neovim_install_prefix }}/tmp"


[script('bash'), group('install')]
nvim_install: nvim_build 
    set -euxo pipefail
    sudo make -C {{ neovim_cache }} install
    version=$( "{{ neovim_install_prefix }}/tmp/bin/nvim" --version | grep "NVIM" | awk '{print $2}' )
    sudo mv {{ neovim_install_prefix }}/tmp "{{ neovim_install_prefix }}/nvim-${version}"


global_gitignore_path := home_directory() / ".config" / "git" / "global.gitignore"

[group('install')]
global_gitignore_set:
    {{ if path_exists(global_gitignore_path) == "false" { error("global gitignore doesn't exist") } else { "" } }}
    git config --global core.excludesfile {{ global_gitignore_path }}

zdotdir := env('ZDOTDIR')
npm_init_cmd := if os() == "linux" { ". /usr/share/nvm/init-nvm.sh" } else if os() == "macos" { "export NVM_DIR=/Users/alealfaro/.nvm; [ -s /opt/homebrew/opt/nvm/nvm.sh ] && . /opt/homebrew/opt/nvm/nvm.sh; [ -s /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm ] && . /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" } else { error("Unsupported os!") }

[group('install')]
npm_setup:
    {{ if os() == "macos" { shell('brew', 'install nvm') } else { shell('sudo pacman', '-S', 'nvm') } }}
    echo {{ npm_init_cmd }} >> "{{ zdotdir }}/zshrc.d/099-apps.zsh"
    nvm install v22.19.0
    nvm alias default v22.19.0
