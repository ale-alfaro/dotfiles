set shell := ['zsh', '-uc']

dotfiles_pkg_file := home_dir() / 'dotfiles' / os() / 'install' / 'pkglist.txt'


pacman-ls-orphans:
    @echo '{{ BOLD + RED }} Orphans:{{ NORMAL }}'
    pacman -Qdttq

[confirm]
pacman-rm-orphans: pacman-ls-orphans
    pacman -Qdttq | sudo pacman -Rns -

@systemd-diagnostics:
    systemctl status --full --no-pager > systemd-status.log
    systemctl --failed --no-pager > systemd-failed.log
    awk 'NR==2 {print $2}' systemd-status.log | xargs systemctl status --full --no-pager
    awk 'NR==2 {print $2}' systemd-status.log | xargs journalctl --no-pager

@udev-rules-install rules_file:
    sudo cp {{ rules_file }} /etc/udev/rules.d/
    sudo udevadm control --reload
