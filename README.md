# Dotfiles

This repository contains my personal dotfiles, managed with GNU Stow. The configuration is split into `common`, `macos`, and `linux` directories to support different operating systems while sharing common configurations.

## Structure

```
dotfiles/
├── common/
│   ├── .config/
│   │   ├── alacritty/
│   │   ├── atuin/
│   │   ├── clangd/
│   │   ├── direnv/
│   │   ├── dtsh/
│   │   ├── just/
│   │   ├── lazygit/
│   │   ├── man/
│   │   ├── nvim/
│   │   ├── opencode/
│   │   ├── SEGGER/
│   │   ├── starship/
│   │   ├── zellij/
│   │   └── zsh/
│   ├── bin/
│   └── .envrc
├── macos/
│   └── .config/
│       ├── aerospace/
│       ├── hammerspoon/
│       ├── karabiner/
│       ├── sketchybar/
│       ├── svim/
├── linux/
│   └── .config/
│   │   ├── bash/
│   │   ├── btop/
│   │   ├── chromium-flags.conf
│   │   ├── electron-flags.conf
│   │   ├── environment.d/
│   │   ├── fastfetch/
│   │   ├── fcitx5/
│   │   ├── fontconfig/
│   │   ├── fuzzel/
│   │   ├── gpg/
│       ├── hypr/
│   │   ├── konsolerc
│   │   ├── omarchy/
│       ├── pacman/
│       ├── plymouth/
│       ├── swayosd/
│       ├── systemd/
│   │   ├── uwsm/
│   │   ├── walker/
│       └── waybar/
│   │   ├── wikiman/
│   │   ├── xournalpp/
├── .stow-local-ignore
├── .stowrc
├── justfile
├── README.md
└── install/
```

## Installation

### Prerequisites

*   **GNU Stow:** Make sure `stow` is installed on your system.
    *   On macOS (with Homebrew): `brew install stow`
    *   On Arch Linux: `sudo pacman -S stow`
*   **Clone this repository:**
    ```bash
    git clone <repository_url> ~/dotfiles
    cd ~/dotfiles
    ```
    (Replace `<repository_url>` with the actual URL of your dotfiles repository.)

### For macOS Users

1.  Navigate to the `dotfiles` directory:
    ```bash
    cd ~/dotfiles
    ```
2.  Stow the `common` and `macos` configurations:
    ```bash
    stow common macos
    ```
    This will create symlinks from the `common` and `macos` directories to your home directory (or `$XDG_CONFIG_HOME` if set up correctly).

### For Linux Users

1.  Navigate to the `dotfiles` directory:
    ```bash
    cd ~/dotfiles
    ```
2.  Stow the `common` and `linux` configurations:
    ```bash
    stow common linux
    ```
    This will create symlinks from the `common` and `linux` directories to your home directory (or `$XDG_CONFIG_HOME` if set up correctly).
