---
name: mise-task-composer
description: Create and update mise file tasks in this repo, using the local mise task conventions and usage spec. Use for adding or editing scripts under mise-tasks/. Prefer file tasks over toml tasks, add #MISE metadata and #USAGE specs, and follow local templates.
---

# Mise Task Composer

## When To Use

Use this skill when creating or editing mise file tasks in this repository (scripts under `mise-tasks/`).

## Required References

Read these local docs before writing or updating tasks:

- `../references/file_tasks.md`
- `../references/task_arguments.md`
- `../references/tasks.md`
- `../references/templates.md`
- `../references/mise.toml`

## Conventions

- Prefer file tasks in `mise-tasks/` over `mise.toml` tasks.
- Use `#MISE` headers for description/tools/env/depends/etc.
- Use `#USAGE` spec for arguments and flags; expose values via `usage_` env vars.
- Ensure task files are executable.
- Keep scripts small, deterministic, and tool-focused.
- Use a shebang that matches the script language and set `set -euo pipefail` for shell tasks when appropriate.

## Placement

- Default location: `mise-tasks/<task_name>`
- Group tasks via subdirectories to create `group:task` names.

## Minimal Template (bash)

```bash
#!/usr/bin/env bash
set -euo pipefail
#MISE description="Short task description"
#USAGE arg "[arg]" help="Optional arg"

# Task body
```

## Notes

- Avoid `# MISE` (with a space) since mise ignores it.
- Use `mise tasks edit <name>` for quick edits if needed.
