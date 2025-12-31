conf_home := if env('XDG_CONFIG_HOME', '') =~ '^/' { absolute_path(env('XDG_CONFIG_HOME')) } else { home_directory() / '.config' }
dots := home_directory() / 'dotfiles'
stow_sim := env('STOW_NO_SIM', '1')
verbose_lvl := "2"
extra_args := ""
stow_flags := f'--verbose={{verbose_lvl}} {{if stow_sim == "1" { "-n" } else { "" }}} {{extra_args}}'

[group('stow')]
@sstow pkg_dir target_dir pkgs:
    stow -d {{ pkg_dir }} -t {{ target_dir }} {{ stow_flags }} -S {{ pkgs }}
    @echo "✅ Stowd all packages."

[group('stow')]
@restow pkg_dir target_dir pkgs *extra_args:
    stow -d {{ pkg_dir }} -t {{ target_dir }} {{ stow_flags }} -R {{ pkgs }}
    @echo "✅ Stow refresh complete."

[group('stow')]
@unstow pkg_dir target_dir pkgs:
    stow -d {{ pkg_dir }} -t {{ target_dir }} {{ stow_flags }} -D {{ pkgs }}
    echo "✅ Unstowed all packages."

[group('stow')]
@stow-check-bogus target_dir:
    chkstow -b -t {{ target_dir }}

[group('maintanance')]
@restow-platform-dotfiles: (restow dots / os() conf_home '.config')
    echo "Stowed {{ os() }} packages"

[group('maintanance')]
restow-user-home: (restow dots / "common" home_dir() 'home')

[group('maintanance')]
@restow-user-bin:
    just --justfile {{ justfile() }} extra_args=--ignore='/*.venv'  restow {{ dots / "common" }} {{ executable_dir() }} "bin"

[group('maintanance')]
@restow-common-dotfiles:
    just --justfile {{ justfile() }} extra_args=--ignore='chromium'  restow {{ dots / "common" }} {{ conf_home }} ".config"
    echo "Stowed common packages"

[group('maintanance')]
restow-dotfiles: restow-common-dotfiles restow-platform-dotfiles

# clean-bogus: Find and automatically remove all broken symlinks
[group('stow')]
clean-bogus target_dir:
    @echo "Searching for and removing broken symlinks..."
    @chkstow -b -t {{ target_dir }} | awk -F': ' '{print $2}' | xargs -r rm
    @echo "✅ Done."

# check-aliens: Find 'alien' files (not managed by stow) in the target directory
[group('stow')]
check-aliens target_dir:
    @chkstow -a -t {{ target_dir }} | awk '{print $2}'

# clean-aliens-interactive: Interactively remove 'alien' files. DANGEROUS!
# This will prompt you to delete any file or directory in your .config

# that is NOT a symlink created by stow. Use with extreme caution.
[group('stow')]
clean-aliens-interactive target_dir:
    @echo "WARNING: This is a dangerous operation."
    @echo "You will be prompted to delete every file not managed by stow."
    @chkstow -a -t {{ target_dir }} | awk -F': ' '{print $2}' | xargs -r -p rm -rf
