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
common_extra_flags := " --ignore='bin' --ignore='chromium' --ignore='zmk-config'"

# By default, show the list of available recipes
default:
    @just --list
    @echo "Running on OS: {{ os() }}"

restow-platform-dotfiles: (restow absolute_path(justfile_directory() / os()) dotfiles_target_location ".config" common_extra_flags)
    echo "Stowed {{ os() }} packages"

restow-common-dotfiles: (restow absolute_path(justfile_directory() / "common") dotfiles_target_location "." common_extra_flags)
    echo "Stowed common packages"

restow-dotfiles: restow-common-dotfiles restow-platform-dotfiles


neovim_install_prefix := home_directory() / ".local/nvim"
xdg_cache_home := if env('XDG_CACHE_HOME', '') =~ '^/' {
  env('XDG_CACHE_HOME')
} else {
  home_directory() / '.cache'
}
neovim_cache := xdg_cache_home / "nvim_build"
neovim_user_repo := "neovim/neovim"
nvim_build:
    sudo rm -rf {{ neovim_cache }}
    sudo gh repo clone {{ neovim_user_repo }} {{ neovim_cache }} -- --filter=blob:none
    sudo mkdir -p {{ neovim_install_prefix }}
    sudo make -C {{ neovim_cache }} CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX="{{ neovim_install_prefix }}/tmp"


[script("bash")]
nvim_install: nvim_build 
    set -euxo pipefail
    sudo make -C {{ neovim_cache }} install
    version=$( "{{ neovim_install_prefix }}/tmp/bin/nvim" --version | grep "NVIM" | awk '{print $2}' )
    sudo mv {{ neovim_install_prefix }}/tmp "{{ neovim_install_prefix }}/nvim-${version}"

# check: Simulate stowing to check for any conflicts
# vectorcode := require("vectorcode")
# common_dotfiles_dir := "nvim zsh wezterm just"
# macos_dotfiles_dir := "aerospace hammerspoon sketchybar borders"
# linux_dotfiles_dir := "hypr mako waybar swayosd "
# vectorcode-includes:
#     #!/bin/env bash
#     echo "Generating .vectorcode/vectorcode.include from the directory lists"
#     local common_dir_names=$({{ common_dotfiles_dir }})
#     echo '{{ common_dotfiles_dir }}' | awk '/\S/ {print "common/.config/"$1"/**"}' > .vectorcode/vectorcode.include
#     # echo '{{ linux_dotfiles_dir }}' | awk '/\S/ {print "linux/.config/"$1"/**"}' > .vectorcode/vectorcode.include
# vectorcode-init:
#     {{ if path_exists(".vectorcode") != "true" { shell('vectorcode init') } else { "" } }}
#     @echo 'common/.config/**' > .vectorcode/vectorcode.include
#     @echo '{{ os() }}/.config/**' >> .vectorcode/vectorcode.include
#     @cp .gitignore .vectorcode/vectorcode.exclude
#     {{ vectorcode }} vectorise
#
# vectorcode-check:
#     {{ vectorcode }} check config
#     @bat --paging=never .vectorcode/vectorcode.include
#     @bat --paging=never .vectorcode/vectorcode.exclude
#     {{ vectorcode }} ls --pipe | jq '.'
#     {{ vectorcode }} files ls --pipe | jq '.'

chromadb_root_dir := "~/.local/share/chromadb"
systemd_chroma_service_spec := """
  [Unit]
  Description = Chroma Service
  After = network.target

  [Service]
  Type = simple
  User = root
  Group = root
  WorkingDirectory = {{ chromadb_root_dir }}
  ExecStart=/usr/local/bin/chroma run --host 127.0.0.1 --port 8000 --path {{ chromadb_root_dir }}/data --log-path {{ chromadb_root_dir }}/log/chroma.log

  [Install]
  WantedBy = multi-user.target
"""

_chromadb_serice_init:
    @sudo systemctl enable chroma
    @sudo systemctl start chroma

global_gitignore_path := home_directory() / ".config" / "git" / "global.gitignore"

global_gitignore_set:
    {{ if path_exists(global_gitignore_path) == "false" { error("global gitignore doesn't exist") } else { "" } }}
    git config --global core.excludesfile {{ global_gitignore_path }}

zdotdir := env('ZDOTDIR')
npm_init_cmd := if os() == "linux" { ". /usr/share/nvm/init-nvm.sh" } else if os() == "macos" { "export NVM_DIR=/Users/alealfaro/.nvm; [ -s /opt/homebrew/opt/nvm/nvm.sh ] && . /opt/homebrew/opt/nvm/nvm.sh; [ -s /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm ] && . /opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" } else { error("Unsupported os!") }

npm_setup:
    {{ if os() == "macos" { shell('brew', 'install nvm') } else { shell('sudo pacman', '-S', 'nvm') } }}
    echo {{ npm_init_cmd }} >> "{{ zdotdir }}/zshrc.d/099-apps.zsh"
    nvm install v22.19.0
    nvm alias default v22.19.0
