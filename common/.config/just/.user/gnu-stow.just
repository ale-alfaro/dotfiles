set unstable := true

conf_home := if env('XDG_CONFIG_HOME', '') =~ '^/' { absolute_path(env('XDG_CONFIG_HOME')) } else { home_directory() / '.config' }
dots := home_directory() / 'dotfiles'
stow_no_sim := env('STOW_NO_SIM', '')
stow_sim_msg := stow_no_sim || f'{{style("warning")}}Ran restow simulation successfully. To do the change run with STOW_NO_SIM=1'
stow_sim_flag := if stow_no_sim != '' { '' } else { '--simulate' }
verbose_lvl := "2"

@sstow pkg_dir target_dir pkgs:
    stow -d {{ absolute_path(pkg_dir) }} -t {{ absolute_path(target_dir) }} {{ f"--verbose={{verbose_lvl}} {{stow_sim_flag}} " }} -S {{ pkgs }}
    echo '{{ stow_sim_msg || f"✅ Restowed {{pkgs}} in {{pkg_dir}} on target dir {{target_dir}}" }}'

@restow pkg_dir target_dir pkgs:
    stow -d {{ absolute_path(pkg_dir) }} -t {{ absolute_path(target_dir) }} {{ f"--verbose={{verbose_lvl}} {{stow_sim_flag}} " }} -R {{ pkgs }}
    echo '{{ stow_sim_msg || f"✅ Restowed {{pkgs}} in {{pkg_dir}} on target dir {{target_dir}}" }}'

@unstow pkg_dir target_dir pkgs:
    stow -d {{ absolute_path(pkg_dir) }} -t {{ absolute_path(target_dir) }} {{ f"--verbose={{verbose_lvl}} {{stow_sim_flag}} " }} -D {{ pkgs }}
    echo '{{ stow_sim_msg || f"✅ Unstowed {{pkgs}} in {{pkg_dir}} on target dir {{target_dir}}" }}'

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
[working-directory(x'${HOME}/dotfiles/linux/etc')]
restow-etc:
    sudo ln -sf -t /etc/pacman.d $(realpath pacman.d/mirrorlist*)
    sudo ln -sf -t /etc/pacman.d $(realpath pacman.d/hooks)
    sudo ln -sf -t /etc/pacman.d $(realpath pacman.d/gnupg)
    sudo ln -sf -t /etc/zsh $(realpath zsh/*)
    sudo ln -sf -t /etc/nix $(realpath nix/*)

[linux]
restow-applications: (restow dots / os() data_local_dir() 'applications')

@restow-user-bin: (restow dots / "common" executable_dir() 'bin')

@restow-common-dotfiles: (restow dots / 'common' conf_home '.config')

restow-dotfiles: restow-common-dotfiles restow-platform-dotfiles

agents_skills_src_dir := dots / 'common' / 'llm_memory' / 'skills'
agents_skills_target_dir := home_dir() / '.agents' / 'skills'

@stow-agents-skills: (sstow agents_skills_src_dir agents_skills_target_dir '.')

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
