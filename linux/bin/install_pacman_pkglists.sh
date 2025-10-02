#!/bin/env bash

pacman -S --needed - <pacman_pkglists/pkglist.txt
yay -S - <pacman_pkglists/pkglist_aur.txt
