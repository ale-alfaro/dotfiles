#!/bin/bash

yay -S --noconfirm --needed \
  cargo clang llvm mise \
  imagemagick \
  github-cli \
  lazygit lazydocker-bin \
  go  go-tools \
  python python-pip pyenv


sudo go install github.com/go-delve/delve/cmd/dlv@latest

