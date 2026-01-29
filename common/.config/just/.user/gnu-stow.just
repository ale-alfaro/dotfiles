set unstable := true

conf_home := if env('XDG_CONFIG_HOME', '') =~ '^/' { absolute_path(env('XDG_CONFIG_HOME')) } else { home_directory() / '.config' }
dots := home_directory() / 'dotfiles'
stow_no_sim := env('STOW_NO_SIM', '')
stow_sim_flag := if stow_no_sim != '' { '' } else { '--simulate' }
verbose_lvl := "2"

[group('stow')]
@sstow pkg_dir target_dir pkgs *extra_args:
    stow -d {{ pkg_dir }} -t {{ target_dir }} {{ f"--verbose={{verbose_lvl}} {{stow_sim_flag}} '{{extra_args}}'" }} -S {{ pkgs }}
    echo {{ if stow_sim_flag == '--simulate' { "Ran simulation successfully. To do the change run with STOW_NO_SIM=1" } else { f"✅ Stowed {{pkgs}} in {{pkg_dir}} on target dir {{target_dir}}" } }}

[group('stow')]
@restow pkg_dir target_dir pkgs *extra_args:
    stow -d {{ pkg_dir }} -t {{ target_dir }} {{ f"--verbose={{verbose_lvl}} {{stow_sim_flag}} '{{extra_args}}'" }} -R {{ pkgs }}
    echo {{ if stow_sim_flag == '--simulate' { "Ran restow simulation successfully. To do the change run with STOW_NO_SIM=1" } else { f"✅ Restowed {{pkgs}} in {{pkg_dir}} on target dir {{target_dir}}" } }}

[group('stow')]
@unstow pkg_dir target_dir pkgs *extra_args:
    stow -d {{ pkg_dir }} -t {{ target_dir }} {{ f"--verbose={{verbose_lvl}} {{stow_sim_flag}} '{{extra_args}}'" }} -D {{ pkgs }}
    echo {{ if stow_sim_flag == '--simulate' { "Ran unstow simulation successfully. To do the change run with STOW_NO_SIM=1" } else { f"✅ Unstowed {{pkgs}} in {{pkg_dir}} on target dir {{target_dir}}" } }}

[group('stow')]
@stow-check-bogus target_dir:
    chkstow -b -t {{ target_dir }}

[group('maintanance')]
@restow-platform-dotfiles: (restow dots / os() conf_home '.config')
    echo "Stowed {{ os() }} packages"

[group('maintanance')]
[macos]
restow-zshenv: (restow dots / "common/home" home_dir() '.')

[linux]
restow-zshenv:
    sudo ln -sf {{ dots / "common" / "home" / "zshenv" }}  /etc/zsh/zshenv

@restow-user-bin:
    just --justfile {{ justfile() }} restow {{ dots / "common" }} {{ executable_dir() }} bin --ignore='.*\.(md|lock|venv|direnv|python-version|toml|envrc)$'

[group('maintanance')]
@restow-common-dotfiles:
    just --justfile {{ justfile() }} restow {{ dots / "common" }} {{ conf_home }} ".config" --ignore='chromium'
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
