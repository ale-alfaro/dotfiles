#!/usr/bin/just --justfile

set shell := ["bash", "-c"]
set unstable := true

# ==============================================================================
# Stow Management
# ==============================================================================

export dotfiles_repo_location := absolute_path(justfile_directory())
export dotfiles_target_location := if env('XDG_CONFIG_HOME', '') =~ '^/' { absolute_path(env('XDG_CONFIG_HOME')) } else { home_directory() / '.config' }
zshenv_path := justfile_directory() / "common" / ".zshenv"
zshenv_home := home_directory() / ".zshenv"

# By default, show the list of available recipes
default:
    @just --list
    @echo "Running on OS: {{ os() }}"

# stow: Restow all configurations managed by stow
stow-cmd cmd_flag *extra_args:
    {{ if path_exists(zshenv_home) == "true" { shell('rm $1', zshenv_home) } else { '' } }} 
    ln -sf  {{ zshenv_path }}  {{ zshenv_home }}
    stow -d "{{ dotfiles_repo_location }}/common/" -t {{ dotfiles_target_location }} --verbose=2 {{ extra_args }} {{ cmd_flag }} --ignore='\.zshenv'  .config
    stow -d "{{ dotfiles_repo_location }}/{{ os() }}/" -t {{ dotfiles_target_location }} --verbose=2 {{ extra_args }} {{ cmd_flag }}  .config

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

vectorcode := require("vectorcode")

# common_dotfiles_dir := "nvim zsh wezterm just"
# macos_dotfiles_dir := "aerospace hammerspoon sketchybar borders"
# linux_dotfiles_dir := "hypr mako waybar swayosd "

# vectorcode-includes:
#     #!/bin/env bash 
#     echo "Generating .vectorcode/vectorcode.include from the directory lists"
#     local common_dir_names=$({{ common_dotfiles_dir }})
#     echo '{{ common_dotfiles_dir }}' | awk '/\S/ {print "common/.config/"$1"/**"}' > .vectorcode/vectorcode.include
#     # echo '{{ linux_dotfiles_dir }}' | awk '/\S/ {print "linux/.config/"$1"/**"}' > .vectorcode/vectorcode.include

vectorcode_init:
    {{ if path_exists(".vectorcode") != "true" { shell('vectorcode init') } else { "" } }}
    @echo 'common/.config/**' > .vectorcode/vectorcode.include
    @echo '{{ os() }}/.config/**' >> .vectorcode/vectorcode.include
    @cp .gitignore .vectorcode/vectorcode.exclude
    {{ vectorcode }} vectorise

vectorcode_check:
    {{ vectorcode }} check config
    @bat --paging=never .vectorcode/vectorcode.include
    @bat --paging=never .vectorcode/vectorcode.exclude
    {{ vectorcode }} ls --pipe | jq '.'
    {{ vectorcode }} files ls --pipe | jq '.'

