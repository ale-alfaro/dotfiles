# Fish Ported Configuration

This folder contains a Fish shell configuration that mirrors your Zsh setup across macOS and Arch Linux.

## Features
- Vi-mode enabled
- Neovim integration (`Ctrl-X Ctrl-E`)
- Starship, Atuin, and FZF support
- zoxide, direnv, and NVM integration
- Compatible with wezterm and just
- Modular structure (`conf.d` and `functions`)

## Folder layout
- `conf.d/` — environment and tool setup
- `functions/` — interactive utilities (fzf, Neovim integration)
- `README.md` — documentation

## Notes
Scripts in `.config/direnv/lib/*.sh` use Bash syntax and need porting for Fish compatibility. Consider writing wrappers or using conditional sourcing inside `.envrc` files.

---
Generated automatically by ChatGPT (GPT-5) on 2025-10-08.
