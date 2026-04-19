#!/bin/env bash

# Make sure to be in this directory for pathing
pushd "$(dirname "${BASH_SOURCE[0]}")" || exit
pacman -S --noconfirm --needed - <pkglist.txt
yay -S - <pkglist-aur.txt
popd || exit
