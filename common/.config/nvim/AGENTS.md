
# Agent Configuration

## Build/Lint/Test Commands
- Format: `just format` or `stylua .` (runs on all lua files, requires stylua)
- Check format: `just check-format` (check if formatting is needed, requires stylua)
- Config check: `just check-config` (validate configuration loads without errors)
- Health check: `just check-health` (run Neovim health checks)
- Full check: `just check-all` (run both config and health checks)
- Single test: Not applicable (this is a Neovim config, not a codebase with tests)

## Code Style Guidelines
- Formatting: Stylua with 2 space indent, Unix line endings, single quotes
- File structure: Modular Lua files organized by category
- Naming: snake_case for variables/functions, PascalCase for modules
- Imports: Use relative paths for local modules
- Error handling: Use pcall() for unsafe operations
- Comments: Minimal, only for complex logic

## Plugin Management
- All plugins configured in `lua/plugins.lua`
- Use the `enabled` field to enable/disable plugin categories
- Key mappings centralized in `lua/whichkey.lua`

## Key Conventions
- Leader key: Space
- Plugin loading: Lazy-loaded by default
- Configuration: Prefer simple, minimal configurations
- No tests required (Neovim plugin config)

## Recent Changes
- **Removed snacks.nvim**: Too bloated, replaced picker functionality with telescope
- **Migrated pickers**: Moved useful picker keybindings from snacks to telescope
- **Current plugin count**: ~12-15 plugins (reduced from ~20)
- **Removed redundancies**: No more duplicate file explorers, git tools, or fuzzy finders

## Structure

- `init.lua` - Main configuration file
- `lua/lazyplugins.lua` - Lazy plugin loader
- `lua/utils/` - Utility modules (whichkey, health checks, terminal)
- `lua/core` - Essential plugins (mini.nvim, file explorer, which-key)
- `lua/lsp` - Language Server Protocol plugins
- `lua/aesthetics` - UI/Theme related plugins
- `lua/git` - Git integration plugins
- `lua/utils` - Utility plugins (telescope, autopairs, etc.)

To enable/disable a category, simply change the `enabled` field to `true` or `false` in `lua/plugins.lua`.

