#!/usr/bin/just --justfile

set shell := ["bash", "-c"]
set unstable := true
# ==============================================================================
# Stow Management
# ==============================================================================

export dotfiles_repo_location := absolute_path(justfile_directory())
export dotfiles_target_location := if env('XDG_CONFIG_HOME', '') =~ '^/' { absolute_path(env('XDG_CONFIG_HOME')) } else { home_directory() / '.config' }
# stow_common_args :=
    

# Helper function to get OS (Darwin or Linux)

zellij_config_path := justfile_directory() / "common/.config/zellij/config.kdl"
zellij_os_config_path := justfile_directory() / os() / ".config/zellij/config.kdl"
zellij_config_file_pre_cmd := if path_exists(zellij_config_path) != "true" { "cp " + zellij_os_config_path } else { "echo " + "Zellij config already exists" }

# By default, show the list of available recipes
default:
    @just --list
    @echo "Running on OS: {{ os() }}"


prepare-stow:
    @{{zellij_config_file_pre_cmd}} {{zellij_config_path}}

# stow: Restow all configurations managed by stow
stow-cmd cmd_flag *extra_args:
    stow -d "{{dotfiles_repo_location}}/common/" -t {{dotfiles_target_location}} --verbose=2 {{extra_args}} {{cmd_flag}}  .config
    stow -d "{{dotfiles_repo_location}}/{{os()}}/" -t {{dotfiles_target_location}} --verbose=2 {{extra_args}} {{cmd_flag}}  --ignore='.*bak' .config

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
    @just pull
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
