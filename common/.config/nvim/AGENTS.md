# Agent Configuration

This document outlines the configuration, conventions, and tools used in this Neovim setup.

## Project Structure

The configuration is organized within the `lua/` directory, following a modular approach managed by `lazy.nvim`.

- **`init.lua`**: The main entry point for the Neovim configuration.
- **`lua/config/`**: Core Neovim settings.
  - `lazy.lua`: Configuration for the `lazy.nvim` plugin manager.
  - `options.lua`: General Neovim options (`vim.o`).
  - `keymaps.lua`: Global key mappings.
  - `autocmds.lua`: Automation rules.
- **`lua/plugins/`**: Plugin specifications, organized by functionality (e.g., `lsp.lua`, `treesitter.lua`, `colorscheme.lua`).
- **`lua/custom/`**: Custom modules and helpers that are not standard plugins.
  - `helpers/`: Utility functions.
  - `parsers/`: Custom parsers for tools like CodeCompanion memory.

## Build, Lint, and Test Commands

This project uses `just` as a command runner.

- **Format Code**: `just format` (runs `stylua` on all Lua files).
- **Check Formatting**: `just check-format` (verifies if formatting is needed).
- **Check Config**: `just check-config` (validates that the configuration loads without errors).
- **Health Check**: `just check-health` (runs Neovim's built-in health checks).
- **Full Check**: `just check-all` (runs both config and health checks).
- **Testing**: Not applicable, as this is a configuration repository.

## Code Style Guidelines

- **Formatting**: Adheres to `stylua` with a 2-space indent, Unix line endings, and single quotes.
- **Naming Conventions**:
  - `snake_case` for local variables and function names.
  - `PascalCase` for Lua modules that return a table (class-like structures).
- **Error Handling**: Use `pcall()` for operations that might fail (e.g., `require`ing optional dependencies).
- **Comments**: Keep comments minimal. Focus on *why* a piece of code exists, not *what* it does.

## VectorCode Toolbox

This repository is indexed with `vectorcode`, a CLI tool for creating a searchable vector database of the codebase. This allows for semantic code search using natural language.

### Key Commands

- **Initialize Project**: `vectorcode init`

  - Run this in the project root. It creates a `.vectorcode` directory for configuration.

- **Vectorise Files**: `vectorcode vectorise <path/to/file_or_dir>`

  - Creates or updates the vector embeddings for the specified files.
  - It respects `.gitignore` by default.
  - To index all files specified in `.vectorcode/vectorcode.include`, run `vectorcode vectorise` with no arguments.

- **Query the Codebase**: `vectorcode query "natural language query"`

  - Searches the indexed files for code relevant to the query. For multi-word queries, always enclose the query in quotes.
  - **Example**: `vectorcode query "how are plugins configured"`
  - **Control result count**: Use the `-n <number>` flag to specify the maximum number of documents to return.
  - **Customize output**: Use the `--include` flag to control what information is returned. This is especially useful for scripting.
    - `--include path`: Returns only the file paths of the results.
    - `--include document`: Returns only the content of the results.
    - `--include chunk`: Returns the specific chunks of text that matched the query, which can be more precise than the whole document.

- **List Indexed Projects**: `vectorcode ls`

  - Shows all projects (collections) currently indexed in the database.

- **List Indexed Files**: `vectorcode files ls`

  - Lists all the files indexed for the current project.

- **Update Embeddings**: `vectorcode update`

  - Refreshes the embeddings for all files currently indexed in the project.

- **Remove Project**: `vectorcode drop`

  - Deletes the entire collection for the current project from the database.

### Automation with Git Hooks

`vectorcode` can automatically update embeddings on commits using Git hooks. The `vectorcode init --hooks` command can be used to set this up, keeping the index synchronized with code changes.

### Developer Integration (`--pipe`)

For tool integration (like with the CodeCompanion plugin), the `--pipe` flag formats the command output as JSON, making it easy to parse programmatically.
