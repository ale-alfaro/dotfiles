# Neovim Configuration

This is a streamlined Neovim configuration that reduces complexity while maintaining functionality.

## Structure

- `init.lua` - Main configuration file
- `lua/plugins.lua` - Centralized plugin management with enable/disable functionality
- `lua/lazyplugins.lua` - Lazy plugin loader
- `lua/whichkey.lua` - WhichKey mappings
- `lua/utils/` - Utility modules (health checks, terminal)

## Plugin Management

Plugins are organized in categories in `lua/plugins.lua`:

- `core` - Essential plugins (mini.nvim, file explorer, which-key)
- `lsp` - Language Server Protocol plugins
- `aesthetics` - UI/Theme related plugins
- `git` - Git integration plugins
- `completion` - Code completion plugins
- `utils` - Utility plugins (telescope, autopairs, etc.)
- `ai` - AI plugins (disabled by default)

To enable/disable a category, simply change the `enabled` field to `true` or `false` in `lua/plugins.lua`.

## Key Features

- Easy plugin enable/disable through centralized configuration
- Reduced file count from 20+ to just a few files
- Clean, organized structure
- Fast startup with proper lazy loading
- Consistent keybindings through WhichKey

## Usage

1. Start Neovim: `nvim`
2. Plugins will be automatically installed on first run
3. Use `<space>` as the leader key
4. Use `<space> ?` to see available keybindings
5. Use `:Lazy` to manage plugins
6. Use `:Mason` to manage LSP servers and tools

## Customization

To customize plugins:
1. Edit `lua/plugins.lua` to enable/disable categories or modify plugin configurations
2. Edit `lua/whichkey.lua` to modify keybindings
3. Edit `init.lua` to modify core Neovim settings