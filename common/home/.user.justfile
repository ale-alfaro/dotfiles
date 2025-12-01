set unstable := true
set allow-duplicate-recipes := true
set shell := ["zsh", "-uc"]

# List available recipes
help:
    @just --list

# Display system information
system-info:
    @echo "CPU architecture: {{ arch() }}"
    @echo "Operating system type: {{ os_family() }}"
    @echo "Operating system: {{ os() }}"
    @echo "Home directory: {{ home_directory() }}"

bat-files-with-extension extension search_base_directory=".":
    @fd --extension {{ extension }} --base-directory {{ search_base_directory }} -X bat --style=header --paging=never

bat-files-with-glob glob search_base_directory=".":
    @fd --glob {{ glob }} --base-directory {{ search_base_directory }} -X bat --style=header --paging=never


mod global '~/.config/just'
