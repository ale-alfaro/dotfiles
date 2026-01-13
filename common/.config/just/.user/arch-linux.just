set shell := ['zsh', '-uc']

dotfiles_pkg_file := home_dir() / 'dotfiles' / os() / 'install' / 'pkglist.txt'

arch-pkgs-dump:
    pacman -Qqen

arch-pkgs-dump-aur:
    pacman -Qqem

arch-pkgs-dump-all:
    pacman -Qqe

arch-pkgs-install file=dotfiles_pkg_file *args:
    yay {{ f'-S{{args}}' }} "${(@f)"$(<{{ file }})"}"

arch-pkgs-install-no-confirm file: (arch-pkgs-install '--noconfirm --needed')

arch-pkgs-list-orphans:
    echo '{{ BOLD + RED }}Orphans:{{ NORMAL }}'
    pacman -Qdtq
    echo '{{ BOLD + RED }}Optional orphans:{{ NORMAL }} (remove this for a more aggresive clean)'
    pacman -Qdttq

arch-remove-orphans:
    pacman -Qdtq | sudo pacman -Rns -

@systemd-diagnostics:
    systemctl status --full --no-pager > systemd-status.log
    systemctl --failed --no-pager > systemd-failed.log
    awk 'NR==2 {print $2}' systemd-status.log | xargs systemctl status --full --no-pager
    awk 'NR==2 {print $2}' systemd-status.log | xargs journalctl --no-pager

@udev-rules-install rules_file:
    sudo cp {{ rules_file }} /etc/udev/rules.d/
    sudo udevadm control --reload
