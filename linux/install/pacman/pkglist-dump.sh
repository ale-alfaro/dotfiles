#!/bin/env bash

# Make sure to be in this directory for pathing
pushd "$(dirname "${BASH_SOURCE[0]}")" || exit
pacman -Qqen >pkglist.txt
pacman -Qqem >pkglist-aur.txt
popd || exit
