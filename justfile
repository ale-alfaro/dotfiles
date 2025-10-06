#!/usr/bin/just --justfile

set shell := ["bash", "-c"]
set unstable := true

# ==============================================================================
# Stow Management
# ==============================================================================

export dotfiles_repo_location := absolute_path(justfile_directory())
export dotfiles_target_location := if env('XDG_CONFIG_HOME', '') =~ '^/' { absolute_path(env('XDG_CONFIG_HOME')) } else { home_directory() / '.config' }
home := home_directory()
common_extra_flags := " --ignore='bin' --ignore='chromium'"

# By default, show the list of available recipes
default:
    @just --list
    @echo "Running on OS: {{ os() }}"

migrate-common *extra_args:
    stow -d "{{ dotfiles_repo_location }}/common/" -t {{ home }} --verbose=2 {{ extra_args }} {{ common_extra_flags }} -D .config -S .

# stow: Restow all configurations managed by stow
stow-cmd cmd_flag *extra_args:
    stow -d "{{ dotfiles_repo_location }}/common/" -t {{ home }} --verbose=2 {{ extra_args }} {{ common_extra_flags }}  {{ cmd_flag }} .
    stow -d "{{ dotfiles_repo_location }}/{{ os() }}/" -t {{ dotfiles_target_location }} --verbose=2 {{ extra_args }} {{ common_extra_flags }}{{ cmd_flag }}  .config

stow: (stow-cmd "-S")
    @echo "✅ Stow complete."

restow: (stow-cmd "-R")
    @echo "✅ Stow refresh complete."

unstow: (stow-cmd "-D")
    @echo "✅ Unstowed all packages."

# check: Simulate stowing to check for any conflicts
check: (stow-cmd "-R" "--simulate")
    @echo "Simulating stow to check for conflicts..."

# ==============================================================================
# Maintenance
# ==============================================================================

# update: Pull latest changes and apply them with stow
update:
    @git pull
    @just stow

# ==============================================================================
# Stow Health Check (chkstow)
# ==============================================================================
# check-bogus: Find broken symlinks that point to non-existent files
check-bogus:
    @chkstow -b -t {{ dotfiles_target_location }}

# clean-bogus: Find and automatically remove all broken symlinks
clean-bogus:
    @echo "Searching for and removing broken symlinks..."
    @chkstow -b -t {{ dotfiles_target_location }} | awk -F': ' '{print $2}' | xargs -r rm
    @echo "✅ Done."

# check-aliens: Find 'alien' files (not managed by stow) in the target directory
check-aliens:
    @chkstow -a -t {{ dotfiles_target_location }}

# clean-aliens-interactive: Interactively remove 'alien' files. DANGEROUS!
# This will prompt you to delete any file or directory in your .config

# that is NOT a symlink created by stow. Use with extreme caution.
clean-aliens-interactive:
    @echo "WARNING: This is a dangerous operation."
    @echo "You will be prompted to delete every file not managed by stow."
    @chkstow -a -t {{ dotfiles_target_location }} | awk -F': ' '{print $2}' | xargs -r -p rm -rf

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
