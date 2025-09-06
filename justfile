#!/usr/bin/just --justfile

# By default, show the list of available recipes
default:
    @just --list

# ==============================================================================
# Stow Management
# ==============================================================================

# stow: Restow all configurations managed by stow
stow: check
    @stow -R .config
    @echo "✅ Stow refresh complete."

# unstow: Remove all symlinks managed by stow
unstow:
    @stow -D .config
    @echo "✅ Unstowed all packages."

# check: Simulate stowing to check for any conflicts
check:
    @echo "Simulating stow to check for conflicts..."
    @stow --simulate -R .config


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
STOW_TARGET := "/home/alealfaro/.config"

# check-bogus: Find broken symlinks that point to non-existent files
check-bogus:
    @chkstow -b -t {{STOW_TARGET}}

# clean-bogus: Find and automatically remove all broken symlinks
clean-bogus:
    @echo "Searching for and removing broken symlinks..."
    @chkstow -b -t {{STOW_TARGET}} | awk -F': ' '{print $2}' | xargs -r rm
    @echo "✅ Done."

# check-aliens: Find 'alien' files (not managed by stow) in the target directory
check-aliens:
    @chkstow -a -t {{STOW_TARGET}}

# clean-aliens-interactive: Interactively remove 'alien' files. DANGEROUS!
# This will prompt you to delete any file or directory in your .config
# that is NOT a symlink created by stow. Use with extreme caution.
clean-aliens-interactive:
    @echo "WARNING: This is a dangerous operation."
    @echo "You will be prompted to delete every file not managed by stow."
    @chkstow -a -t {{STOW_TARGET}} | awk -F': ' '{print $2}' | xargs -r -p rm -rf
