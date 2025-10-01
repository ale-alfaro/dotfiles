#!/bin/env bash

pacman -S --needed - <pacman_pkglists/pkglist.txt
pacman -S --needed - <pacman_pkglists/pkglist_aur.txt
