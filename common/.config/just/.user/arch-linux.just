set shell := ['zsh', '-uc']

dotfiles_pkg_file := home_dir() / 'dotfiles' / os() / 'install' / 'pkglist.txt'

pacman-dump:
    pacman -Qqen

pacman-dump-aur:
    pacman -Qqem

pacman-S-file file=dotfiles_pkg_file *args:
    sudo pacman {{ f'-S{{args}}' }} "${(@f)"$(<{{ file }})"}"
    yay {{ f'-S{{args}}' }} "${(@f)"$(<{{ file }})"}"

[confirm('Are you sure you want to install with --noconfirm and --needed')]
pacman-S-file-noconfirm file: (pacman-S-file '--noconfirm --needed')

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

osdclient +args:
    swayosd-client --monitor "$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')" {{ args }}

# Laptop multimedia keys for volume and LCD brightness (with OSD)
arch_raise_vol: (osdclient '--output-volume raise')

arch_lower_vol: (osdclient '--output-volume lower')

arch_mute_out: (osdclient '--output-volume mute-toggle')

arch_mute_in: (osdclient '--input-volume mute-toggle')

arch_raise_bright: (osdclient '--brightness raise')

arch_lower_bright: (osdclient '--brightness lower')

arch_play_next: (osdclient '--playerctl next')

arch_play_pause: (osdclient '--playerctl play-pause')

arch_play_prev: (osdclient '--playerctl previous')
