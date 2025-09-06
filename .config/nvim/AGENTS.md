# Agent Configuration

## Build/Lint/Test Commands
- Format: `stylua .` (runs on all lua files)
- Single test: Not applicable (this is a Neovim config, not a codebase with tests)
- Health checks: `:checkhealth` in Neovim

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