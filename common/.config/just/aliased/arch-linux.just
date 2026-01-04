pkgs-dump-all:
    pacman -Qqe 

pkgs-dump-arch:
    pacman -Qqen

pkgs-dump-aur:
    pacman -Qqem

install-file file:
    mapfile -t packages < <(grep -v '^#' {{ file }} | grep -v '^$') \
    sudo pacman -S --noconfirm --needed "${packages[@]}"

[group('clean')]
list-orphans:
    pacman -Qdtq

[group('clean')]
list-optional-orphans:
    pacman -Qdttq

[group('clean')]
remove-orphans:
    pacman -Qdtq | sudo pacman -Rns -

[group('diagnostics')]
systemd-diagnostics:
    @systemctl status --full --no-pager > systemd-status.log
    @systemctl --failed --no-pager > systemd-failed.log
    @awk 'NR==2 {print $2}' systemd-status.log | xargs systemctl status --full --no-pager
    @awk 'NR==2 {print $2}' systemd-status.log | xargs journalctl --no-pager

[group('udev')]
install-udev-rules rules_file:
    @sudo cp {{ rules_file }} /etc/udev/rules.d/
    @sudo udevadm control --reload
